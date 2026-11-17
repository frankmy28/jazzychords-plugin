import SwiftUI

enum Theme {
    static let background = LinearGradient(
        colors: [Color(red: 0.09, green: 0.07, blue: 0.13), Color(red: 0.05, green: 0.04, blue: 0.08)],
        startPoint: .top, endPoint: .bottom)
    static let panel = Color.white.opacity(0.05)
    static let panelStroke = Color.white.opacity(0.08)
    static let accent = Color(red: 1.0, green: 0.62, blue: 0.27)
    static let accentSecondary = Color(red: 0.86, green: 0.33, blue: 0.62)
    static let accentGradient = LinearGradient(colors: [accent, accentSecondary],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
    static let secondaryText = Color.white.opacity(0.55)
}

struct Panel<Content: View>: View {
    let title: String
    var detail: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.secondaryText)
                if let detail {
                    Text(detail)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
            }
            content
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.panelStroke))
    }
}

/// A compact selectable chip used for roots, chord types and segmented choices.
struct Chip: View {
    let label: String
    let selected: Bool
    var minWidth: CGFloat = 0
    var fill = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                .lineLimit(1)
                .frame(minWidth: minWidth, maxWidth: fill ? .infinity : nil)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 6).fill(Theme.accentGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.07))
                    }
                }
                .foregroundStyle(selected ? Color.black : Color.white.opacity(0.85))
        }
        .buttonStyle(.plain)
    }
}
