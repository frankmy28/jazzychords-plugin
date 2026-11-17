/// One pad: root pitch class, chord quality and optional slash bass.
public struct ChordSlot: Codable, Hashable, Sendable {
    public var root: Int
    public var qualityID: String
    public var bass: Int?

    public init(root: Int, qualityID: String, bass: Int? = nil) {
        self.root = ((root % 12) + 12) % 12
        self.qualityID = qualityID
        self.bass = bass.map { (($0 % 12) + 12) % 12 }
    }

    public init(root: Int, quality: ChordQuality, bass: Int? = nil) {
        self.init(root: root, qualityID: quality.id, bass: bass)
    }

    public var quality: ChordQuality {
        ChordQuality.withID(qualityID) ?? .defaultQuality
    }

    public var name: String {
        let base = PitchClass.name(root) + quality.symbol
        guard let bass, bass != root else { return base }
        return base + "/" + PitchClass.name(bass)
    }

    // MARK: Packing for lock-free transfer to the audio thread

    public static let noBass: UInt32 = 0xFF

    /// `root | qualityIndex << 8 | bass << 16`, with bass 0xFF = none.
    public var packed: UInt32 {
        UInt32(root) | UInt32(quality.index) << 8 | (bass.map { UInt32($0) } ?? Self.noBass) << 16
    }

    public init(packed: UInt32) {
        let qualityIndex = Int((packed >> 8) & 0xFF)
        let bassValue = (packed >> 16) & 0xFF
        let quality = ChordQuality.all.indices.contains(qualityIndex) ? ChordQuality.all[qualityIndex] : .defaultQuality
        self.init(root: Int(packed & 0xFF), quality: quality, bass: bassValue == Self.noBass ? nil : Int(bassValue))
    }
}

/// Twelve pads, one per key of the trigger octave (C through B).
public struct ChordBank: Codable, Hashable, Sendable {
    public static let slotCount = 12

    public var name: String
    public var slots: [ChordSlot]

    public init(name: String, slots: [ChordSlot]) {
        self.name = name
        var normalized = Array(slots.prefix(Self.slotCount))
        while normalized.count < Self.slotCount {
            normalized.append(ChordSlot(root: normalized.count, quality: .defaultQuality))
        }
        self.slots = normalized
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(name: try container.decode(String.self, forKey: .name),
                  slots: try container.decode([ChordSlot].self, forKey: .slots))
    }
}
