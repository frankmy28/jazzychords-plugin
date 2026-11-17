import ChordCore
import SwiftUI

struct MainView: View {
    let model: PluginViewModel

    var body: some View {
        VStack(spacing: 10) {
            HeaderBar(model: model)
            HStack(alignment: .top, spacing: 10) {
                PadGridView(model: model)
                    .frame(width: 370)
                ChordEditorView(model: model)
            }
            .frame(height: 250)
            VoicingControlsView(model: model)
            KeyboardView(model: model)
                .frame(height: 54)
        }
        .padding(12)
        .frame(minWidth: 760, minHeight: 520)
        .background(Theme.background)
        .environment(\.colorScheme, .dark)
        .tint(Theme.accent)
    }
}

struct HeaderBar: View {
    let model: PluginViewModel
    @State private var showingSave = false
    @State private var newPresetName = ""

    var body: some View {
        HStack(spacing: 14) {
            Text("JazzyChords")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accentGradient)

            Picker("", selection: model.intBinding(.mode)) {
                ForEach(TriggerMode.allCases, id: \.rawValue) { Text($0.displayName).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 170)

            if model.mode == .pad {
                Stepper(value: model.intBinding(.triggerOctave), in: -2...8) {
                    Text("Keys \(PitchClass.noteName(model.triggerBaseNote))–\(PitchClass.noteName(model.triggerBaseNote + 11))")
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(Theme.secondaryText)
                }
                .help("The octave whose keys trigger the 12 pads. Other keys pass through.")
            }

            Spacer()

            Menu {
                Section("Factory Banks") {
                    ForEach(model.factoryPresets, id: \.number) { preset in
                        Button(preset.name) { model.load(preset) }
                    }
                }
                if !model.userPresets.isEmpty {
                    Section("User Presets") {
                        ForEach(model.userPresets, id: \.number) { preset in
                            Button(preset.name) { model.load(preset) }
                        }
                    }
                }
                Divider()
                Button("Save Preset…") {
                    newPresetName = model.bank.name
                    showingSave = true
                }
                if let current = model.currentUserPreset {
                    Button("Delete “\(current.name)”", role: .destructive) { model.deleteCurrentUserPreset() }
                }
            } label: {
                Label(model.presetName, systemImage: "music.note.list")
            }
            .menuStyle(.button)
            .frame(maxWidth: 230)
            .popover(isPresented: $showingSave, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Save Preset").font(.headline)
                    TextField("Name", text: $newPresetName)
                        .frame(width: 220)
                        .onSubmit(save)
                    HStack {
                        Spacer()
                        Button("Cancel") { showingSave = false }
                        Button("Save", action: save).keyboardShortcut(.defaultAction)
                    }
                }
                .padding(12)
            }
        }
    }

    private func save() {
        model.saveUserPreset(named: newPresetName)
        showingSave = false
    }
}
