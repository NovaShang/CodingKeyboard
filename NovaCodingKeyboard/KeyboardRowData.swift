import Foundation

// MARK: - Row Data

func buildRow1(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    // Standard US keyboard: shift+number = symbol
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
    r.append(.shiftable(",", "<", isShifted: shifted))
    r.append(.shiftable(".", ">", isShifted: shifted))
    return r
}

func buildRow5(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    // 9 × 1.0 + 1 × 2.0 = 11.0 units — fills the full row
    r.append(.shiftable("[", "{", isShifted: shifted))
    r.append(.shiftable("]", "}", isShifted: shifted))
    r.append(.shiftable("-", "_", isShifted: shifted))
    r.append(.shiftable("=", "+", isShifted: shifted))
    r.append(KeyDef(label: "space", action: .space, units: 2.0))
    r.append(.shiftable(";", ":", isShifted: shifted))
    r.append(.shiftable("'", "\"", isShifted: shifted))
    r.append(.shiftable("/", "?", isShifted: shifted))
    r.append(.shiftable("\\", "|", isShifted: shifted))
    r.append(.shiftable("`", "~", isShifted: shifted))
    return r
}
