public enum VoicingStyle: Int, CaseIterable, Codable, Sendable, Identifiable {
    /// All chord tones stacked from the root.
    case close
    /// Second-highest voice dropped an octave: the classic Rhodes/pad spread.
    case drop2
    /// Third-highest voice dropped an octave.
    case drop3
    /// Root in the bass, upper structure opened up: big pads.
    case spread
    /// Rootless, four-voice, fifth omitted: the deep house organ/keys stab.
    case stab

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .close: "Close"
        case .drop2: "Drop 2"
        case .drop3: "Drop 3"
        case .spread: "Spread"
        case .stab: "House Stab"
        }
    }
}

public enum Voicer {
    /// Builds a voiced chord without allocating, so it is safe on the audio thread.
    ///
    /// - Parameters:
    ///   - rootPitch: MIDI note of the root before voicing (sets the register).
    ///   - mask: interval bitmask from `ChordQuality.mask`.
    ///   - bassPitchClass: slash-chord bass (0–11), or `nil`.
    ///   - inversion: number of times the lowest upper voice is raised an octave.
    ///   - octaveShift: whole-chord transposition in octaves.
    public static func voice(
        rootPitch: Int,
        mask: UInt32,
        bassPitchClass: Int?,
        style: VoicingStyle,
        inversion: Int,
        octaveShift: Int
    ) -> NoteSet {
        var upper = NoteSet()
        var interval = 0
        while interval < 24 {
            if mask & (1 << UInt32(interval)) != 0 { upper.append(rootPitch + interval) }
            interval += 1
        }
        guard !upper.isEmpty else { return upper }

        if style == .stab && upper.count >= 4 {
            if let root = upper.firstIndex(of: rootPitch) { upper.remove(at: root) }
            if upper.count > 4, let fifth = upper.firstIndex(of: rootPitch + 7) { upper.remove(at: fifth) }
        }

        let inversions = max(0, inversion) % upper.count
        var i = 0
        while i < inversions {
            upper.sort()
            let low = upper[0]
            upper.remove(at: 0)
            upper.append(low + 12)
            i += 1
        }
        upper.sort()

        if upper.count >= 4 {
            switch style {
            case .drop2:
                upper[upper.count - 2] -= 12
            case .drop3:
                upper[upper.count - 3] -= 12
            case .spread:
                // Drop the 2nd and 4th voices from the top (drop 2+4).
                upper[upper.count - 2] -= 12
                upper[upper.count - 4] -= 12
            case .close, .stab:
                break
            }
            upper.sort()
        }

        var result = NoteSet()
        let bass: Int? = bassPitchClass ?? (style == .spread ? ((rootPitch % 12) + 12) % 12 : nil)
        if let bass, let lowest = upper.lowest {
            if style == .spread && bassPitchClass == nil, let root = upper.firstIndex(of: rootPitch) {
                upper.remove(at: root)
            }
            let upperLowest = upper.lowest ?? lowest
            // Highest note with the bass pitch class that sits at least a 4th under the upper voices.
            var bassNote = upperLowest - ((upperLowest - bass) % 12 + 12) % 12
            if upperLowest - bassNote < 5 { bassNote -= 12 }
            result.append(bassNote)
        }
        i = 0
        while i < upper.count {
            result.append(upper[i])
            i += 1
        }

        result.transpose(by: octaveShift * 12)
        result.foldIntoMIDIRange()
        return result
    }
}
