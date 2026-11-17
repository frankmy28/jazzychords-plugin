import AudioToolbox
import ChordCore
import Synchronization

/// The real-time MIDI engine.
///
/// Everything touched from `render` is preallocated in `init`: fixed-size
/// unsafe buffers for note tracking and the strum queue, atomics for
/// parameters and pads. The render path performs no allocation and takes no
/// locks. The AU's render block captures the kernel `unowned(unsafe)`, so
/// there is no reference counting per buffer either.
final class ChordKernel {
    static let notesPerChord = NoteSet.capacity
    /// Trigger slots 0–127 are MIDI notes; 128–139 are pads auditioned from the UI.
    static let uiTriggerBase = 128
    static let triggerCount = 128 + ChordBank.slotCount
    static let pendingCapacity = 256
    static let uiQueueCapacity = 64
    /// Register of pad chords: the root sits in the octave starting at C2 (48).
    static let padRegister = 48

    private enum TriggerKind: UInt8 { case idle, passThrough, chord }

    private struct PendingNote {
        var active = false
        var time: AUEventSampleTime = 0
        var note: UInt8 = 0
        var velocity: UInt8 = 0
        var channel: UInt8 = 0
        var trigger: UInt16 = 0
    }

    // MARK: Shared with the UI / host (atomics)

    private let params: UnsafeMutablePointer<Atomic<UInt32>>
    private let paramCount: Int
    private let paramMin: UnsafeMutablePointer<AUValue>
    private let paramMax: UnsafeMutablePointer<AUValue>
    private let slots: UnsafeMutablePointer<Atomic<UInt32>>
    private let uiQueue: UnsafeMutablePointer<Atomic<UInt32>>
    private let uiWriteIndex = Atomic<Int>(0)
    private let uiReadIndex = Atomic<Int>(0)
    private let resetRequested = Atomic<Bool>(false)
    let bypassed = Atomic<Bool>(false)
    /// Output notes currently sounding (bit n = note n), for the keyboard display.
    let soundingLow = Atomic<UInt64>(0)
    let soundingHigh = Atomic<UInt64>(0)
    /// Pads currently held (bit n = pad n), for pad highlighting.
    let heldPads = Atomic<UInt32>(0)

    // MARK: Audio thread only

    private let masks: UnsafeMutablePointer<UInt32>
    private let qualityCount: Int
    private let triggerKind: UnsafeMutablePointer<UInt8>
    private let triggerChannel: UnsafeMutablePointer<UInt8>
    private let triggerPad: UnsafeMutablePointer<Int8>
    private let emitted: UnsafeMutablePointer<UInt8>
    private let emittedCount: UnsafeMutablePointer<UInt8>
    private let refCount: UnsafeMutablePointer<UInt8>
    private let pending: UnsafeMutablePointer<PendingNote>
    private let midiBytes: UnsafeMutablePointer<UInt8>
    private var pendingActive = 0
    private var heldPadMask: UInt32 = 0
    private var lastChord = NoteSet()
    private var rng: UInt64 = 0x9E37_79B9_7F4A_7C15
    private var strumUpNext = true
    private var transportWasMoving = false
    private var sampleRate = 44_100.0

    private(set) var silence: UnsafeMutablePointer<Float>?
    private var silenceFrames: AUAudioFrameCount = 0

    // Set from allocateRenderResources, read on the audio thread.
    var midiOutput: AUMIDIOutputEventBlock?
    var transportState: AUHostTransportStateBlock?

    init() {
        paramCount = Param.allCases.count
        params = .allocate(capacity: paramCount)
        paramMin = .allocate(capacity: paramCount)
        paramMax = .allocate(capacity: paramCount)
        for param in Param.allCases {
            let i = Int(param.rawValue)
            (params + i).initialize(to: Atomic(param.spec.defaultValue.bitPattern))
            paramMin[i] = param.spec.min
            paramMax[i] = param.spec.max
        }

        slots = .allocate(capacity: ChordBank.slotCount)
        for i in 0..<ChordBank.slotCount { (slots + i).initialize(to: Atomic(ChordBank.defaultBank.slots[i].packed)) }

        uiQueue = .allocate(capacity: Self.uiQueueCapacity)
        for i in 0..<Self.uiQueueCapacity { (uiQueue + i).initialize(to: Atomic(0)) }

        qualityCount = ChordQuality.all.count
        masks = .allocate(capacity: qualityCount)
        for (i, quality) in ChordQuality.all.enumerated() { masks[i] = quality.mask }

        triggerKind = .allocate(capacity: Self.triggerCount)
        triggerKind.initialize(repeating: TriggerKind.idle.rawValue, count: Self.triggerCount)
        triggerChannel = .allocate(capacity: Self.triggerCount)
        triggerChannel.initialize(repeating: 0, count: Self.triggerCount)
        triggerPad = .allocate(capacity: Self.triggerCount)
        triggerPad.initialize(repeating: -1, count: Self.triggerCount)
        emitted = .allocate(capacity: Self.triggerCount * Self.notesPerChord)
        emitted.initialize(repeating: 0, count: Self.triggerCount * Self.notesPerChord)
        emittedCount = .allocate(capacity: Self.triggerCount)
        emittedCount.initialize(repeating: 0, count: Self.triggerCount)
        refCount = .allocate(capacity: 128)
        refCount.initialize(repeating: 0, count: 128)
        pending = .allocate(capacity: Self.pendingCapacity)
        pending.initialize(repeating: PendingNote(), count: Self.pendingCapacity)
        midiBytes = .allocate(capacity: 3)
        midiBytes.initialize(repeating: 0, count: 3)
    }

    deinit {
        params.deinitialize(count: paramCount)
        params.deallocate()
        paramMin.deallocate()
        paramMax.deallocate()
        slots.deinitialize(count: ChordBank.slotCount)
        slots.deallocate()
        uiQueue.deinitialize(count: Self.uiQueueCapacity)
        uiQueue.deallocate()
        masks.deallocate()
        triggerKind.deallocate()
        triggerChannel.deallocate()
        triggerPad.deallocate()
        emitted.deallocate()
        emittedCount.deallocate()
        refCount.deallocate()
        pending.deallocate()
        midiBytes.deallocate()
        silence?.deallocate()
    }

    // MARK: Main-thread API (not real-time)

    func allocate(sampleRate: Double, maxFrames: AUAudioFrameCount) {
        self.sampleRate = sampleRate
        if silenceFrames < maxFrames {
            silence?.deallocate()
            silence = .allocate(capacity: Int(maxFrames))
            silence?.initialize(repeating: 0, count: Int(maxFrames))
            silenceFrames = maxFrames
        }
        clearState()
    }

    /// Asks the audio thread to release every sounding note at the next buffer.
    func requestReset() {
        resetRequested.store(true, ordering: .releasing)
    }

    // MARK: Thread-safe API

    func setParam(_ address: AUParameterAddress, _ value: AUValue) {
        guard address < paramCount else { return }
        let i = Int(address)
        let clamped = min(max(value, paramMin[i]), paramMax[i])
        params[i].store(clamped.bitPattern, ordering: .relaxed)
    }

    func param(address: AUParameterAddress) -> AUValue {
        guard address < paramCount else { return 0 }
        return AUValue(bitPattern: params[Int(address)].load(ordering: .relaxed))
    }

    func setSlot(_ index: Int, packed: UInt32) {
        guard index >= 0 && index < ChordBank.slotCount else { return }
        slots[index].store(packed, ordering: .relaxed)
    }

    /// Queues a pad audition from the UI. Returns false if the queue is full.
    @discardableResult
    func audition(pad: Int, on: Bool) -> Bool {
        let write = uiWriteIndex.load(ordering: .relaxed)
        let read = uiReadIndex.load(ordering: .acquiring)
        guard write - read < Self.uiQueueCapacity else { return false }
        uiQueue[write % Self.uiQueueCapacity].store(UInt32(pad & 0xFF) | (on ? 0x100 : 0), ordering: .relaxed)
        uiWriteIndex.store(write + 1, ordering: .releasing)
        return true
    }

    // MARK: Render (audio thread)

    private func value(_ param: Param) -> AUValue {
        AUValue(bitPattern: params[Int(param.rawValue)].load(ordering: .relaxed))
    }

    private func intValue(_ param: Param) -> Int {
        Int(value(param).rounded())
    }

    func render(timestamp: UnsafePointer<AudioTimeStamp>, frameCount: AUAudioFrameCount,
                events: UnsafePointer<AURenderEvent>?) {
        let start = AUEventSampleTime(timestamp.pointee.mSampleTime)
        let end = start + AUEventSampleTime(frameCount)

        if resetRequested.exchange(false, ordering: .acquiringAndReleasing) {
            releaseAll(at: start)
        }
        checkTransport(at: start)
        drainUIQueue(at: start)

        let bypass = bypassed.load(ordering: .relaxed)
        var event = events
        while let current = event {
            let head = current.pointee.head
            // Immediate events carry a huge negative time; clamp into this buffer.
            let time = min(max(head.eventSampleTime, start), end - 1)
            flushPending(before: time)
            switch head.eventType {
            case .MIDI:
                if bypass {
                    forward(current.pointee.MIDI, at: time)
                } else {
                    handle(current.pointee.MIDI, at: time)
                }
            case .parameter, .parameterRamp:
                let parameter = current.pointee.parameter
                setParam(parameter.parameterAddress, parameter.value)
            default:
                break
            }
            event = UnsafePointer(head.next)
        }
        flushPending(before: end)
        publishState()
    }

    private func handle(_ midi: AUMIDIEvent, at time: AUEventSampleTime) {
        let status = midi.data.0 & 0xF0
        let channel = midi.data.0 & 0x0F
        let data1 = Int(midi.data.1 & 0x7F)
        let data2 = Int(midi.data.2 & 0x7F)
        switch status {
        case 0x90 where data2 > 0:
            noteOn(trigger: data1, playedNote: data1, velocity: data2, channel: channel, at: time)
        case 0x80, 0x90:
            noteOff(trigger: data1, channel: channel, at: time)
        case 0xB0 where data1 == 120 || data1 == 123:
            releaseAll(at: time)
            forward(midi, at: time)
        default:
            // CCs (incl. sustain pedal), pitch bend, aftertouch etc. go straight to the instrument.
            forward(midi, at: time)
        }
    }

    private func noteOn(trigger: Int, playedNote: Int, velocity: Int, channel: UInt8, at time: AUEventSampleTime) {
        if triggerKind[trigger] != TriggerKind.idle.rawValue {
            noteOff(trigger: trigger, channel: channel, at: time)
        }

        let mode = TriggerMode(rawValue: intValue(.mode)) ?? .pad
        let rootPitch: Int
        let mask: UInt32
        var bass: Int? = nil
        let pad: Int

        if mode == .pad {
            if trigger >= Self.uiTriggerBase {
                pad = trigger - Self.uiTriggerBase
            } else {
                pad = playedNote - (intValue(.triggerOctave) + 2) * 12
                guard pad >= 0 && pad < ChordBank.slotCount else {
                    // Outside the trigger octave: play the note as-is (bass lines, melodies).
                    triggerKind[trigger] = TriggerKind.passThrough.rawValue
                    triggerChannel[trigger] = channel
                    send(0x90 | channel, UInt8(playedNote), UInt8(velocity), at: time)
                    return
                }
            }
            let packed = slots[pad].load(ordering: .relaxed)
            let qualityIndex = Int((packed >> 8) & 0xFF)
            let bassValue = (packed >> 16) & 0xFF
            rootPitch = Self.padRegister + Int(packed & 0xFF)
            mask = masks[qualityIndex < qualityCount ? qualityIndex : 0]
            if bassValue != ChordSlot.noBass { bass = Int(bassValue) }
        } else {
            let qualityIndex = intValue(.quality)
            mask = masks[qualityIndex >= 0 && qualityIndex < qualityCount ? qualityIndex : 0]
            if trigger >= Self.uiTriggerBase {
                pad = trigger - Self.uiTriggerBase
                rootPitch = Self.padRegister + pad
            } else {
                pad = playedNote % 12
                rootPitch = playedNote
            }
        }

        let style = VoicingStyle(rawValue: intValue(.voicing)) ?? .close
        let octaveShift = intValue(.octaveShift)
        var chord: NoteSet
        if value(.voiceLeading) >= 0.5 {
            chord = VoiceLeader.lead(rootPitch: rootPitch, mask: mask, bassPitchClass: bass,
                                     style: style, octaveShift: octaveShift, previous: lastChord)
        } else {
            chord = Voicer.voice(rootPitch: rootPitch, mask: mask, bassPitchClass: bass,
                                 style: style, inversion: intValue(.inversion), octaveShift: octaveShift)
        }
        lastChord = chord
        if value(.passThrough) >= 0.5 && trigger < Self.uiTriggerBase && !chord.contains(playedNote) {
            chord.append(playedNote)
            chord.sort()
        }

        triggerKind[trigger] = TriggerKind.chord.rawValue
        triggerChannel[trigger] = channel
        triggerPad[trigger] = Int8(pad)
        emittedCount[trigger] = 0
        heldPadMask |= 1 << UInt32(pad)

        let baseVelocity = intValue(.velocityMode) == 1 ? intValue(.fixedVelocity) : velocity
        let strumSamples = Double(value(.strumTime)) * 0.001 * sampleRate
        let humanizeSamples = Double(value(.humanizeTime)) * 0.001 * sampleRate
        let humanizeVelocity = Double(value(.humanizeVelocity))
        let up: Bool
        switch StrumDirection(rawValue: intValue(.strumDirection)) ?? .up {
        case .up: up = true
        case .down: up = false
        case .alternate:
            up = strumUpNext
            strumUpNext.toggle()
        }

        let lastIndex = max(chord.count - 1, 1)
        var i = 0
        while i < chord.count {
            let position = up ? i : chord.count - 1 - i
            var delay = strumSamples * Double(position) / Double(lastIndex)
            if humanizeSamples > 0 { delay += humanizeSamples * nextRandom() }
            var noteVelocity = baseVelocity
            if humanizeVelocity > 0 {
                noteVelocity += Int((nextRandom() * 2 - 1) * humanizeVelocity)
            }
            noteVelocity = min(max(noteVelocity, 1), 127)

            let delaySamples = AUEventSampleTime(delay)
            if delaySamples == 0 {
                emitNoteOn(trigger: trigger, note: chord[i], velocity: noteVelocity, channel: channel, at: time)
            } else {
                schedule(trigger: trigger, note: chord[i], velocity: noteVelocity, channel: channel,
                         at: time + delaySamples)
            }
            i += 1
        }
    }

    private func noteOff(trigger: Int, channel: UInt8, at time: AUEventSampleTime) {
        switch TriggerKind(rawValue: triggerKind[trigger]) ?? .idle {
        case .idle:
            // A note we never saw start (e.g. held while the plugin loaded): pass it on.
            if trigger < Self.uiTriggerBase { send(0x80 | channel, UInt8(trigger), 0, at: time) }
        case .passThrough:
            send(0x80 | triggerChannel[trigger], UInt8(trigger), 0, at: time)
        case .chord:
            cancelPending(trigger: trigger)
            let channel = triggerChannel[trigger]
            let base = trigger * Self.notesPerChord
            var i = 0
            while i < Int(emittedCount[trigger]) {
                let note = Int(emitted[base + i])
                if refCount[note] > 0 { refCount[note] -= 1 }
                if refCount[note] == 0 { send(0x80 | channel, UInt8(note), 0, at: time) }
                i += 1
            }
            if triggerPad[trigger] >= 0 { heldPadMask &= ~(1 << UInt32(triggerPad[trigger])) }
        }
        triggerKind[trigger] = TriggerKind.idle.rawValue
        triggerPad[trigger] = -1
        emittedCount[trigger] = 0
    }

    private func releaseAll(at time: AUEventSampleTime) {
        var trigger = 0
        while trigger < Self.triggerCount {
            if triggerKind[trigger] != TriggerKind.idle.rawValue {
                noteOff(trigger: trigger, channel: triggerChannel[trigger], at: time)
            }
            trigger += 1
        }
        var note = 0
        while note < 128 {
            if refCount[note] > 0 {
                refCount[note] = 0
                send(0x80, UInt8(note), 0, at: time)
            }
            note += 1
        }
        clearPending()
        heldPadMask = 0
        lastChord.removeAll()
    }

    private func emitNoteOn(trigger: Int, note: Int, velocity: Int, channel: UInt8, at time: AUEventSampleTime) {
        guard note >= 0 && note < 128 else { return }
        let count = Int(emittedCount[trigger])
        guard count < Self.notesPerChord else { return }
        if refCount[note] > 0 {
            // Shared with another held chord: re-articulate it.
            send(0x80 | channel, UInt8(note), 0, at: time)
        }
        send(0x90 | channel, UInt8(note), UInt8(velocity), at: time)
        if refCount[note] < 255 { refCount[note] += 1 }
        emitted[trigger * Self.notesPerChord + count] = UInt8(note)
        emittedCount[trigger] = UInt8(count + 1)
    }

    // MARK: Strum queue

    private func schedule(trigger: Int, note: Int, velocity: Int, channel: UInt8, at time: AUEventSampleTime) {
        var i = 0
        while i < Self.pendingCapacity {
            if !pending[i].active {
                pending[i] = PendingNote(active: true, time: time, note: UInt8(note), velocity: UInt8(velocity),
                                         channel: channel, trigger: UInt16(trigger))
                pendingActive += 1
                return
            }
            i += 1
        }
        // Queue full: play it now rather than drop it.
        emitNoteOn(trigger: trigger, note: note, velocity: velocity, channel: channel, at: time)
    }

    /// Emits every queued note due before `limit`, in time order.
    private func flushPending(before limit: AUEventSampleTime) {
        while pendingActive > 0 {
            var earliest = -1
            var i = 0
            while i < Self.pendingCapacity {
                if pending[i].active && pending[i].time < limit
                    && (earliest < 0 || pending[i].time < pending[earliest].time) {
                    earliest = i
                }
                i += 1
            }
            guard earliest >= 0 else { return }
            let entry = pending[earliest]
            pending[earliest].active = false
            pendingActive -= 1
            emitNoteOn(trigger: Int(entry.trigger), note: Int(entry.note), velocity: Int(entry.velocity),
                       channel: entry.channel, at: entry.time)
        }
    }

    private func cancelPending(trigger: Int) {
        guard pendingActive > 0 else { return }
        var i = 0
        while i < Self.pendingCapacity {
            if pending[i].active && Int(pending[i].trigger) == trigger {
                pending[i].active = false
                pendingActive -= 1
            }
            i += 1
        }
    }

    private func clearPending() {
        var i = 0
        while i < Self.pendingCapacity {
            pending[i].active = false
            i += 1
        }
        pendingActive = 0
    }

    // MARK: Helpers

    private func drainUIQueue(at time: AUEventSampleTime) {
        var read = uiReadIndex.load(ordering: .relaxed)
        let write = uiWriteIndex.load(ordering: .acquiring)
        while read < write {
            let message = uiQueue[read % Self.uiQueueCapacity].load(ordering: .relaxed)
            let pad = Int(message & 0xFF)
            if pad < ChordBank.slotCount {
                let trigger = Self.uiTriggerBase + pad
                if message & 0x100 != 0 {
                    noteOn(trigger: trigger, playedNote: Self.padRegister + pad, velocity: 100, channel: 0, at: time)
                } else {
                    noteOff(trigger: trigger, channel: 0, at: time)
                }
            }
            read += 1
        }
        uiReadIndex.store(read, ordering: .releasing)
    }

    private func checkTransport(at time: AUEventSampleTime) {
        guard let transportState else { return }
        var flags = AUHostTransportStateFlags()
        guard transportState(&flags, nil, nil, nil) else { return }
        let moving = flags.contains(.moving)
        if transportWasMoving && !moving { releaseAll(at: time) }
        transportWasMoving = moving
    }

    private func forward(_ midi: AUMIDIEvent, at time: AUEventSampleTime) {
        guard let midiOutput else { return }
        midiBytes[0] = midi.data.0
        midiBytes[1] = midi.data.1
        midiBytes[2] = midi.data.2
        _ = midiOutput(time, 0, Int(min(midi.length, 3)), midiBytes)
    }

    private func send(_ status: UInt8, _ data1: UInt8, _ data2: UInt8, at time: AUEventSampleTime) {
        guard let midiOutput else { return }
        midiBytes[0] = status
        midiBytes[1] = data1
        midiBytes[2] = data2
        _ = midiOutput(time, 0, 3, midiBytes)
    }

    /// xorshift64*, returns 0..<1.
    private func nextRandom() -> Double {
        rng ^= rng >> 12
        rng ^= rng << 25
        rng ^= rng >> 27
        return Double((rng &* 0x2545_F491_4F6C_DD1D) >> 11) / Double(1 << 53)
    }

    private func publishState() {
        var low: UInt64 = 0
        var high: UInt64 = 0
        var note = 0
        while note < 64 {
            if refCount[note] > 0 { low |= 1 << UInt64(note) }
            if refCount[note + 64] > 0 { high |= 1 << UInt64(note) }
            note += 1
        }
        soundingLow.store(low, ordering: .relaxed)
        soundingHigh.store(high, ordering: .relaxed)
        heldPads.store(heldPadMask, ordering: .relaxed)
    }

    private func clearState() {
        triggerKind.update(repeating: TriggerKind.idle.rawValue, count: Self.triggerCount)
        triggerPad.update(repeating: -1, count: Self.triggerCount)
        emittedCount.update(repeating: 0, count: Self.triggerCount)
        refCount.update(repeating: 0, count: 128)
        clearPending()
        heldPadMask = 0
        lastChord.removeAll()
        transportWasMoving = false
    }
}
