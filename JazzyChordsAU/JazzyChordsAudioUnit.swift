import AVFoundation
import AudioToolbox
import ChordCore

/// JazzyChords MIDI processor (type `aumi`).
///
/// Main-thread state (the chord bank, presets) lives here; everything the
/// audio thread needs is mirrored into `ChordKernel` via atomics.
public final class JazzyChordsAudioUnit: AUAudioUnit {
    let kernel = ChordKernel()

    private let _parameterTree: AUParameterTree
    private var outputBus: AUAudioUnitBus!
    private var outputBusArray: AUAudioUnitBusArray!
    private var _currentPreset: AUAudioUnitPreset?

    private static let bankStateKey = "jazzyChordsBank"
    private static let paramsStateKey = "jazzyChordsParams"

    /// The bank being played in Pad mode. Set via `setBank` / `setSlot`.
    private(set) var bank: ChordBank = .defaultBank

    /// Called on the main thread when the bank or preset changes (UI refresh).
    var onStateChange: (() -> Void)?

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        _parameterTree = Param.makeParameterTree()
        try super.init(componentDescription: componentDescription, options: options)

        // Logic pulls MIDI FX like any other unit, so expose one (silent) output bus.
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        outputBus = try AUAudioUnitBus(format: format)
        outputBus.maximumChannelCount = 8
        outputBusArray = AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [outputBus])

        let kernel = self.kernel
        _parameterTree.implementorValueObserver = { parameter, value in
            kernel.setParam(parameter.address, value)
        }
        _parameterTree.implementorValueProvider = { parameter in
            kernel.param(address: parameter.address)
        }
        _parameterTree.implementorStringFromValueCallback = { parameter, valuePointer in
            let value = valuePointer?.pointee ?? parameter.value
            if let strings = parameter.valueStrings, strings.indices.contains(Int(value.rounded())) {
                return strings[Int(value.rounded())]
            }
            switch parameter.unit {
            case .boolean: return value >= 0.5 ? "On" : "Off"
            case .milliseconds: return String(format: "%.0f ms", value)
            default: return String(format: "%.0f", value)
            }
        }

        applyBank(.defaultBank)
        _currentPreset = _factoryPresets.first
    }

    // MARK: AUAudioUnit overrides

    public override var parameterTree: AUParameterTree? {
        get { _parameterTree }
        set { /* fixed tree */ }
    }

    public override var outputBusses: AUAudioUnitBusArray { outputBusArray }

    public override var midiOutputNames: [String] { ["Chords"] }

    public override var channelCapabilities: [NSNumber]? { [0, 2] }

    public override var shouldBypassEffect: Bool {
        get { kernel.bypassed.load(ordering: .relaxed) }
        set { kernel.bypassed.store(newValue, ordering: .relaxed) }
    }

    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        kernel.midiOutput = midiOutputEventBlock
        kernel.transportState = transportStateBlock
        kernel.allocate(sampleRate: outputBus.format.sampleRate, maxFrames: maximumFramesToRender)
    }

    public override func deallocateRenderResources() {
        kernel.midiOutput = nil
        kernel.transportState = nil
        super.deallocateRenderResources()
    }

    public override func reset() {
        super.reset()
        kernel.requestReset()
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        unowned(unsafe) let kernel = self.kernel
        return { _, timestamp, frameCount, _, outputData, events, _ in
            kernel.render(timestamp: timestamp, frameCount: frameCount, events: events)

            // Output silence on the audio bus.
            let buffers = UnsafeMutableAudioBufferListPointer(outputData)
            let byteSize = frameCount * UInt32(MemoryLayout<Float>.size)
            for index in 0..<buffers.count {
                if buffers[index].mData == nil, let silence = kernel.silence {
                    buffers[index].mData = UnsafeMutableRawPointer(silence)
                }
                buffers[index].mDataByteSize = byteSize
                if let data = buffers[index].mData { memset(data, 0, Int(byteSize)) }
            }
            return noErr
        }
    }

    // MARK: Bank editing (main thread)

    func setBank(_ newBank: ChordBank) {
        applyBank(newBank)
    }

    func setSlot(_ index: Int, to slot: ChordSlot) {
        guard bank.slots.indices.contains(index) else { return }
        bank.slots[index] = slot
        kernel.setSlot(index, packed: slot.packed)
    }

    private func applyBank(_ newBank: ChordBank) {
        bank = newBank
        for (index, slot) in newBank.slots.enumerated() {
            kernel.setSlot(index, packed: slot.packed)
        }
        notifyStateChange()
    }

    private func notifyStateChange() {
        guard let onStateChange else { return }
        if Thread.isMainThread { onStateChange() } else { DispatchQueue.main.async(execute: onStateChange) }
    }

    // MARK: Presets & state

    public override var supportsUserPresets: Bool { true }

    private lazy var _factoryPresets: [AUAudioUnitPreset] = ChordBank.factory.enumerated().map { index, bank in
        let preset = AUAudioUnitPreset()
        preset.number = index
        preset.name = bank.name
        return preset
    }

    public override var factoryPresets: [AUAudioUnitPreset]? { _factoryPresets }

    public override var currentPreset: AUAudioUnitPreset? {
        get { _currentPreset }
        set {
            guard let preset = newValue else {
                _currentPreset = nil
                return
            }
            if preset.number >= 0 {
                // Factory presets swap the chord bank and leave the performance settings alone.
                guard ChordBank.factory.indices.contains(preset.number) else { return }
                _currentPreset = preset
                applyBank(ChordBank.factory[preset.number])
            } else if let state = try? presetState(for: preset) {
                fullState = state
                _currentPreset = preset
                notifyStateChange()
            }
        }
    }

    public override var fullState: [String: Any]? {
        get {
            var state = super.fullState ?? [:]
            state[Self.bankStateKey] = try? JSONEncoder().encode(bank)
            var params: [String: Float] = [:]
            for parameter in _parameterTree.allParameters {
                params[parameter.identifier] = parameter.value
            }
            state[Self.paramsStateKey] = params
            return state
        }
        set {
            super.fullState = newValue
            guard let newValue else { return }
            if let data = newValue[Self.bankStateKey] as? Data,
               let restored = try? JSONDecoder().decode(ChordBank.self, from: data) {
                applyBank(restored)
            }
            if let params = newValue[Self.paramsStateKey] as? [String: Any] {
                for parameter in _parameterTree.allParameters {
                    if let value = (params[parameter.identifier] as? NSNumber)?.floatValue {
                        parameter.value = value
                    }
                }
            }
        }
    }

    /// Saves the current bank and settings as a user preset and makes it current.
    func saveUserPreset(named name: String) throws {
        let preset = AUAudioUnitPreset()
        preset.name = name
        preset.number = -((userPresets.map { abs($0.number) }.max() ?? 0) + 1)
        bank.name = name
        try saveUserPreset(preset)
        _currentPreset = preset
        notifyStateChange()
    }

    func removeUserPreset(_ preset: AUAudioUnitPreset) throws {
        try deleteUserPreset(preset)
        if _currentPreset?.number == preset.number { _currentPreset = nil }
        notifyStateChange()
    }
}
