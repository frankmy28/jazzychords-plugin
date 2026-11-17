import ChordCore
import SwiftUI

struct ChordEditorView: View {
    @Bindable var model: PluginViewModel

    var body: some View {
        Panel(title: model.mode == .pad ? "Pad \(model.padKeyLabel(model.selectedPad))" : "Chord type",
              detail: model.mode == .pad ? model.editedSlot.name : model.transposeQuality.symbol) {
            VStack(alignment: .leading, spacing: 10) {
                if model.mode == .pad {
                    rootPicker
                }
                Picker("", selection: $model.editorCategory) {
                    ForEach(ChordCategory.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 66), spacing: 6)], spacing: 6) {
                        ForEach(ChordQuality.inCategory(model.editorCategory)) { quality in
                            Chip(label: quality.symbol, selected: quality == model.editedQuality, minWidth: 52) {
                                model.setQuality(quality)
                            }
                        }
                    }
                }

                if model.mode == .pad {
                    bassPicker
                }
            }
        }
    }

    private var rootPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
            ForEach(0..<12, id: \.self) { root in
                Chip(label: PitchClass.name(root), selected: model.editedSlot.root == root, fill: true) {
                    model.setRoot(root)
                }
            }
        }
    }

    private var bassPicker: some View {
        HStack {
            Text("Bass")
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
            Picker("", selection: Binding(get: { model.editedSlot.bass ?? -1 },
                                          set: { model.setBass($0 < 0 ? nil : $0) })) {
                Text("Root").tag(-1)
                ForEach(0..<12, id: \.self) { Text("/" + PitchClass.name($0)).tag($0) }
            }
            .labelsHidden()
            .frame(width: 90)
            Spacer()
        }
    }
}
