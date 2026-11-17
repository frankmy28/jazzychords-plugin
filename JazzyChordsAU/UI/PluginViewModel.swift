import AudioToolbox
import ChordCore
import Observation
import SwiftUI

/// Bridges the audio unit to SwiftUI: mirrors parameters and the bank, and
/// polls the kernel's atomics for the sounding-notes display.
@MainActor
@Observable
final class PluginViewModel {
    let audioUnit: JazzyChordsAudioUnit

    private(set) var bank: ChordBank
    private(set) var values: [AUParameterAddress: AUValue] = [:]
    private(set) var soundingLow: UInt64 = 0
    private(set) var soundingHigh: UInt64 = 0
    private(set) var heldPads: UInt32 = 0
    private(set) var presetName = ""
    private(set) var userPresets: [AUAudioUnitPreset] = []
    var selectedPad = 0
    var editorCategory: ChordCategory = .house

    @ObservationIgnored private var observerToken: AUParameterObserverToken?
    @ObservationIgnored private var timer: Timer?

    init(audioUnit: JazzyChordsAudioUnit) {
        self.audioUnit = audioUnit
        bank = audioUnit.bank
        refreshFromAudioUnit()
        editorCategory = bank.slots[0].quality.category

        audioUnit.onStateChange = { [weak self] in
            MainActor.assumeIsolated { self?.refreshFromAudioUnit() }
        }
        observerToken = audioUnit.parameterTree?.token(byAddingParameterObserver: { [weak self] address, value in
            DispatchQueue.main.async { self?.values[address] = value }
        })
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pollKernel() }
        }
    }

    isolated deinit {
        timer?.invalidate()
        if let observerToken { audioUnit.parameterTree?.removeParameterObserver(observerToken) }
        audioUnit.onStateChange = nil
    }

    private func refreshFromAudioUnit() {
        bank = audioUnit.bank
        for parameter in audioUnit.parameterTree?.allParameters ?? [] {
            values[parameter.address] = parameter.value
        }
        presetName = audioUnit.currentPreset?.name ?? bank.name
        userPresets = audioUnit.userPresets
    }

    private func pollKernel() {
        let low = audioUnit.kernel.soundingLow.load(ordering: .relaxed)
        let high = audioUnit.kernel.soundingHigh.load(ordering: .relaxed)
        let held = audioUnit.kernel.heldPads.load(ordering: .relaxed)
        if low != soundingLow { soundingLow = low }
        if high != soundingHigh { soundingHigh = high }
        if held != heldPads { heldPads = held }
    }

    // MARK: Parameters

    func value(_ param: Param) -> AUValue {
        values[param.rawValue] ?? param.spec.defaultValue
    }

    func set(_ param: Param, _ value: AUValue) {
        values[param.rawValue] = value
        audioUnit.parameterTree?.parameter(withAddress: param.rawValue)?.setValue(value, originator: observerToken)
    }

    func binding(_ param: Param) -> Binding<Double> {
        Binding(get: { Double(self.value(param)) }, set: { self.set(param, AUValue($0)) })
    }

    func intBinding(_ param: Param) -> Binding<Int> {
        Binding(get: { Int(self.value(param).rounded()) }, set: { self.set(param, AUValue($0)) })
    }

    func boolBinding(_ param: Param) -> Binding<Bool> {
        Binding(get: { self.value(param) >= 0.5 }, set: { self.set(param, $0 ? 1 : 0) })
    }

    var mode: TriggerMode {
        TriggerMode(rawValue: Int(value(.mode).rounded())) ?? .pad
    }

    var triggerBaseNote: Int {
        (Int(value(.triggerOctave).rounded()) + 2) * 12
    }

    var transposeQuality: ChordQuality {
        let index = Int(value(.quality).rounded())
        return ChordQuality.all.indices.contains(index) ? ChordQuality.all[index] : .defaultQuality
    }

    func isSounding(_ note: Int) -> Bool {
        note < 64 ? soundingLow & (1 << UInt64(note)) != 0 : soundingHigh & (1 << UInt64(note - 64)) != 0
    }

    // MARK: Pads

    func padName(_ pad: Int) -> String {
        switch mode {
        case .pad: bank.slots[pad].name
        case .transpose: PitchClass.name(pad) + transposeQuality.symbol
        }
    }

    func padKeyLabel(_ pad: Int) -> String {
        mode == .pad ? PitchClass.noteName(triggerBaseNote + pad) : PitchClass.name(pad)
    }

    func isPadHeld(_ pad: Int) -> Bool {
        heldPads & (1 << UInt32(pad)) != 0
    }

    func padDown(_ pad: Int) {
        selectPad(pad)
        audioUnit.kernel.audition(pad: pad, on: true)
    }

    func padUp(_ pad: Int) {
        audioUnit.kernel.audition(pad: pad, on: false)
    }

    func selectPad(_ pad: Int) {
        selectedPad = pad
        if mode == .pad { editorCategory = bank.slots[pad].quality.category }
    }

    // MARK: Chord editor

    var editedQuality: ChordQuality {
        mode == .pad ? bank.slots[selectedPad].quality : transposeQuality
    }

    var editedSlot: ChordSlot { bank.slots[selectedPad] }

    func setQuality(_ quality: ChordQuality) {
        switch mode {
        case .pad:
            var slot = editedSlot
            slot.qualityID = quality.id
            updateSlot(slot)
        case .transpose:
            set(.quality, AUValue(quality.index))
        }
    }

    func setRoot(_ root: Int) {
        var slot = editedSlot
        slot.root = root
        updateSlot(slot)
    }

    func setBass(_ bass: Int?) {
        var slot = editedSlot
        slot.bass = bass
        updateSlot(slot)
    }

    private func updateSlot(_ slot: ChordSlot) {
        audioUnit.setSlot(selectedPad, to: slot)
        bank = audioUnit.bank
    }

    // MARK: Presets

    var factoryPresets: [AUAudioUnitPreset] { audioUnit.factoryPresets ?? [] }

    var currentUserPreset: AUAudioUnitPreset? {
        guard let current = audioUnit.currentPreset, current.number < 0 else { return nil }
        return current
    }

    func load(_ preset: AUAudioUnitPreset) {
        audioUnit.currentPreset = preset
        refreshFromAudioUnit()
        selectPad(selectedPad)
    }

    func saveUserPreset(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try? audioUnit.saveUserPreset(named: trimmed)
        refreshFromAudioUnit()
    }

    func deleteCurrentUserPreset() {
        guard let preset = currentUserPreset else { return }
        try? audioUnit.removeUserPreset(preset)
        refreshFromAudioUnit()
    }
}
