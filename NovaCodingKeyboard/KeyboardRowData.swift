import Foundation

// MARK: - Row Data
// Layout: 10 columns, 6 rows
// unitWidth = (totalWidth - 9 * gap) / 10

// Row 0: ⇥(1.5) [ ] ' ; - = ☰(1.0) ↓(1.5) — 10 units
func buildRow0(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "⇥", action: .tab, units: 1.5))
    r.append(.shiftable("[", "{", isShifted: shifted))
    r.append(.shiftable("]", "}", isShifted: shifted))
    r.append(.shiftable("'", "\"", isShifted: shifted))
    r.append(.shiftable(";", ":", isShifted: shifted))
    r.append(.shiftable("-", "_", isShifted: shifted))
    r.append(.shiftable("=", "+", isShifted: shifted))
    r.append(KeyDef(label: "☰", action: .openApp, units: 1.0))
    r.append(KeyDef(label: "↓", action: .dismiss, units: 1.5))
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

// Row 5: \ / `(1.0) ␣(3.0) , . ↵(2.0) — 2+1+3+2+2 = 10 units
func buildRow5(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.shiftable("\\", "|", isShifted: shifted))
    r.append(.shiftable("/", "?", isShifted: shifted))
    r.append(.shiftable("`", "~", isShifted: shifted))
    r.append(KeyDef(label: "␣", action: .space, units: 3.0))
    r.append(.shiftable(",", "<", isShifted: shifted))
    r.append(.shiftable(".", ">", isShifted: shifted))
    r.append(KeyDef(label: "↵", action: .enter, units: 2.0))
    return r
}
