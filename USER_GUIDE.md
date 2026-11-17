# JazzyChords User Guide

JazzyChords is a MIDI FX plugin for Logic Pro that turns single notes into full chords. Its chord types and banks come from soulful and deep house, with extra colours from jazz, R&B, neo-soul and gospel. Play one key and you get a voiced Am9, a rootless house stab or an altered dominant. You can strum chords like a guitarist and humanize them so they feel played rather than programmed.

---

## Contents

1. [Installation](#1-installation)
2. [Loading the plugin in Logic Pro](#2-loading-the-plugin-in-logic-pro)
3. [The interface at a glance](#3-the-interface-at-a-glance)
4. [Trigger modes: Pads and Transpose](#4-trigger-modes-pads-and-transpose)
5. [Editing chords](#5-editing-chords)
6. [Voicing](#6-voicing)
7. [Strum & Humanize](#7-strum--humanize)
8. [Velocity](#8-velocity)
9. [Presets and banks](#9-presets-and-banks)
10. [Automation](#10-automation)
11. [How JazzyChords handles MIDI](#11-how-jazzychords-handles-midi)
12. [Reference: chord types](#12-reference-chord-types)
13. [Reference: factory banks](#13-reference-factory-banks)
14. [Tips for soulful house](#14-tips-for-soulful-house)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Installation

JazzyChords is an Audio Unit (AUv3) extension that comes inside the **JazzyChords** app.

1. Copy **JazzyChords.app** to your Applications folder. If you build it yourself, see `README.md`.
2. **Open the app once.** This registers the plugin with macOS, and you don't need to keep the app running afterwards.
3. The app window shows a live preview of the plugin. Clicking pads plays them through a built-in electric piano, so you can try chords without opening Logic.

> Requirements: a Mac with Apple silicon, macOS 15.4 or later, and Logic Pro.

---

## 2. Loading the plugin in Logic Pro

1. Create or select a **Software Instrument** track and pick any instrument: Rhodes, pad, organ or piano all work well.
2. In the channel strip, click the **MIDI FX** slot above the instrument slot.
3. Choose **Audio Units → Frank Mathy → JazzyChords**.
4. Play your keyboard. In Pads mode, the default trigger keys are **C1–B1**.

JazzyChords also works with GarageBand and other hosts that support AUv3 MIDI effects.

---

## 3. The interface at a glance

```
┌──────────────────────────────────────────────────────────────────────┐
│ JazzyChords  [Pads|Transpose]  Keys C1–B1 ⇅         [♫ Preset ▾]    │  ← Header
├───────────────────────────────┬──────────────────────────────────────┤
│ PADS                          │ PAD D1  Em7                          │
│ ┌────┐┌────┐┌────┐┌────┐      │ [C][D♭][D][E♭][E][F]  ← root         │
│ │Am9 ││Dm9 ││Em7 ││Fmaj9│     │ [G♭][G][A♭][A][B♭][B]                │
│ └────┘└────┘└────┘└────┘      │ [House|Jazz|R&B]      ← category     │
│  … 12 pads (4 × 3) …          │ m7 m9 m11 maj9 6/9 …  ← chord type   │
│                               │ Bass [Root ▾]         ← slash bass   │
├───────────────┬───────────────┴───────┬──────────────────────────────┤
│ VOICING       │ STRUM & HUMANIZE      │ VELOCITY                     │
├───────────────┴───────────────────────┴──────────────────────────────┤
│ ▁▁▁ keyboard C1–C6: lit keys = notes being sent ▁▁▁                  │
└──────────────────────────────────────────────────────────────────────┘
```

| Area | What it does |
|---|---|
| **Header** | Switches the trigger mode, sets the trigger octave (Pads mode only) and opens the preset menu. |
| **Pads** | Twelve pads, one per key of the trigger octave. Click and hold a pad to hear it, and release to stop. Pads light up while they sound, whether you clicked them or played them from the keyboard. |
| **Chord editor** | Changes the chord on the selected pad (outlined in orange), or the chord type in Transpose mode. |
| **Voicing** | Sets how the chord notes are spread across the keyboard. |
| **Strum & Humanize** | Spreads notes in time and adds random variation. |
| **Velocity** | Uses the velocity you play or a fixed velocity, and optionally adds the key you played to the chord. |
| **Keyboard** | Shows the notes JazzyChords is sending right now. In Pads mode, an orange bar marks the trigger octave. |

---

## 4. Trigger modes: Pads and Transpose

Switch modes with the **Pads | Transpose** control in the header.

### Pads mode (chord memory)

- The **12 keys of the trigger octave** (C to B) each play one pad: C plays pad 1, C♯ plays pad 2, and so on up to B for pad 12.
- Each pad holds a complete chord with its own root, chord type and optional bass note. A bank can therefore hold a whole progression, such as Am9 → Dm9 → G13sus → Cmaj9, playable with one finger.
- Set the trigger octave with the **Keys C1–B1** stepper. It ranges from C-2 to C8 and uses Logic's naming, where middle C is C3.
- **Keys outside the trigger octave pass through unchanged.** You can play a bass line with your left hand and trigger chords with one finger, or play a melody above the chords.
- Pad chords sound in a fixed register, with the root between C2 and B2 plus any octave shift, no matter where the trigger octave is.

### Transpose mode (one chord type everywhere)

- **Every key is a root.** JazzyChords builds the selected chord type on whatever note you play. With **m9** selected, D gives Dm9 and F gives Fm9.
- The chord follows the register of your hand: playing higher gives a higher chord.
- Choose the chord type in the editor on the right. The pads then show that type on all 12 roots (Cm9, D♭m9 …) for auditioning.
- This is the classic deep house "one-finger minor chord" technique. Play a melody with one finger and every note becomes a chord stab.

---

## 5. Editing chords

### In Pads mode

1. **Select a pad** by clicking it. Clicking also auditions the pad.
2. **Root:** click one of the 12 note buttons.
3. **Category:** choose **House**, **Jazz** or **R&B** to filter the chord types.
4. **Chord type:** click a type. The pad name updates straight away.
5. **Bass:** choose **Root** for a normal chord, or pick a note for a **slash chord**. For example, choose F root, maj7 type and bass G to get **Fmaj7/G**. The bass note always sits below the chord.

Edits apply instantly, even while you are playing. Notes that are already held finish exactly as they started, so a chord never gets stuck when you change it mid-note.

### In Transpose mode

Only the category and chord type are shown. Picking a type sets the **Chord Type** parameter, which you can also automate (see [Automation](#10-automation)).

> **Tip:** edits change the *current bank*. To keep them, save a user preset (see [Presets and banks](#9-presets-and-banks)). They are also stored with your Logic project automatically.

---

## 6. Voicing

### Style

| Style | Sound | What it does |
|---|---|---|
| **Close** | Compact and direct | Stacks every chord tone upward from the root. |
| **Drop 2** | Warm Rhodes/keys spread | Moves the second-highest note down an octave. |
| **Drop 3** | Wider, more open | Moves the third-highest note down an octave. |
| **Spread** | Big pads, strings | Puts the root in the bass and opens up the upper notes (drop 2 + 4). |
| **House Stab** | The classic deep house organ/keys stab | Leaves out the root, and the 5th on larger chords, to give a tight four-note voicing. Am9 becomes **C E G B**. |

Drop 2, Drop 3 and Spread need chords with at least four notes. Triads such as *sus2* stay in close position, and Spread still adds its bass root.

### Inversion (Root / 1st / 2nd / 3rd)

Moves the lowest note(s) up an octave. This works only when **Voice leading is off**; otherwise the buttons are greyed out.

### Voice leading (on by default)

JazzyChords picks the inversion and octave of each new chord so the notes move as little as possible from the previous chord, the way a keyboard player's hands would. It also pulls back gently toward the chord's home register, so long progressions don't creep up or down the keyboard.

Turn it off to set inversions yourself, or to get identical voicings every time.

### Oct

Shifts the whole chord by −2 to +2 octaves.

---

## 7. Strum & Humanize

| Control | Range | Effect |
|---|---|---|
| **Strum** | 0–100 ms | Total time from the first note of the chord to the last. 0 plays all notes at once. 15–30 ms gives a natural, soft attack; 60–100 ms sounds like a harp or guitar. |
| **Up / Down / Alt** | — | Strum direction. **Up** plays the lowest note first, **Down** the highest first, and **Alt** switches direction with each chord, like strumming a guitar down and up. |
| **Timing** | 0–30 ms | Delays each note by a random amount, so chords don't sound machine-tight. Notes are only ever delayed, never moved earlier. |
| **Velocity** | ±0–30 | Gives each note its own random velocity, for a more human, uneven touch. |

If you release a key before a strum has finished, the notes that haven't played yet are cancelled.

---

## 8. Velocity

| Control | Effect |
|---|---|
| **As played** | Chord notes use the velocity you played with. |
| **Fixed** + **Level** (1–127) | Every chord uses the same velocity, which suits steady, programmed-sounding stabs. |
| **Play trigger note** | Adds the key you physically played to the chord. In Transpose mode this doubles your melody note at its original pitch. It doesn't apply to pads clicked in the interface. |

Humanize velocity is applied on top of either mode.

---

## 9. Presets and banks

Open the preset menu at the top right. The button shows the current preset name.

### Factory banks

There are six ready-made banks of 12 chords each (see [Reference: factory banks](#13-reference-factory-banks)). **Loading a factory bank replaces the chords only.** Voicing, strum, velocity and mode stay as they are, so you can try different progressions with the same feel.

### User presets

- **Save Preset…** stores the current bank **and all settings** under a name you choose. User presets appear in the **User Presets** section of the menu.
- **Delete "…"** removes the current user preset. It only appears when a user preset is loaded.
- User presets are shared between all your Logic projects.

### Saved with your project

Logic stores the full JazzyChords state (bank and all settings) in your project. Reopening the project restores everything, including chords you edited but never saved as a preset.

You can also use Logic's own plug-in header preset menu to save and recall settings.

---

## 10. Automation

Every control except the chord bank itself can be automated in Logic:

Mode · Trigger Octave · Chord Type · Inversion · Voicing · Octave · Voice Leading · Strum · Strum Direction · Humanize Timing · Humanize Velocity · Velocity · Fixed Velocity · Play Trigger Note

Some ideas:
- Automate **Chord Type** in Transpose mode to switch from m9 to m11 in the breakdown.
- Bring **Strum** up gradually through a build.
- Switch **Voicing** from House Stab to Spread for the drop.

---

## 11. How JazzyChords handles MIDI

- **Note on/off:** turned into chords as described above. Each key remembers exactly which notes it started and releases those notes, even if you changed the bank or settings while holding it.
- **Overlapping chords:** if two held chords share a note, that note is re-struck by the newer chord. It keeps sounding until *both* keys are released.
- **Sustain pedal, mod wheel, pitch bend, aftertouch and other controllers** pass straight through to your instrument.
- **All Notes Off / All Sound Off** (CC 123 / 120) release every chord.
- **Stopping Logic's transport** releases any chords still sounding, so stopping never leaves hanging notes.
- **Bypass:** when the plugin is bypassed, MIDI passes through unchanged.
- **Recording:** Logic records the keys you *play*, not the chords. JazzyChords generates the chords on playback, so you can still change the bank or voicing afterwards. If you want the chord notes themselves as MIDI regions, check whether your Logic version offers **Record MIDI to Track Here** in the MIDI FX slot menu.

---

## 12. Reference: chord types

The notes below are built on C.

### House

| Symbol | Notes on C | Character |
|---|---|---|
| m7 | C E♭ G B♭ | The basic minor groove chord |
| **m9** | C E♭ G B♭ D | *The* deep house chord |
| m11 | C E♭ G B♭ D F | Darker and more suspended |
| m7(11) | C E♭ G B♭ F | m11 without the 9th, more open |
| maj7 | C E G B | Bright and dreamy |
| maj9 | C E G B D | Lush, uplifting |
| 6/9 | C E G A D | Shimmering, resolved |
| m6/9 | C E♭ G A D | Bittersweet, Dorian |
| 7sus4 | C F G B♭ | Floating dominant |
| 9sus | C F G B♭ D | Gospel/house turnaround |
| 13sus | C F B♭ D A | Wide and open |
| add9 | C E G D | Clean pop-house |
| m(add9) | C E♭ G D | Moody, simple |
| 9 | C E G B♭ D | Funky dominant |
| maj9♯11 | C E B D F♯ | Lydian, airy (no 5th) |

### Jazz

| Symbol | Notes on C | Character |
|---|---|---|
| 7 | C E G B♭ | Dominant |
| 13 | C E B♭ D A | Rich dominant (no 5th) |
| 7♭9 | C E G B♭ D♭ | Tense, resolves to minor |
| 7♯9 | C E G B♭ D♯ | Bluesy "Hendrix" chord |
| 7♯11 | C E G B♭ F♯ | Lydian dominant |
| 13♭9 | C E B♭ D♭ A | Dark, sophisticated |
| 7alt | C E B♭ D♭ D♯ A♭ | Maximum tension |
| m7♭5 | C E♭ G♭ B♭ | Half-diminished, the ii of minor keys |
| m9♭5 | C E♭ G♭ B♭ D | Softer half-diminished |
| dim7 | C E♭ G♭ A | Passing chord |
| m(maj7) | C E♭ G B | Mysterious, cinematic |
| m(maj9) | C E♭ G B D | Noir |
| maj7♯5 | C E G♯ B | Augmented colour |
| 6 | C E G A | Vintage, sweet |

### R&B / Neo-Soul / Gospel

| Symbol | Notes on C | Character |
|---|---|---|
| maj13 | C E B D A | Silky neo-soul major |
| m13 | C E♭ B♭ D A | Smooth minor |
| 11 | C G B♭ D F | Gospel "sus" dominant (no 3rd) |
| 13♯11 | C E B♭ D F♯ A | Bright, complex dominant |
| 7♯5♯9 | C E G♯ B♭ D♯ | Gritty neo-soul tension |
| m6 | C E♭ G A | Classic soul minor |
| sus2 | C D G | Open and ambiguous |
| maj9sus | C F G B D | Hovering major |
| m11♭5 | C E♭ G♭ B♭ F | Dark, modern R&B |

---

## 13. Reference: factory banks

Keys are shown with the default trigger octave (C1–B1).

| Key | Deep House Classics | Kerri-style Minor | Fingers / Larry Heard | Jazz ii-V-I | Neo-Soul / R&B | Gospel Turnarounds |
|---|---|---|---|---|---|---|
| C1 | Am9 | Cm9 | Dm9 | Dm9 | E♭maj13 | Cmaj9 |
| D♭1 | Dm9 | E♭maj9 | Fmaj9 | G13 | Dm11 | E7♯9 |
| D1 | Em7 | Fm9 | Gm9 | Cmaj9 | G7♯5♯9 | Am9 |
| E♭1 | Fmaj9 | Gm7 | Am7 | Em7♭5 | Cm13 | D9 |
| E1 | G13sus | A♭maj9 | B♭maj9 | A7alt | F11 | Dm11 |
| F1 | Cmaj9 | B♭9sus | C9sus | Dm(maj9) | B♭maj9 | G13sus |
| G♭1 | Bm7♭5 | Cm11 | E♭maj9♯11 | Fm9 | A♭maj9sus | G7alt |
| G1 | E7♯9 | Dm7♭5 | Fm9 | B♭13 | D♭maj13 | Fmaj13 |
| A♭1 | Fm9 | Fm11 | Gm11 | E♭maj9 | Fm9/A♭ | G♭m7♭5 |
| A1 | B♭maj9 | G7♯9 | A♭maj9 | A♭7♯11 | B♭13♯11 | B7♯9 |
| B♭1 | E♭maj9 | A♭maj9♯11 | B♭13sus | G7♭9 | Am11♭5 | Em11 |
| B1 | A♭6/9 | B♭13sus | Dm11 | C6/9 | G♭maj9 | Fmaj7/G |

**Progressions to try:**

- **Deep House Classics:** C1 → D♭1 → E1 → F1 (Am9 → Dm9 → G13sus → Cmaj9)
- **Kerri-style Minor:** C1 → A♭1 → E1 → F1 (Cm9 → Fm11 → A♭maj9 → B♭9sus)
- **Jazz ii-V-I:** C1 → D♭1 → D1 (Dm9 → G13 → Cmaj9), or the minor ii-V E♭1 → E1 → F1
- **Gospel Turnarounds:** C1 → D♭1 → D1 → E♭1 (Cmaj9 → E7♯9 → Am9 → D9)

---

## 14. Tips for soulful house

- **The one-finger stab:** use Transpose mode with **m9** or **m11**, the **House Stab** voicing, Voice leading **on** and Velocity **Fixed** at about 100. Play a rhythm on one or two keys through an organ or a short-release Rhodes.
- **Lush pads:** use **Spread** voicing with **maj9 / m11 / 13sus**, Strum about 20 ms and Humanize Timing about 8 ms, through a slow-attack pad.
- **Live-feeling keys:** use **Drop 2**, Strum 10–15 ms in **Alt** direction, and Humanize Velocity ±10–15.
- **Bass + chords:** in Pads mode, put the trigger octave at C1. Play bass notes from C2 upward with your left hand, since those pass through, and trigger chords with your right. You could also put JazzyChords on a separate instrument track.
- **Slash chords for gospel lift:** build a pad as **Fmaj7/G** or **E♭maj9/F**. A major chord over the root a whole step higher is a classic turnaround sound.

---

## 15. Troubleshooting

| Problem | Solution |
|---|---|
| JazzyChords doesn't appear in Logic | Open the JazzyChords app once. Then in Logic go to **Settings → Plug-in Manager**, select JazzyChords (or all) and click **Reset & Rescan Selection**. |
| It appears under Audio FX or Instruments instead | It is a **MIDI FX** plugin. Load it in the MIDI FX slot of a Software Instrument track. |
| Some keys play single notes | In Pads mode, only the trigger octave plays chords; the orange bar under the keyboard shows where it is. Move it with the **Keys** stepper, or switch to Transpose mode. |
| Chords sound too high or too low | Use **Oct** in the Voicing section, or the instrument's own transpose. |
| The Inversion buttons are greyed out | Voice leading is on and chooses inversions automatically. Turn it off to choose them yourself. |
| Notes hang after stopping | JazzyChords releases its notes when the transport stops and on All Notes Off. If an instrument still hangs, check the sustain pedal (CC 64), which passes through unchanged. |
| A pad click plays nothing in Logic | Pad auditions go to the instrument on the same track. Check that the track has an instrument loaded and the volume is up. |
| My edited bank was lost | Bank edits are saved with the Logic project, or as a user preset via **Save Preset…**. Loading a factory bank replaces the current chords. |
