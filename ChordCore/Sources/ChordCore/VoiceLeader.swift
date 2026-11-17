public enum VoiceLeader {
    /// Picks the inversion and octave that move the least from `previous`,
    /// with a gentle pull back towards the chord's home register so repeated
    /// changes don't drift up or down the keyboard. Allocation-free.
    public static func lead(
        rootPitch: Int,
        mask: UInt32,
        bassPitchClass: Int?,
        style: VoicingStyle,
        octaveShift: Int,
        previous: NoteSet
    ) -> NoteSet {
        let home = Voicer.voice(rootPitch: rootPitch, mask: mask, bassPitchClass: bassPitchClass,
                                style: style, inversion: 0, octaveShift: octaveShift)
        guard !previous.isEmpty, !home.isEmpty else { return home }
        let homeCenter = center(home)

        var best = home
        var bestCost = Int.max
        let inversions = min(home.count, 6)
        var octave = -1
        while octave <= 1 {
            var inversion = 0
            while inversion < inversions {
                let candidate = Voicer.voice(rootPitch: rootPitch, mask: mask, bassPitchClass: bassPitchClass,
                                             style: style, inversion: inversion, octaveShift: octaveShift + octave)
                let cost = movement(from: previous, to: candidate) * 2 + abs(center(candidate) - homeCenter)
                if cost < bestCost {
                    bestCost = cost
                    best = candidate
                }
                inversion += 1
            }
            octave += 1
        }
        return best
    }

    /// Symmetric nearest-note distance between two chords, in semitones.
    public static func movement(from a: NoteSet, to b: NoteSet) -> Int {
        nearestSum(a, b) + nearestSum(b, a)
    }

    private static func nearestSum(_ a: NoteSet, _ b: NoteSet) -> Int {
        var total = 0
        var i = 0
        while i < a.count {
            var nearest = Int.max
            var j = 0
            while j < b.count {
                nearest = min(nearest, abs(a[i] - b[j]))
                j += 1
            }
            total += nearest
            i += 1
        }
        return total
    }

    private static func center(_ notes: NoteSet) -> Int {
        guard let low = notes.lowest, let high = notes.highest else { return 0 }
        return (low + high) / 2
    }
}
