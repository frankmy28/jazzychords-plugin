public enum ChordCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case house
    case jazz
    case rnb

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .house: "House"
        case .jazz: "Jazz"
        case .rnb: "R&B"
        }
    }
}

/// A chord type described by its intervals above the root.
///
/// `id` is the stable key that presets save. `index` is the position in `all`,
/// used by the real-time kernel and by the automatable "Chord Type" parameter.
/// Only append to `all`, so saved parameter values keep their meaning.
public struct ChordQuality: Hashable, Sendable, Identifiable {
    public let id: String
    public let symbol: String
    public let category: ChordCategory
    public let intervals: [Int]

    /// Bit `n` set = interval of `n` semitones above the root (n < 24).
    public var mask: UInt32 {
        intervals.reduce(0) { $0 | (1 << UInt32($1)) }
    }

    public var index: Int {
        Self.all.firstIndex(of: self)!
    }

    public static func withID(_ id: String) -> ChordQuality? {
        all.first { $0.id == id }
    }

    public static func inCategory(_ category: ChordCategory) -> [ChordQuality] {
        all.filter { $0.category == category }
    }

    public static let defaultQuality = withID("m9")!

    // The soul of deep house: minor 9/11ths, major 9ths, 6/9s and sus voicings.
    // Jazz adds altered dominants and half-diminished chords; R&B adds the lush
    // extensions and sus/slash colours of gospel and neo-soul.
    public static let all: [ChordQuality] = [
        // House
        .init(id: "m7", symbol: "m7", category: .house, intervals: [0, 3, 7, 10]),
        .init(id: "m9", symbol: "m9", category: .house, intervals: [0, 3, 7, 10, 14]),
        .init(id: "m11", symbol: "m11", category: .house, intervals: [0, 3, 7, 10, 14, 17]),
        .init(id: "m7add11", symbol: "m7(11)", category: .house, intervals: [0, 3, 7, 10, 17]),
        .init(id: "maj7", symbol: "maj7", category: .house, intervals: [0, 4, 7, 11]),
        .init(id: "maj9", symbol: "maj9", category: .house, intervals: [0, 4, 7, 11, 14]),
        .init(id: "6/9", symbol: "6/9", category: .house, intervals: [0, 4, 7, 9, 14]),
        .init(id: "m6/9", symbol: "m6/9", category: .house, intervals: [0, 3, 7, 9, 14]),
        .init(id: "7sus4", symbol: "7sus4", category: .house, intervals: [0, 5, 7, 10]),
        .init(id: "9sus4", symbol: "9sus", category: .house, intervals: [0, 5, 7, 10, 14]),
        .init(id: "13sus4", symbol: "13sus", category: .house, intervals: [0, 5, 10, 14, 21]),
        .init(id: "add9", symbol: "add9", category: .house, intervals: [0, 4, 7, 14]),
        .init(id: "madd9", symbol: "m(add9)", category: .house, intervals: [0, 3, 7, 14]),
        .init(id: "9", symbol: "9", category: .house, intervals: [0, 4, 7, 10, 14]),
        .init(id: "maj9#11", symbol: "maj9#11", category: .house, intervals: [0, 4, 11, 14, 18]),

        // Jazz
        .init(id: "7", symbol: "7", category: .jazz, intervals: [0, 4, 7, 10]),
        .init(id: "13", symbol: "13", category: .jazz, intervals: [0, 4, 10, 14, 21]),
        .init(id: "7b9", symbol: "7♭9", category: .jazz, intervals: [0, 4, 7, 10, 13]),
        .init(id: "7#9", symbol: "7♯9", category: .jazz, intervals: [0, 4, 7, 10, 15]),
        .init(id: "7#11", symbol: "7♯11", category: .jazz, intervals: [0, 4, 7, 10, 18]),
        .init(id: "13b9", symbol: "13♭9", category: .jazz, intervals: [0, 4, 10, 13, 21]),
        .init(id: "7alt", symbol: "7alt", category: .jazz, intervals: [0, 4, 10, 13, 15, 20]),
        .init(id: "m7b5", symbol: "m7♭5", category: .jazz, intervals: [0, 3, 6, 10]),
        .init(id: "m9b5", symbol: "m9♭5", category: .jazz, intervals: [0, 3, 6, 10, 14]),
        .init(id: "dim7", symbol: "dim7", category: .jazz, intervals: [0, 3, 6, 9]),
        .init(id: "mmaj7", symbol: "m(maj7)", category: .jazz, intervals: [0, 3, 7, 11]),
        .init(id: "mmaj9", symbol: "m(maj9)", category: .jazz, intervals: [0, 3, 7, 11, 14]),
        .init(id: "maj7#5", symbol: "maj7♯5", category: .jazz, intervals: [0, 4, 8, 11]),
        .init(id: "6", symbol: "6", category: .jazz, intervals: [0, 4, 7, 9]),

        // R&B / Neo-Soul / Gospel
        .init(id: "maj13", symbol: "maj13", category: .rnb, intervals: [0, 4, 11, 14, 21]),
        .init(id: "m13", symbol: "m13", category: .rnb, intervals: [0, 3, 10, 14, 21]),
        .init(id: "11", symbol: "11", category: .rnb, intervals: [0, 7, 10, 14, 17]),
        .init(id: "13#11", symbol: "13♯11", category: .rnb, intervals: [0, 4, 10, 14, 18, 21]),
        .init(id: "7#5#9", symbol: "7♯5♯9", category: .rnb, intervals: [0, 4, 8, 10, 15]),
        .init(id: "m6", symbol: "m6", category: .rnb, intervals: [0, 3, 7, 9]),
        .init(id: "sus2", symbol: "sus2", category: .rnb, intervals: [0, 2, 7]),
        .init(id: "maj9sus", symbol: "maj9sus", category: .rnb, intervals: [0, 5, 7, 11, 14]),
        .init(id: "m11b5", symbol: "m11♭5", category: .rnb, intervals: [0, 3, 6, 10, 17]),
    ]
}

public enum PitchClass {
    public static let names = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    public static func name(_ pitchClass: Int) -> String {
        names[((pitchClass % 12) + 12) % 12]
    }

    /// Logic Pro naming: middle C (60) is C3.
    public static func noteName(_ note: Int) -> String {
        "\(name(note))\(note / 12 - 2)"
    }
}
