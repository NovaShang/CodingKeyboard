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
⇥ ← →  \  /  `  [  ]  '  ;  -  =     (12 keys sharing 10 columns)
1  2  3  4  5  6  7  8  9  0
  Q  W  E  R  T  Y  U  I  O  P
    A  S  D  F  G  H  J  K  L
⇧    Z  X  C  V  B  N  M    ⌫
🌐  ⌄  Term    ␣     ,  .   ↵
```

**Landscape / iPad** — a Mac-like 5-row layout with a dedicated Caps Lock, a wide
space bar, and cursor keys flanking it. Which layout you get is chosen on available
width, not device: anything wider than 500pt gets the landscape one, so an iPad uses
it in both orientations and a narrow Split View falls back to portrait.

Shifted values are printed on every key, so `!@#$%^&*()`, `{}`, `|`, `~`, `_`, `+`,
`:`, `"`, `<`, `>`, `?` are all one modifier away.

## Terminal mode

A custom keyboard has no API for sending key *events* — `UITextDocumentProxy` offers
`insertText`, `deleteBackward` and `adjustTextPosition` and nothing else. That turns out
not to matter for a terminal, because a terminal does not receive key events either: the
PTY sees a byte stream. Insert the byte a real keyboard would have produced and the shell
cannot tell the difference, provided the host terminal forwards inserted text to the PTY.

Terminal mode does exactly that. It adds `Esc`, `Ctrl` and `Opt`, a full cursor cluster,
Home/End/PgUp/PgDn/⌦ and F1–F12, and rewires what every key sends:

| Key | Normal mode | Terminal mode |
| --- | --- | --- |
| Return | `\n` | `\r` (0x0D) |
| Delete | `deleteBackward()` | `deleteBackward()` — ⌥⌫ is `ESC` `DEL`, ⌃⌫ is `0x08` |
| ⌦ | — | `ESC [ 3~` |
| ← → | `adjustTextPosition` | `ESC [ D` / `ESC [ C` |
| ↑ ↓ | — | `ESC [ A` / `ESC [ B` |
| Home / End | — | `ESC [ H` / `ESC [ F` |
| PgUp / PgDn | — | `ESC [ 5~` / `ESC [ 6~` |
| F1–F4 | — | `ESC O P`…`ESC O S` |
| F5–F12 | — | `ESC [ 15~`, `17~`, `18~`, `19~`, `20~`, `21~`, `23~`, `24~` |
| Esc | — | `0x1B` |
| Tab | `\t` | `\t`, and ⇧Tab is back-tab: `ESC [ Z` |
| Space | `" "` | `" "`, and ⌃Space is `NUL` (0x00) |
| ⌃ + letter | — | the C0 byte: ⌃A = 0x01 … ⌃Z = 0x1A |
| ⌃ + `@ [ \ ] ^ _` | — | 0x00 0x1B 0x1C 0x1D 0x1E 0x1F |
| ⌥ + any key | — | `ESC` then the key — Meta is an ESC prefix |

`Ctrl` and `Opt` latch exactly like Shift (tap, hold, double-tap to lock) and stack with
it and with each other. A modifier engages the instant the finger lands, so holding `Ctrl`
with one thumb and typing with the other behaves like a physical keyboard. Control ignores
Shift, since ⌃A and ⌃a are the same byte; Option does not, so ⌥⇧B sends `ESC` `B`.

Modified cursor keys use xterm's encoding — `ESC [ 1;<n> <final>`, where n is 1 plus a
bitmask of Shift(1), Alt(2), Control(4) — so ⌃← is `ESC [ 1;5D`. The exception is ⌥← and
⌥→, which send readline's `ESC b` and `ESC f`: word-wise movement is what they are for,
and readline does not understand the CSI form without a custom inputrc.

Unmodified cursor keys go out in the normal `ESC [` form rather than the application-mode
`ESC O` form. Which one a terminal wants depends on DECCKM, which is invisible from inside
a keyboard extension; `ESC [` is accepted by bash/readline, vim and less alike.

**Turning it on** — the `Term` key on the bottom row, in both orientations. It highlights
like a locked Shift while the mode is active.

Terminal mode never changes the keyboard's size or its grid: the same six rows in portrait
and five in landscape, on the same columns, so no key you already know moves. Everything it
adds goes on the first row, which scrolls sideways to hold it.

The setting persists in the extension's own `UserDefaults`. It is deliberately *not* an
App Group: this keyboard declares `RequestsOpenAccess = false`, and without full access an
extension cannot reach a shared container at all. The container app therefore cannot see
or change the mode — the switch lives on the keyboard.

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
| `KeyModels.swift` | `KeyDef`, `KeyAction`, `KeyEvent`, `ShiftState`, `ModifierLatch` |
| `KeyboardRowData.swift` | Row definitions for both orientations and both modes |
| `CodingKeyboardView.swift` | Layout, sizing, modifier and terminal-mode state |
| `KeyCap.swift` | Visual key rendering, press feedback, key repeat, long press |
| `KeyButton.swift` | Bridges `KeyDef` → `KeyCap`, computes widths from the unit grid |
| `ShiftKeyCap.swift` | Latching modifier caps: Shift, Caps Lock, ctrl, opt, term |
| `GlobeKeyButton.swift` | UIKit-backed globe key using `handleInputModeList` |
| `KeyboardViewController.swift` | Extension entry point, turns a `KeyEvent` into text or terminal bytes |

## License

MIT — see [LICENSE](LICENSE).
