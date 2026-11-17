import AudioToolbox
import ChordCore
import SwiftUI

struct VoicingControlsView: View {
    let model: PluginViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Panel(title: "Voicing") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Style", selection: model.intBinding(.voicing)) {
                        ForEach(VoicingStyle.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { inversion in
                            Chip(label: ["Root", "1st", "2nd", "3rd"][inversion],
                                 selected: model.intBinding(.inversion).wrappedValue == inversion) {
                                model.set(.inversion, AUValue(inversion))
                            }
                        }
                    }
                    .disabled(model.boolBinding(.voiceLeading).wrappedValue)
                    .opacity(model.boolBinding(.voiceLeading).wrappedValue ? 0.4 : 1)
                    HStack {
                        Toggle("Voice leading", isOn: model.boolBinding(.voiceLeading))
                        Spacer()
                        Stepper("Oct \(signed(model.intBinding(.octaveShift).wrappedValue))",
                                value: model.intBinding(.octaveShift), in: -2...2)
                    }
                    .font(.system(size: 12))
                }
            }
            Panel(title: "Strum & Humanize") {
                VStack(alignment: .leading, spacing: 6) {
                    ParamSlider(label: "Strum", value: model.binding(.strumTime), range: 0...100, format: "%.0f ms")
                    HStack(spacing: 4) {
                        ForEach(StrumDirection.allCases, id: \.rawValue) { direction in
                            Chip(label: direction.displayName,
                                 selected: model.intBinding(.strumDirection).wrappedValue == direction.rawValue) {
                                model.set(.strumDirection, AUValue(direction.rawValue))
                            }
                        }
                    }
                    ParamSlider(label: "Timing", value: model.binding(.humanizeTime), range: 0...30, format: "%.0f ms")
                    ParamSlider(label: "Velocity", value: model.binding(.humanizeVelocity), range: 0...30, format: "±%.0f")
                }
            }
            Panel(title: "Velocity") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("", selection: model.intBinding(.velocityMode)) {
                        Text("As played").tag(0)
                        Text("Fixed").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    ParamSlider(label: "Level", value: model.binding(.fixedVelocity), range: 1...127, format: "%.0f")
                        .disabled(model.intBinding(.velocityMode).wrappedValue == 0)
                        .opacity(model.intBinding(.velocityMode).wrappedValue == 0 ? 0.4 : 1)
                    Toggle("Play trigger note", isOn: model.boolBinding(.passThrough))
                        .font(.system(size: 12))
                }
            }
        }
        .frame(height: 140)
    }

    private func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }
}

struct ParamSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 50, alignment: .leading)
            Slider(value: $value, in: range)
                .controlSize(.small)
            Text(String(format: format, value))
                .font(.system(size: 11).monospacedDigit())
                .frame(width: 42, alignment: .trailing)
        }
    }
}
