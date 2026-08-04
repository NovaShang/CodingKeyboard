# Coding Keyboard

An iOS custom keyboard built for typing code on a phone or iPad. Every character
you reach for in a terminal or an editor — brackets, backtick, pipe, slash, tilde —
sits on the first layer, with no symbol-page toggling.

Written in SwiftUI. No network access, no analytics, no data collection.

## Why

The stock iOS keyboard hides `{`, `}`, `[`, `]`, `\`, `|`, `` ` `` and `~` behind two
levels of page switching. That is fine for prose and miserable for code, SSH sessions,
and config files. Coding Keyboard puts them all on the primary layer and adds Tab,
cursor arrows, and a real Shift with lock.

## Layout

**Portrait** — 10 columns × 6 rows:

```
⇥  ←  →  [  ]  '  ;  -  =  ↓
1  2  3  4  5  6  7  8  9  0
  Q  W  E  R  T  Y  U  I  O  P
    A  S  D  F  G  H  J  K  L
⇧    Z  X  C  V  B  N  M    ⌫
🌐  \  /  `   ␣    ,  .   ↵
```

**Landscape / iPad** — a Mac-like 5-row layout with a dedicated Caps Lock, a wide
space bar, and cursor keys flanking it.

Shifted values are printed on every key, so `!@#$%^&*()`, `{}`, `|`, `~`, `_`, `+`,
`:`, `"`, `<`, `>`, `?` are all one modifier away.

## Shift behavior

The Shift key has three states, matching a physical keyboard more closely than iOS does:

| Gesture | State | Resets |
| --- | --- | --- |
| Single tap | `on` | after the next character |
| Double tap | `locked` | on the next Shift press |
| Press and hold | `momentary` | when you lift your finger |

Shift engages on finger-**down**, not on lift and not after a hold threshold, so the
physical-keyboard habit works: hold Shift with one thumb and type with the other, and
the very first keystroke is already capitalized. What a press *meant* is decided when
you lift — if you typed while holding, it was a held modifier and Shift drops; if you
didn't, it was a tap and Shift stays on for the next character.

## Privacy

The keyboard extension declares `RequestsOpenAccess = false`. It has no network
capability whatsoever, records nothing, and includes no third-party SDKs. See
[docs/privacy-policy.html](docs/privacy-policy.html).

## Building

Requires Xcode 26.3+ and iOS 18.6+.

```sh
open CodingKeyboard.xcodeproj
```

The project has two targets: `CodingKeyboard` (the container app, which holds the
setup instructions and a scratch text field) and `KeyboardExtension` (the keyboard
itself). Most of the UI lives in the `CodingKeyboard/` folder and is shared with the
extension via target membership.

To build from the command line:

```sh
xcodebuild -project CodingKeyboard.xcodeproj -scheme CodingKeyboard \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

### Signing

No signing identity is committed. Simulator builds work straight from a fresh clone
with no setup. To build to a device, supply your own Team ID:

```sh
cp Configuration/Local.xcconfig.example Configuration/Local.xcconfig
# then edit DEVELOPMENT_TEAM in that file
```

`Configuration/Local.xcconfig` is gitignored. `Configuration/Base.xcconfig` pulls it in
with an optional `#include?`, so the project still configures cleanly when the file is
absent. If you fork this, also point `PRODUCT_BUNDLE_IDENTIFIER` at a prefix you own —
the example file shows where.

## Enabling the keyboard

Settings → General → Keyboard → Keyboards → Add New Keyboard → **Coding Keyboard**.
Then long-press the 🌐 key on any keyboard to switch to it.

## Source layout

| File | Purpose |
| --- | --- |
| `KeyModels.swift` | `KeyDef`, `KeyAction`, `ShiftState` |
| `KeyboardRowData.swift` | Row definitions for both orientations |
| `CodingKeyboardView.swift` | Layout, sizing, Shift gesture state machine |
| `KeyCap.swift` | Visual key rendering, press feedback, key repeat |
| `KeyButton.swift` | Bridges `KeyDef` → `KeyCap`, computes widths from the unit grid |
| `ShiftKeyCap.swift` | Shift/Caps Lock key with its own gesture handling |
| `GlobeKeyButton.swift` | UIKit-backed globe key using `handleInputModeList` |
| `KeyboardViewController.swift` | Extension entry point, applies actions to `textDocumentProxy` |

## License

MIT — see [LICENSE](LICENSE).
