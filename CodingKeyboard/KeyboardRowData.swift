import Foundation

// MARK: - Portrait Row Data
// Layout: 10 columns, 6 rows
// unitWidth = (totalWidth - 9 * gap) / 10

// Row 0: ⇥(1) ←(1) →(1) [ ] ' ; - = hide(1) — 10 units
func buildRow0(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "⇥", action: .tab, units: 1.0))
    r.append(KeyDef(label: "←", action: .cursorLeft, units: 1.0))
    r.append(KeyDef(label: "→", action: .cursorRight, units: 1.0))
    r.append(.shiftable("[", "{", isShifted: shifted))
    r.append(.shiftable("]", "}", isShifted: shifted))
    r.append(.shiftable("'", "\"", isShifted: shifted))
    r.append(.shiftable(";", ":", isShifted: shifted))
    r.append(.shiftable("-", "_", isShifted: shifted))
    r.append(.shiftable("=", "+", isShifted: shifted))
    r.append(KeyDef(label: "sf:keyboard.chevron.compact.down", action: .dismiss, units: 1.0))
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

// Row 5: 🌐(1) + body(9)  — 10 units total
// The globe key is rendered separately as a native UIKit button, and is absent wherever
// the system supplies its own. `spaceUnits` absorbs the difference: 2.0 with the globe
// key present, 3.0 without it, so the row always totals 10 units.
func buildRow5Body(shifted: Bool, spaceUnits: CGFloat = 2.0) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.shiftable("\\", "|", isShifted: shifted))
    r.append(.shiftable("/", "?", isShifted: shifted))
    r.append(.shiftable("`", "~", isShifted: shifted))
    r.append(KeyDef(label: "␣", action: .space, units: spaceUnits))
    r.append(.shiftable(",", "<", isShifted: shifted))
    r.append(.shiftable(".", ">", isShifted: shifted))
    r.append(KeyDef(label: "↵", action: .enter, units: 2.0))
    return r
}
// MARK: - Landscape Row Data
// Layout: 5 rows, Mac-like, 14.5 total columns
// unitWidth = (totalWidth - (totalCols - 1) * gap) / totalCols
let landscapeTotalCols: CGFloat = 14.5

// Landscape Row 0: `(1) 1 2 3 4 5 6 7 8 9 0 -(1) =(1) ⌫(1.5) — 14.5 units
func buildLandscapeRow0(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
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
    return r
}

// Landscape Row 1: ⇥(1.5) Q W E R T Y U I O P [(1) ](1) \(1) — 14.5 units
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

// Landscape Row 2: ⇪(2) A S D F G H J K L ;(1) '(1) ↵(1.5) — 14.5 units
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
// The shift keys are rendered separately, so this returns the body only.
func buildLandscapeRow3Body(shifted: Bool) -> [KeyDef] {
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
    return r
}

// Landscape Row 4: 🌐(1.5) hide(1.5) ␣(8) ←(1) →(1) hide(1.5) — 14.5 units
// The globe key is rendered separately as a native UIKit button, and is absent wherever
// the system supplies its own. `spaceUnits` absorbs the difference: 8.0 with the globe
// key present, 9.5 without it, so the row always totals 14.5 units.
func buildLandscapeRow4Body(shifted: Bool, spaceUnits: CGFloat = 8.0) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "sf:keyboard.chevron.compact.down", action: .dismiss, units: 1.5))
    r.append(KeyDef(label: "␣", action: .space, units: spaceUnits))
    r.append(KeyDef(label: "←", action: .cursorLeft, units: 1.0))
    r.append(KeyDef(label: "→", action: .cursorRight, units: 1.0))
    r.append(KeyDef(label: "sf:keyboard.chevron.compact.down", action: .dismiss, units: 1.5))
    return r
}

