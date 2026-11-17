import AudioToolbox
import ChordCore

enum TriggerMode: Int, CaseIterable {
    /// Each key of the trigger octave plays one pad of the bank.
    case pad
    /// Every key is a root; the selected chord type is built on it.
    case transpose

    var displayName: String {
        switch self {
        case .pad: "Pads"
        case .transpose: "Transpose"
        }
    }
}

enum StrumDirection: Int, CaseIterable {
    case up, down, alternate

    var displayName: String {
        switch self {
        case .up: "Up"
        case .down: "Down"
        case .alternate: "Alt"
        }
    }
}

/// Every automatable parameter. Raw values are the AUParameterAddress and the
/// kernel's parameter slot, so never reorder; only append.
enum Param: AUParameterAddress, CaseIterable {
    case mode
    case triggerOctave
    case quality
    case inversion
    case voicing
    case octaveShift
    case voiceLeading
    case strumTime
    case strumDirection
    case humanizeTime
    case humanizeVelocity
    case velocityMode
    case fixedVelocity
    case passThrough

    struct Spec {
        let identifier: String
        let name: String
        let min: AUValue
        let max: AUValue
        let defaultValue: AUValue
        let unit: AudioUnitParameterUnit
        var valueStrings: [String]? = nil
        var unitName: String? = nil
    }

    var spec: Spec {
        switch self {
        case .mode:
            Spec(identifier: "mode", name: "Mode", min: 0, max: 1, defaultValue: 0, unit: .indexed,
                 valueStrings: TriggerMode.allCases.map(\.displayName))
        case .triggerOctave:
            // Logic naming: octave 3 starts at middle C (note 60).
            Spec(identifier: "triggerOctave", name: "Trigger Octave", min: -2, max: 8, defaultValue: 1, unit: .octaves)
        case .quality:
            Spec(identifier: "quality", name: "Chord Type", min: 0, max: AUValue(ChordQuality.all.count - 1),
                 defaultValue: AUValue(ChordQuality.defaultQuality.index), unit: .indexed,
                 valueStrings: ChordQuality.all.map(\.symbol))
        case .inversion:
            Spec(identifier: "inversion", name: "Inversion", min: 0, max: 3, defaultValue: 0, unit: .indexed,
                 valueStrings: ["Root", "1st", "2nd", "3rd"])
        case .voicing:
            Spec(identifier: "voicing", name: "Voicing", min: 0, max: AUValue(VoicingStyle.allCases.count - 1),
                 defaultValue: 0, unit: .indexed, valueStrings: VoicingStyle.allCases.map(\.displayName))
        case .octaveShift:
            Spec(identifier: "octaveShift", name: "Octave", min: -2, max: 2, defaultValue: 0, unit: .octaves)
        case .voiceLeading:
            Spec(identifier: "voiceLeading", name: "Voice Leading", min: 0, max: 1, defaultValue: 1, unit: .boolean)
        case .strumTime:
            Spec(identifier: "strumTime", name: "Strum", min: 0, max: 100, defaultValue: 0, unit: .milliseconds)
        case .strumDirection:
            Spec(identifier: "strumDirection", name: "Strum Direction", min: 0, max: 2, defaultValue: 0, unit: .indexed,
                 valueStrings: StrumDirection.allCases.map(\.displayName))
        case .humanizeTime:
            Spec(identifier: "humanizeTime", name: "Humanize Timing", min: 0, max: 30, defaultValue: 0, unit: .milliseconds)
        case .humanizeVelocity:
            Spec(identifier: "humanizeVelocity", name: "Humanize Velocity", min: 0, max: 30, defaultValue: 0,
                 unit: .customUnit, unitName: "vel")
        case .velocityMode:
            Spec(identifier: "velocityMode", name: "Velocity", min: 0, max: 1, defaultValue: 0, unit: .indexed,
                 valueStrings: ["As Played", "Fixed"])
        case .fixedVelocity:
            Spec(identifier: "fixedVelocity", name: "Fixed Velocity", min: 1, max: 127, defaultValue: 100, unit: .midiController)
        case .passThrough:
            Spec(identifier: "passThrough", name: "Play Trigger Note", min: 0, max: 1, defaultValue: 0, unit: .boolean)
        }
    }

    static func makeParameterTree() -> AUParameterTree {
        let parameters = allCases.map { param -> AUParameter in
            let spec = param.spec
            let isDiscrete = spec.unit != .milliseconds && spec.unit != .customUnit
            var flags: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable]
            if !isDiscrete { flags.insert(.flag_CanRamp) }
            let parameter = AUParameterTree.createParameter(
                withIdentifier: spec.identifier, name: spec.name, address: param.rawValue,
                min: spec.min, max: spec.max, unit: spec.unit, unitName: spec.unitName,
                flags: flags, valueStrings: spec.valueStrings, dependentParameters: nil)
            parameter.value = spec.defaultValue
            return parameter
        }
        return AUParameterTree.createTree(withChildren: parameters)
    }
}
