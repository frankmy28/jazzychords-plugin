import AVFoundation
import CoreAudioKit
import SwiftUI

/// Container app. Logic Pro finds the plugin once this app has been launched
/// once; the app also hosts the plugin with a simple sampler for quick tests.
@main
struct JazzyChordsApp: App {
    var body: some Scene {
        WindowGroup("JazzyChords") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @State private var host = PluginHost()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("JazzyChords is installed.")
                    .font(.title2.bold())
                Text("In Logic Pro, create a Software Instrument track and choose MIDI FX ▸ Audio Units ▸ Frank Mathy ▸ JazzyChords. If it is missing, open Logic Pro ▸ Settings ▸ Plug-in Manager and click Reset & Rescan Selection.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Below is a live preview: the pads play through a built-in test sampler.")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 780, alignment: .leading)

            Group {
                if let viewController = host.viewController {
                    PluginView(viewController: viewController)
                } else {
                    Text(host.status)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 780, height: 540)
        }
        .padding(16)
        .task { await host.load() }
    }
}

private struct PluginView: NSViewControllerRepresentable {
    let viewController: NSViewController

    func makeNSViewController(context: Context) -> NSViewController { viewController }
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

@MainActor
@Observable
final class PluginHost {
    private(set) var viewController: NSViewController?
    private(set) var status = "Loading plugin…"

    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var plugin: AVAudioUnit?

    static let componentDescription = AudioComponentDescription(
        componentType: kAudioUnitType_MIDIProcessor,
        componentSubType: fourCharCode("Jzch"),
        componentManufacturer: fourCharCode("Fmth"),
        componentFlags: 0,
        componentFlagsMask: 0)

    func load() async {
        guard plugin == nil else { return }
        do {
            let unit = try await AVAudioUnit.instantiate(with: Self.componentDescription, options: .loadOutOfProcess)
            plugin = unit
            startEngine(with: unit)
            viewController = await withCheckedContinuation { continuation in
                unit.auAudioUnit.requestViewController { continuation.resume(returning: $0) }
            }
            if viewController == nil { status = "The plugin has no interface." }
        } catch {
            status = "Could not load JazzyChords: \(error.localizedDescription)"
        }
    }

    private func startEngine(with unit: AVAudioUnit) {
        engine.attach(unit)
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        engine.connectMIDI(unit, to: sampler, format: nil, eventListBlock: nil)
        // An electric piano from the system General MIDI bank, if available.
        let bank = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        try? sampler.loadSoundBankInstrument(at: bank, program: 4, bankMSB: 0x79, bankLSB: 0)
        do {
            try engine.start()
        } catch {
            status = "Audio engine failed: \(error.localizedDescription)"
        }
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    string.utf8.reduce(0) { $0 << 8 | FourCharCode($1) }
}
