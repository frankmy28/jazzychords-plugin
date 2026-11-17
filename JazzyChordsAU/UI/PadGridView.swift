import SwiftUI

struct PadGridView: View {
    let model: PluginViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        Panel(title: model.mode == .pad ? "Pads — click to audition" : "Roots — click to audition") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<12, id: \.self) { pad in
                    PadView(
                        keyLabel: model.padKeyLabel(pad),
                        chordName: model.padName(pad),
                        selected: model.selectedPad == pad && model.mode == .pad,
                        held: model.isPadHeld(pad),
                        onDown: { model.padDown(pad) },
                        onUp: { model.padUp(pad) })
                }
            }
        }
    }
}

private struct PadView: View {
    let keyLabel: String
    let chordName: String
    let selected: Bool
    let held: Bool
    let onDown: () -> Void
    let onUp: () -> Void

    @State private var pressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(keyLabel)
                .font(.system(size: 9, weight: .medium).monospacedDigit())
                .foregroundStyle(held ? Color.black.opacity(0.6) : Theme.secondaryText)
            Spacer(minLength: 0)
            Text(chordName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(held ? Color.black : Color.white)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(held ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Color.white.opacity(0.07)))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? Theme.accent : Color.white.opacity(0.06), lineWidth: selected ? 1.5 : 1)
        }
        .scaleEffect(pressed ? 0.96 : 1)
        .animation(.easeOut(duration: 0.08), value: pressed)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        pressed = true
                        onDown()
                    }
                }
                .onEnded { _ in
                    pressed = false
                    onUp()
                })
    }
}
