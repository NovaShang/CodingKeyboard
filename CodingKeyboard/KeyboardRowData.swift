import Foundation

// MARK: - Portrait Row Data
// Layout: 10 columns, 6 rows in both modes.
// unitWidth = (totalWidth - 9 * gap) / 10
let portraitTotalCols: CGFloat = 10

/// The keys terminal mode adds that no phone keyboard has room for on the grid: the
/// navigation block and the function row. They ride at the end of the scrolling first row
/// in both orientations, ordered least-used last, so reaching F9 costs a swipe and
/// reaching Home does not.
///
/// Home and End are real keys here rather than shifted faces of ← and →. Riding on the
/// arrows saved two columns back when the row could not scroll; once it can, the columns
/// are free and a key you can press outright beats one you have to spell.
func terminalNavigationKeys() -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "Home", action: .home, units: 1.0))
    r.append(KeyDef(label: "End", action: .end, units: 1.0))
    r.append(KeyDef(label: "PgUp", action: .pageUp, units: 1.0))
    r.append(KeyDef(label: "PgDn", action: .pageDown, units: 1.0))
    r.append(KeyDef(label: "⌦", action: .forwardDelete, units: 1.0))
    return r
}

func terminalFunctionKeys() -> [KeyDef] {
    (1...12).map { KeyDef(label: "F\($0)", action: .function($0), units: 1.0) }
}

/// The key that puts the keyboard away. Portrait moves it between rows with the mode —
/// see `buildRow0Body` — so both callers take it from here.
func hideKey(units: CGFloat = 1.0) -> KeyDef {
    KeyDef(label: "sf:keyboard.chevron.compact.down", action: .dismiss, units: units)
}

/// `\ / ` [ ] ' ; - =` — the run of symbol keys Row 0 carries in both modes, in the same
/// order in both, so none of them moves when the mode is toggled.
private func row0Symbols(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.shiftable("\\", "|", isShifted: shifted))
    r.append(.shiftable("/", "?", isShifted: shifted))
    r.append(.shiftable("`", "~", isShifted: shifted))
    r.append(.shiftable("[", "{", isShifted: shifted))
    r.append(.shiftable("]", "}", isShifted: shifted))
    r.append(.shiftable("'", "\"", isShifted: shifted))
    r.append(.shiftable(";", ":", isShifted: shifted))
    r.append(.shiftable("-", "_", isShifted: shifted))
    r.append(.shiftable("=", "+", isShifted: shifted))
    return r
}

// Row 0. Grouped by kind, in the order a hand looks for them:
//   normal:   ⇥ ← →       \ / ` [ ] ' ; - =    — 12 keys scaled to fill 10, no scrolling
//   terminal: Esc ⇥ ← ↓ ↑ → \ / ` [ ] ' ; - = hide Home End PgUp PgDn ⌦ F1…F12 — 33 units,
//             scrolled 10 at a time
//
// Portrait has more keys than it has columns in either mode. Normal mode is over by two
// and squeezes; terminal mode is over by twenty-three and scrolls. Either way it is
// confined to this row — the bottom row handed three of its slots to Ctrl, Term and Opt,
// and `\`, `/` and `` ` `` came up here so the modifier cluster could have their place.
// Terminal mode then costs nothing structural: same six rows, same ten columns, same key
// positions everywhere but here.
//
// The hide key is the one thing that changes rows with the mode: terminal mode needs the
// bottom-left slot for Control, so hide comes up here and sits after the symbols, where
// the first screen still reaches it. Normal mode has that slot free and keeps hide down
// there, in the corner, where putting the keyboard away does not cost a scroll.
func buildRow0Body(shifted: Bool, terminal: Bool = false) -> [KeyDef] {
    var r = [KeyDef]()
    if terminal {
        r.append(KeyDef(label: "Esc", action: .escape, units: 1.0))
    }
    r.append(KeyDef(label: "⇥", action: .tab, units: 1.0))
    r.append(KeyDef(label: "←", action: .cursorLeft, units: 1.0))
    if terminal {
        r.append(KeyDef(label: "↓", action: .cursorDown, units: 1.0))
        r.append(KeyDef(label: "↑", action: .cursorUp, units: 1.0))
    }
    r.append(KeyDef(label: "→", action: .cursorRight, units: 1.0))
    r.append(contentsOf: row0Symbols(shifted: shifted))
    guard terminal else {
        // Twelve keys shared across ten columns, rather than the last two pushed off the
        // right edge. Normal mode carries no Esc, no ↓ ↑, no hide and no function block,
        // so the row is only just too long — and giving up ~17% of each key's width is
        // worth every symbol being on screen from the start, with nothing to scroll for.
        // It also keeps this row off the scrolling path in normal mode, so its keys still
        // fire on press-down like the rest of the keyboard (see `KeyCap.scrollSafe`).
        let scale = portraitTotalCols / CGFloat(r.count)
        return r.map { var key = $0; key.units *= scale; return key }
    }
    r.append(hideKey())
    r.append(contentsOf: terminalNavigationKeys())
    r.append(contentsOf: terminalFunctionKeys())
    return r
}

// Row 1: numbers — 10 × 1.0 units
func buildRow1(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.shiftable("1", "!", isShifted: shifted))
    r.append(.shiftable("2", "@", isShifted: shifted))
    r.append(.shiftable("3", "#", isShifted: shifted))
    r.append(.shiftable("4", "$", isShifted: shifted))
    r.append(.shiftable("5", "%", isShifted: shifted))
    r.append(.shiftable("6", "^", isShifted: shifted))
    r.append(.shiftable("7", "&", isShifted: shifted))
    r.append(.shiftable("8", "*", isShifted: shifted))
    r.append(.shiftable("9", "(", isShifted: shifted))
    r.append(.shiftable("0", ")", isShifted: shifted))
    return r
}

// Row 2: QWERTY — 10 × 1.0 units, centered via padding
func buildRow2(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.letter("Q", shifted: shifted))
    r.append(.letter("W", shifted: shifted))
    r.append(.letter("E", shifted: shifted))
    r.append(.letter("R", shifted: shifted))
    r.append(.letter("T", shifted: shifted))
    r.append(.letter("Y", shifted: shifted))
    r.append(.letter("U", shifted: shifted))
    r.append(.letter("I", shifted: shifted))
    r.append(.letter("O", shifted: shifted))
    r.append(.letter("P", shifted: shifted))
    return r
}

// Row 3: ASDFGHJKL — 9 × 1.0 units, centered via 0.5-unit padding on each side
func buildRow3(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.letter("A", shifted: shifted))
    r.append(.letter("S", shifted: shifted))
    r.append(.letter("D", shifted: shifted))
    r.append(.letter("F", shifted: shifted))
    r.append(.letter("G", shifted: shifted))
    r.append(.letter("H", shifted: shifted))
    r.append(.letter("J", shifted: shifted))
    r.append(.letter("K", shifted: shifted))
    r.append(.letter("L", shifted: shifted))
    return r
}

// Row 4: Shift(1.5) + ZXCVBNM + Backspace(1.5) — 1.5+7+1.5 = 10 units
func buildRow4(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "⇧", action: .shift, units: 1.5))
    r.append(contentsOf: buildRow4Body(shifted: shifted))
    return r
}

// Row 4 body without the Shift key (used when Shift is rendered separately)
func buildRow4Body(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.letter("Z", shifted: shifted))
    r.append(.letter("X", shifted: shifted))
    r.append(.letter("C", shifted: shifted))
    r.append(.letter("V", shifted: shifted))
    r.append(.letter("B", shifted: shifted))
    r.append(.letter("N", shifted: shifted))
    r.append(.letter("M", shifted: shifted))
    r.append(KeyDef(label: "⌫", action: .backspace, units: 1.5))
    return r
}

// Row 5: 🌐(1) [hide|Ctrl](1) Term(1) [Opt(1)] + body — 10 units total
//   normal:   🌐(1) hide(1) Term(1) ␣(3.5) ,(1) .(1) ↵(1.5)
//   terminal: 🌐(1) Ctrl(1) Term(1) Opt(1) ␣(2.5) ,(1) .(1) ↵(1.5)
// The globe key is rendered separately as a native UIKit button, and is absent wherever
// the system supplies its own; Ctrl, Term, Opt and the hide key are rendered separately
// too. The second slot belongs to Control in terminal mode and to hide in normal mode,
// which keeps Term in the same column either way. Only the space bar changes width
// between the modes — `,`, `.` and ↵ start at the same column in both.
func buildRow5Body(shifted: Bool, spaceUnits: CGFloat) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "␣", action: .space, units: spaceUnits))
    r.append(.shiftable(",", "<", isShifted: shifted))
    r.append(.shiftable(".", ">", isShifted: shifted))
    // 1.5 rather than 2.0, with the half unit handed to the space bar: Return is a
    // once-per-line key and space is the most-pressed one on the keyboard.
    r.append(KeyDef(label: "↵", action: .enter, units: 1.5))
    return r
}
// MARK: - Landscape Row Data
// Layout: 5 rows, Mac-like, 14.5 total columns in both modes.
// unitWidth = (totalWidth - (totalCols - 1) * gap) / totalCols
//
// Terminal mode adds keys but never columns: whatever it introduces is paid for out of
// the row it lands on, so the unit grid — and with it the letter columns and every key
// width — is identical in both modes. That alignment is the whole point of this layout;
// it exists so a Mac typist's muscle memory transfers, and so toggling the mode does not
// move the keys under your fingers.
let landscapeTotalCols: CGFloat = 14.5

// Landscape Row 0: `(1) 1 2 3 4 5 6 7 8 9 0 -(1) =(1) ⌫(1.5) — 14.5 units, fits exactly
//        terminal: Esc first, then all of the above, then Home End PgUp PgDn ⌦ and
//        F1…F12 — 32.5 units scaled to 30.4, which the row scrolls through 14.5 at a time
//        and which opens on exactly the number row (see the scaling note below).
// Scrolling is what makes room for the function and navigation keys a phone has nowhere
// else to put. The rows below are untouched either way, so the letter block never moves.
func buildLandscapeRow0(shifted: Bool, terminal: Bool = false) -> [KeyDef] {
    var r = [KeyDef]()
    if terminal {
        r.append(KeyDef(label: "Esc", action: .escape, units: 1.0))
    }
    r.append(.shiftable("`", "~", isShifted: shifted))
    r.append(.shiftable("1", "!", isShifted: shifted))
    r.append(.shiftable("2", "@", isShifted: shifted))
    r.append(.shiftable("3", "#", isShifted: shifted))
    r.append(.shiftable("4", "$", isShifted: shifted))
    r.append(.shiftable("5", "%", isShifted: shifted))
    r.append(.shiftable("6", "^", isShifted: shifted))
    r.append(.shiftable("7", "&", isShifted: shifted))
    r.append(.shiftable("8", "*", isShifted: shifted))
    r.append(.shiftable("9", "(", isShifted: shifted))
    r.append(.shiftable("0", ")", isShifted: shifted))
    r.append(.shiftable("-", "_", isShifted: shifted))
    r.append(.shiftable("=", "+", isShifted: shifted))
    r.append(KeyDef(label: "⌫", action: .backspace, units: 1.5))
    guard terminal else { return r }
    r.append(contentsOf: terminalNavigationKeys())
    r.append(contentsOf: terminalFunctionKeys())
    // Esc through ⌫ is 15.5 units, exactly one more than the row is wide, so left alone
    // the row opens on a ⌫ straddling the right edge. Scaling every key by 14.5/15.5
    // settles ⌫ just inside it, which makes the first screen the whole number row and
    // nothing else — scroll only when you actually want what comes after it. The tail is
    // scaled too, so a key that scrolls into view is the same size as the ones already there.
    let scale = landscapeTotalCols / (landscapeTotalCols + 1.0)
    return r.map { var key = $0; key.units *= scale; return key }
}

// Landscape Row 1: ⇥(1.5) Q W E R T Y U I O P [(1) ](1) \(1) — 14.5 units, both modes.
func buildLandscapeRow1(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "⇥", action: .tab, units: 1.5))
    r.append(.letter("Q", shifted: shifted))
    r.append(.letter("W", shifted: shifted))
    r.append(.letter("E", shifted: shifted))
    r.append(.letter("R", shifted: shifted))
    r.append(.letter("T", shifted: shifted))
    r.append(.letter("Y", shifted: shifted))
    r.append(.letter("U", shifted: shifted))
    r.append(.letter("I", shifted: shifted))
    r.append(.letter("O", shifted: shifted))
    r.append(.letter("P", shifted: shifted))
    r.append(.shiftable("[", "{", isShifted: shifted))
    r.append(.shiftable("]", "}", isShifted: shifted))
    r.append(.shiftable("\\", "|", isShifted: shifted))
    return r
}

// Landscape Row 2: ⇪(2) A S D F G H J K L ;(1) '(1) ↵(1.5) — 14.5 units, both modes.
// The caps lock key is rendered separately, so this returns the body only.
func buildLandscapeRow2Body(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.letter("A", shifted: shifted))
    r.append(.letter("S", shifted: shifted))
    r.append(.letter("D", shifted: shifted))
    r.append(.letter("F", shifted: shifted))
    r.append(.letter("G", shifted: shifted))
    r.append(.letter("H", shifted: shifted))
    r.append(.letter("J", shifted: shifted))
    r.append(.letter("K", shifted: shifted))
    r.append(.letter("L", shifted: shifted))
    r.append(.shiftable(";", ":", isShifted: shifted))
    r.append(.shiftable("'", "\"", isShifted: shifted))
    r.append(KeyDef(label: "↵", action: .enter, units: 1.5))
    return r
}

// Landscape Row 3: ⇧(2.25) Z X C V B N M ,(1) .(1) /(1) ⇧(2.25) — 14.5 units
//        terminal: ⇧(2.25) … /(1) ↑(1) ⇧(1.25) — 14.5 units
// The right Shift gives up a unit to ↑ so the arrows can sit in the corner as the inverted
// T a full-size keyboard has, with ↑ over the bottom row's ← ↓ → rather than inline with
// them. The shift keys are rendered separately, so this returns the body only.
func buildLandscapeRow3Body(shifted: Bool, terminal: Bool = false) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.letter("Z", shifted: shifted))
    r.append(.letter("X", shifted: shifted))
    r.append(.letter("C", shifted: shifted))
    r.append(.letter("V", shifted: shifted))
    r.append(.letter("B", shifted: shifted))
    r.append(.letter("N", shifted: shifted))
    r.append(.letter("M", shifted: shifted))
    r.append(.shiftable(",", "<", isShifted: shifted))
    r.append(.shiftable(".", ">", isShifted: shifted))
    r.append(.shiftable("/", "?", isShifted: shifted))
    if terminal {
        r.append(KeyDef(label: "↑", action: .cursorUp, units: 1.0))
    }
    return r
}

// Landscape Row 4: 🌐(1) ·(1.5) Term(1.5) ␣(7) ←(1) →(1) hide(1.5) — 14.5 units
//        terminal: 🌐(1) Ctrl(1.5) Term(1.5) Opt(1) ␣(4.75) hide(1.5) ←(1) ↓(1) →(1) — 14.25
// The globe key is rendered separately as a native UIKit button and is absent wherever
// the system supplies its own; Term, Ctrl and Opt are stateful caps rendered separately
// too. `·` is the empty slot normal mode holds open where Control would be, so that Term
// keeps its position in both. `spaceUnits` absorbs whatever the lot comes to: 7.0/8.0
// normally, 4.75/5.75 in terminal mode, with and without the globe key.
//
// In terminal mode the hide key steps aside so ← ↓ → can have the bottom-right corner
// outright, under the ↑ that Row 3 gives up a unit of right Shift for. This is the one
// row that does not add up to 14.5: it stops a quarter unit short so that ↓ lands under
// that ↑ — see `landscapeSpaceUnits` for why the column cannot be met from Row 3's side.
// Normal mode has no ↑ to pair the arrows with, so they stay inline and the row is full.
func buildLandscapeRow4Body(shifted: Bool, spaceUnits: CGFloat = 8.0, terminal: Bool = false) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "␣", action: .space, units: spaceUnits))
    let hide = hideKey(units: 1.5)
    if terminal {
        // Home and End are not here — they are real keys on the scrolling first row now,
        // rather than shifted faces of these two.
        r.append(hide)
        r.append(KeyDef(label: "←", action: .cursorLeft, units: 1.0))
        r.append(KeyDef(label: "↓", action: .cursorDown, units: 1.0))
        r.append(KeyDef(label: "→", action: .cursorRight, units: 1.0))
    } else {
        r.append(KeyDef(label: "←", action: .cursorLeft, units: 1.0))
        r.append(KeyDef(label: "→", action: .cursorRight, units: 1.0))
        r.append(hide)
    }
    return r
}
