/// A fixed-capacity, heap-free collection of MIDI note numbers.
///
/// All voicing math runs on `NoteSet` so the real-time MIDI thread can build
/// chords without allocating. Values are stored as `Int16` so intermediate
/// results may temporarily fall outside 0...127 before `foldIntoMIDIRange()`.
public struct NoteSet: Equatable, Sendable {
    public static let capacity = 8

    public private(set) var count = 0
    private var storage: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16) = (0, 0, 0, 0, 0, 0, 0, 0)

    public init() {}

    public init(_ notes: [Int]) {
        for note in notes { append(note) }
    }

    public var isEmpty: Bool { count == 0 }

    public subscript(index: Int) -> Int {
        get {
            precondition(index >= 0 && index < count)
            return withUnsafeBytes(of: storage) { Int($0.load(fromByteOffset: index * 2, as: Int16.self)) }
        }
        set {
            precondition(index >= 0 && index < count)
            withUnsafeMutableBytes(of: &storage) { $0.storeBytes(of: Int16(clamping: newValue), toByteOffset: index * 2, as: Int16.self) }
        }
    }

    /// Appends a note; silently ignored when the set is full.
    public mutating func append(_ note: Int) {
        guard count < Self.capacity else { return }
        count += 1
        self[count - 1] = note
    }

    public mutating func remove(at index: Int) {
        precondition(index >= 0 && index < count)
        var i = index
        while i < count - 1 {
            self[i] = self[i + 1]
            i += 1
        }
        count -= 1
    }

    public mutating func removeAll() { count = 0 }

    public func contains(_ note: Int) -> Bool {
        firstIndex(of: note) != nil
    }

    public func firstIndex(of note: Int) -> Int? {
        var i = 0
        while i < count {
            if self[i] == note { return i }
            i += 1
        }
        return nil
    }

    /// Insertion sort, ascending. Chords have at most 8 notes.
    public mutating func sort() {
        guard count > 1 else { return }
        var i = 1
        while i < count {
            let key = self[i]
            var j = i - 1
            while j >= 0 && self[j] > key {
                self[j + 1] = self[j]
                j -= 1
            }
            self[j + 1] = key
            i += 1
        }
    }

    public var lowest: Int? {
        guard count > 0 else { return nil }
        var low = self[0]
        var i = 1
        while i < count { low = min(low, self[i]); i += 1 }
        return low
    }

    public var highest: Int? {
        guard count > 0 else { return nil }
        var high = self[0]
        var i = 1
        while i < count { high = max(high, self[i]); i += 1 }
        return high
    }

    public mutating func transpose(by semitones: Int) {
        var i = 0
        while i < count { self[i] += semitones; i += 1 }
    }

    /// Moves out-of-range notes by octaves into 0...127 and removes duplicates.
    public mutating func foldIntoMIDIRange() {
        var i = 0
        while i < count {
            var note = self[i]
            while note < 0 { note += 12 }
            while note > 127 { note -= 12 }
            self[i] = note
            i += 1
        }
        sort()
        i = 1
        while i < count {
            if self[i] == self[i - 1] { remove(at: i) } else { i += 1 }
        }
    }

    public var array: [Int] {
        var result: [Int] = []
        result.reserveCapacity(count)
        var i = 0
        while i < count { result.append(self[i]); i += 1 }
        return result
    }

    public static func == (lhs: NoteSet, rhs: NoteSet) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var i = 0
        while i < lhs.count {
            if lhs[i] != rhs[i] { return false }
            i += 1
        }
        return true
    }
}
