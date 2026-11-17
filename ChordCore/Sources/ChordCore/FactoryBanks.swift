extension ChordBank {
    // Pitch classes
    private static let C = 0, Db = 1, D = 2, Eb = 3, E = 4, F = 5, Gb = 6, G = 7, Ab = 8, A = 9, Bb = 10, B = 11

    private static func s(_ root: Int, _ quality: String, _ bass: Int? = nil) -> ChordSlot {
        precondition(ChordQuality.withID(quality) != nil, "Unknown quality \(quality)")
        return ChordSlot(root: root, qualityID: quality, bass: bass)
    }

    public static let factory: [ChordBank] = [
        ChordBank(name: "Deep House Classics", slots: [
            s(A, "m9"), s(D, "m9"), s(E, "m7"), s(F, "maj9"),
            s(G, "13sus4"), s(C, "maj9"), s(B, "m7b5"), s(E, "7#9"),
            s(F, "m9"), s(Bb, "maj9"), s(Eb, "maj9"), s(Ab, "6/9"),
        ]),
        ChordBank(name: "Kerri-style Minor", slots: [
            s(C, "m9"), s(Eb, "maj9"), s(F, "m9"), s(G, "m7"),
            s(Ab, "maj9"), s(Bb, "9sus4"), s(C, "m11"), s(D, "m7b5"),
            s(F, "m11"), s(G, "7#9"), s(Ab, "maj9#11"), s(Bb, "13sus4"),
        ]),
        ChordBank(name: "Fingers / Larry Heard", slots: [
            s(D, "m9"), s(F, "maj9"), s(G, "m9"), s(A, "m7"),
            s(Bb, "maj9"), s(C, "9sus4"), s(Eb, "maj9#11"), s(F, "m9"),
            s(G, "m11"), s(Ab, "maj9"), s(Bb, "13sus4"), s(D, "m11"),
        ]),
        ChordBank(name: "Jazz ii-V-I", slots: [
            s(D, "m9"), s(G, "13"), s(C, "maj9"), s(E, "m7b5"),
            s(A, "7alt"), s(D, "mmaj9"), s(F, "m9"), s(Bb, "13"),
            s(Eb, "maj9"), s(Ab, "7#11"), s(G, "7b9"), s(C, "6/9"),
        ]),
        ChordBank(name: "Neo-Soul / R&B", slots: [
            s(Eb, "maj13"), s(D, "m11"), s(G, "7#5#9"), s(C, "m13"),
            s(F, "11"), s(Bb, "maj9"), s(Ab, "maj9sus"), s(Db, "maj13"),
            s(F, "m9", Ab), s(Bb, "13#11"), s(A, "m11b5"), s(Gb, "maj9"),
        ]),
        ChordBank(name: "Gospel Turnarounds", slots: [
            s(C, "maj9"), s(E, "7#9"), s(A, "m9"), s(D, "9"),
            s(D, "m11"), s(G, "13sus4"), s(G, "7alt"), s(F, "maj13"),
            s(Gb, "m7b5"), s(B, "7#9"), s(E, "m11"), s(F, "maj7", G),
        ]),
    ]

    public static var defaultBank: ChordBank { factory[0] }
}
