import CoreAudioKit
import SwiftUI

/// Extension principal class: creates the audio unit and hosts its SwiftUI interface.
public final class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    static let preferredSize = NSSize(width: 780, height: 540)

    private var audioUnit: JazzyChordsAudioUnit?
    private var hostingView: NSView?

    public override func loadView() {
        view = NSView(frame: NSRect(origin: .zero, size: Self.preferredSize))
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = Self.preferredSize
        embedInterfaceIfReady()
    }

    public nonisolated func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try JazzyChordsAudioUnit(componentDescription: componentDescription, options: [])
        DispatchQueue.main.async {
            self.audioUnit = audioUnit
            self.embedInterfaceIfReady()
        }
        return audioUnit
    }

    private func embedInterfaceIfReady() {
        guard let audioUnit, isViewLoaded, hostingView == nil else { return }
        let host = NSHostingView(rootView: MainView(model: PluginViewModel(audioUnit: audioUnit)))
        host.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.topAnchor.constraint(equalTo: view.topAnchor),
            host.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingView = host
    }
}
