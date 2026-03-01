import Foundation

// MARK: - Row Data
// Each function returns a row of KeyDef values.
// Functions are internal (not private) so CodingKeyboardView can call them.

func buildRow1() -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.char("1")); r.append(.char("2")); r.append(.char("3"))
    r.append(.char("4")); r.append(.char("5")); r.append(.char("6"))
    r.append(.char("7")); r.append(.char("8")); r.append(.char("9"))
    r.append(.char("0"))
    r.append(KeyDef(label: "⌫", action: .backspace))
    return r  // 11 × 1.0 units
}

func buildRow2(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.letter("Q", shifted: shifted)); r.append(.letter("W", shifted: shifted))
    r.append(.letter("E", shifted: shifted)); r.append(.letter("R", shifted: shifted))
    r.append(.letter("T", shifted: shifted)); r.append(.letter("Y", shifted: shifted))
    r.append(.letter("U", shifted: shifted)); r.append(.letter("I", shifted: shifted))
    r.append(.letter("O", shifted: shifted)); r.append(.letter("P", shifted: shifted))
    return r  // 10 × 1.0 units — centered via padding
}

func buildRow3(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(KeyDef(label: "tab", action: .character("\t")))
    r.append(.letter("A", shifted: shifted)); r.append(.letter("S", shifted: shifted))
    r.append(.letter("D", shifted: shifted)); r.append(.letter("F", shifted: shifted))
    r.append(.letter("G", shifted: shifted)); r.append(.letter("H", shifted: shifted))
    r.append(.letter("J", shifted: shifted)); r.append(.letter("K", shifted: shifted))
    r.append(.letter("L", shifted: shifted))
    r.append(KeyDef(label: "↵", action: .enter))
    return r  // 11 × 1.0 units
}

func buildRow4(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    // Shift is 1.5 units; remaining 9 keys are 1.0 unit each.
    // Total = 1.5 + 9 = 10.5 units — centered via 0.25-unit padding on each side.
    r.append(KeyDef(label: "⇧", action: .shift, units: 1.5))
    r.append(.letter("Z", shifted: shifted)); r.append(.letter("X", shifted: shifted))
    r.append(.letter("C", shifted: shifted)); r.append(.letter("V", shifted: shifted))
    r.append(.letter("B", shifted: shifted)); r.append(.letter("N", shifted: shifted))
    r.append(.letter("M", shifted: shifted))
    r.append(.char(",")); r.append(.char("."))
    return r
}

func buildRow5() -> [KeyDef] {
    var r = [KeyDef]()
    // 9 × 1.0 + 1 × 2.0 = 11.0 units — fills the full row
    r.append(.char("[")); r.append(.char("]"))
    r.append(.char("-")); r.append(.char("+"))
    r.append(KeyDef(label: "space", action: .space, units: 2.0))
    r.append(.char(";")); r.append(.char("'"))
    r.append(.char("/")); r.append(.char("\\"))
    r.append(.char("`"))
    return r
}
