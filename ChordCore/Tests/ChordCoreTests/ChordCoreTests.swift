import Foundation
import Testing
@testable import ChordCore

@Suite struct ChordQualityTests {
    @Test func idsAreUnique() {
        let ids = ChordQuality.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyQualityFitsTheKernel() {
        #expect(ChordQuality.all.count < 255)
        for quality in ChordQuality.all {
            #expect(quality.intervals.first == 0, "\(quality.id) must contain the root")
            #expect(quality.intervals.allSatisfy { $0 >= 0 && $0 < 24 })
            #expect(quality.intervals.count <= NoteSet.capacity - 1, "\(quality.id) leaves no room for a bass")
        }
    }

    @Test func aMinorNine() {
        let am9 = Voicer.voice(rootPitch: 57, mask: ChordQuality.withID("m9")!.mask,
                               bassPitchClass: nil, style: .close, inversion: 0, octaveShift: 0)
        #expect(am9.array == [57, 60, 64, 67, 71]) // A C E G B
    }
}

@Suite struct VoicingTests {
    let m9 = ChordQuality.withID("m9")!.mask
    let maj7 = ChordQuality.withID("maj7")!.mask

    @Test func houseStabIsRootlessFourVoices() {
        let stab = Voicer.voice(rootPitch: 57, mask: m9, bassPitchClass: nil, style: .stab, inversion: 0, octaveShift: 0)
        #expect(stab.array == [60, 64, 67, 71]) // C E G B over an implied A
    }

    @Test func drop2() {
        let chord = Voicer.voice(rootPitch: 60, mask: maj7, bassPitchClass: nil, style: .drop2, inversion: 0, octaveShift: 0)
        #expect(chord.array == [55, 60, 64, 71]) // G dropped below C E B
    }

    @Test func firstInversion() {
        let chord = Voicer.voice(rootPitch: 60, mask: maj7, bassPitchClass: nil, style: .close, inversion: 1, octaveShift: 0)
        #expect(chord.array == [64, 67, 71, 72])
    }

    @Test func slashBassSitsBelow() {
        let chord = Voicer.voice(rootPitch: 65, mask: maj7, bassPitchClass: 7, style: .close, inversion: 0, octaveShift: 0)
        #expect(chord.array == [55, 65, 69, 72, 76]) // F maj7 / G
    }

    @Test func spreadHasRootInBass() {
        let chord = Voicer.voice(rootPitch: 57, mask: m9, bassPitchClass: nil, style: .spread, inversion: 0, octaveShift: 0)
        #expect(chord[0] % 12 == 9)
        #expect(chord.count == 5)
        #expect(chord[1] - chord[0] >= 5)
    }

    @Test func allVoicingsStayInRange() {
        for quality in ChordQuality.all {
            for style in VoicingStyle.allCases {
                for inversion in 0..<4 {
                    for octave in -2...2 {
                        for root in [0, 60, 120, 127] {
                            let chord = Voicer.voice(rootPitch: root, mask: quality.mask, bassPitchClass: 4,
                                                     style: style, inversion: inversion, octaveShift: octave)
                            #expect(!chord.isEmpty)
                            #expect(chord.array.allSatisfy { (0...127).contains($0) })
                            #expect(chord.array == chord.array.sorted())
                        }
                    }
                }
            }
        }
    }
}

@Suite struct VoiceLeaderTests {
    @Test func picksMinimalMotion() {
        let maj7 = ChordQuality.withID("maj7")!.mask
        let cmaj7 = Voicer.voice(rootPitch: 60, mask: maj7, bassPitchClass: nil, style: .close, inversion: 0, octaveShift: 0)
        let led = VoiceLeader.lead(rootPitch: 65, mask: maj7, bassPitchClass: nil, style: .close, octaveShift: 0, previous: cmaj7)
        let rootPosition = Voicer.voice(rootPitch: 65, mask: maj7, bassPitchClass: nil, style: .close, inversion: 0, octaveShift: 0)
        #expect(VoiceLeader.movement(from: cmaj7, to: led) < VoiceLeader.movement(from: cmaj7, to: rootPosition))
        #expect(Set(led.array.map { $0 % 12 }) == [5, 9, 0, 4]) // still F A C E
    }

    @Test func noPreviousGivesRootPosition() {
        let m9 = ChordQuality.withID("m9")!.mask
        let led = VoiceLeader.lead(rootPitch: 57, mask: m9, bassPitchClass: nil, style: .close, octaveShift: 0, previous: NoteSet())
        #expect(led.array == [57, 60, 64, 67, 71])
    }

    @Test func doesNotDriftOverLongProgressions() {
        let m9 = ChordQuality.withID("m9")!.mask
        var previous = NoteSet()
        for step in 0..<200 {
            let root = 48 + (step * 5) % 12 // cycle of fourths
            previous = VoiceLeader.lead(rootPitch: root, mask: m9, bassPitchClass: nil, style: .close, octaveShift: 0, previous: previous)
        }
        #expect((36...84).contains(previous.lowest!))
    }
}

@Suite struct BankTests {
    @Test func packingRoundTrips() {
        for quality in ChordQuality.all {
            for bass in [nil, 0, 7, 11] as [Int?] {
                let slot = ChordSlot(root: 9, quality: quality, bass: bass)
                #expect(ChordSlot(packed: slot.packed) == slot)
            }
        }
    }

    @Test func codableRoundTrip() throws {
        for bank in ChordBank.factory {
            let data = try JSONEncoder().encode(bank)
            #expect(try JSONDecoder().decode(ChordBank.self, from: data) == bank)
        }
    }

    @Test func factoryBanksAreComplete() {
        #expect(ChordBank.factory.count == 7)
        for bank in ChordBank.factory {
            #expect(bank.slots.count == ChordBank.slotCount)
        }
    }

    @Test func names() {
        #expect(ChordSlot(root: 9, qualityID: "m9").name == "Am9")
        #expect(ChordSlot(root: 5, qualityID: "maj7", bass: 7).name == "Fmaj7/G")
    }
}
