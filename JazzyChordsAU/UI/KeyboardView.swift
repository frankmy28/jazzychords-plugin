import ChordCore
import SwiftUI

/// Five-octave keyboard (C1–C6) lighting up the notes JazzyChords is sending.
/// In Pad mode the trigger octave is marked underneath.
struct KeyboardView: View {
    let model: PluginViewModel

    private let lowNote = 36
    private let highNote = 96
    private static let blackKeys: Set<Int> = [1, 3, 6, 8, 10]

    var body: some View {
        Canvas { context, size in
            let whiteNotes = (lowNote...highNote).filter { !Self.blackKeys.contains($0 % 12) }
            let whiteWidth = size.width / CGFloat(whiteNotes.count)
            let keyHeight = size.height - 5
            var whiteX: [Int: CGFloat] = [:]

            for (index, note) in whiteNotes.enumerated() {
                let x = CGFloat(index) * whiteWidth
                whiteX[note] = x
                let rect = CGRect(x: x + 0.5, y: 0, width: whiteWidth - 1, height: keyHeight)
                let path = Path(roundedRect: rect, cornerRadius: 2.5)
                if model.isSounding(note) {
                    context.fill(path, with: .linearGradient(
                        Gradient(colors: [Theme.accent, Theme.accentSecondary]),
                        startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
                } else {
                    context.fill(path, with: .color(Color.white.opacity(0.88)))
                }
                if note % 12 == 0 {
                    context.draw(Text(PitchClass.noteName(note)).font(.system(size: 7)).foregroundStyle(.black.opacity(0.5)),
                                 at: CGPoint(x: rect.midX, y: keyHeight - 6))
                }
            }

            let blackWidth = whiteWidth * 0.6
            for note in lowNote...highNote where Self.blackKeys.contains(note % 12) {
                guard let leftX = whiteX[note - 1] else { continue }
                let rect = CGRect(x: leftX + whiteWidth - blackWidth / 2, y: 0,
                                  width: blackWidth, height: keyHeight * 0.6)
                let path = Path(roundedRect: rect, cornerRadius: 2)
                context.fill(path, with: .color(model.isSounding(note) ? Theme.accentSecondary : Color(white: 0.12)))
            }

            if model.mode == .pad,
               let start = whiteX[model.triggerBaseNote],
               let end = whiteX[model.triggerBaseNote + 11] {
                let bar = CGRect(x: start, y: size.height - 3, width: end + whiteWidth - start, height: 3)
                context.fill(Path(roundedRect: bar, cornerRadius: 1.5), with: .color(Theme.accent.opacity(0.7)))
            }
        }
    }
}
