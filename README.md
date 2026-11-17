# JazzyChords

AUv3 MIDI FX chord trigger for Logic Pro (Apple Silicon), focused on soulful/deep house harmony plus jazz and R&B colours.

- **Pads mode:** the 12 keys of the trigger octave (default C1–B1) each play a chord from the current bank; other keys pass through.
- **Transpose mode:** every key is a root; the selected chord type is built on it.
- Voicings (close, drop 2, drop 3, spread, house stab), inversions, octave, automatic voice leading.
- Strum (up/down/alternate) and humanize (timing/velocity).
- Six factory banks, user presets, and per-project state saved by Logic.

## Build

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project JazzyChords.xcodeproj -scheme JazzyChords -derivedDataPath build build
open build/Build/Products/Debug/JazzyChords.app   # registers the extension
auval -v aumi Jzch Fmth                           # validate
```

Then in Logic Pro: Software Instrument track → MIDI FX → Audio Units → Frank Mathy → JazzyChords.
If it doesn't appear, use Settings → Plug-in Manager → Reset & Rescan.

## Layout

- `ChordCore/` – Swift package with chord qualities, voicing, voice leading and banks (`swift test`).
- `JazzyChordsAU/` – the Audio Unit extension: `ChordKernel` (allocation-free real-time engine), `JazzyChordsAudioUnit`, SwiftUI UI.
- `JazzyChords/` – container app that also hosts the plugin with a test sampler.
