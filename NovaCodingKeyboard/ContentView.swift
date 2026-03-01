import SwiftUI

// MARK: - Key Model

enum KeyAction {
    case character(String)
    case backspace
    case shift
    case enter
    case space
}

struct KeyDef {
    let label: String
    let action: KeyAction
    /// Width in standard key units (1.0 = one standard key)
    var units: CGFloat

    init(label: String, action: KeyAction, units: CGFloat = 1.0) {
        self.label = label
        self.action = action
        self.units = units
    }

    static func letter(_ upper: String, shifted: Bool) -> KeyDef {
        let ch = shifted ? upper : upper.lowercased()
        return KeyDef(label: ch, action: .character(ch))
    }

    static func char(_ s: String) -> KeyDef {
        KeyDef(label: s, action: .character(s))
    }
}

// MARK: - Key Button
// unitWidth: pixel width of one standard key unit (gap already excluded)
// keyHeight: pixel height of the key cap area
// gap: horizontal gap between keys

struct KeyButton: View {
    let key: KeyDef
    let unitWidth: CGFloat
    let keyHeight: CGFloat
    let gap: CGFloat
    let onTap: (KeyAction) -> Void

    var keyCapWidth: CGFloat {
        unitWidth * key.units + gap * (key.units - 1)
    }

    var body: some View {
        Button {
            onTap(key.action)
        } label: {
            Text(key.label)
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(bgColor)
                        .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 1)
                )
                .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
        .frame(width: keyCapWidth, height: keyHeight)
    }

    var bgColor: Color {
        switch key.action {
        case .backspace, .enter, .shift:
            return Color(UIColor.systemGray3)
        default:
            return Color(UIColor.systemBackground)
        }
    }
}

// MARK: - Keyboard Row

struct KeyboardRow: View {
    let keys: [KeyDef]
    let unitWidth: CGFloat
    let keyHeight: CGFloat
    let gap: CGFloat
    let onTap: (KeyAction) -> Void

    var body: some View {
        HStack(spacing: gap) {
            ForEach(keys.indices, id: \.self) { i in
                KeyButton(
                    key: keys[i],
                    unitWidth: unitWidth,
                    keyHeight: keyHeight,
                    gap: gap,
                    onTap: onTap
                )
            }
        }
    }
}

// MARK: - Row Data

private func buildRow1() -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.char("1")); r.append(.char("2")); r.append(.char("3"))
    r.append(.char("4")); r.append(.char("5")); r.append(.char("6"))
    r.append(.char("7")); r.append(.char("8")); r.append(.char("9"))
    r.append(.char("0"))
    r.append(KeyDef(label: "⌫", action: .backspace))
    return r  // 11 × 1.0 units
}

private func buildRow2(shifted: Bool) -> [KeyDef] {
    var r = [KeyDef]()
    r.append(.letter("Q", shifted: shifted)); r.append(.letter("W", shifted: shifted))
    r.append(.letter("E", shifted: shifted)); r.append(.letter("R", shifted: shifted))
    r.append(.letter("T", shifted: shifted)); r.append(.letter("Y", shifted: shifted))
    r.append(.letter("U", shifted: shifted)); r.append(.letter("I", shifted: shifted))
    r.append(.letter("O", shifted: shifted)); r.append(.letter("P", shifted: shifted))
    return r  // 10 × 1.0 units — centered via padding
}

private func buildRow3(shifted: Bool) -> [KeyDef] {
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

private func buildRow4(shifted: Bool) -> [KeyDef] {
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

private func buildRow5() -> [KeyDef] {
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

// MARK: - Coding Keyboard View

struct CodingKeyboardView: View {
    @Binding var text: String
    @State private var isShifted = false

    private let keyHeight: CGFloat = 44
    private let gap: CGFloat = 6
    /// Number of standard key columns the keyboard is laid out on
    private let totalCols: CGFloat = 11
    private let rowSpacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let unitWidth = (totalWidth - (totalCols - 1) * gap) / totalCols
            let halfUnit = (unitWidth + gap) / 2

            VStack(alignment: .leading, spacing: rowSpacing) {
                KeyboardRow(keys: buildRow1(), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                KeyboardRow(keys: buildRow2(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                    .padding(.leading, halfUnit)
                KeyboardRow(keys: buildRow3(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                KeyboardRow(keys: buildRow4(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                    .padding(.leading, (unitWidth + gap) * 0.25)
                KeyboardRow(keys: buildRow5(), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
            }
            .padding(.top, 8)
        }
        .frame(height: keyHeight * 5 + rowSpacing * 4 + 8)
        .background(Color(UIColor.systemGray5))
    }

    func handle(_ action: KeyAction) {
        switch action {
        case .character(let c):
            text.append(c)
            if isShifted { isShifted = false }
        case .backspace:
            if !text.isEmpty { text.removeLast() }
        case .enter:
            text.append("\n")
        case .space:
            text.append(" ")
        case .shift:
            isShifted.toggle()
        }
    }
}

// MARK: - Preview Container

struct ContentView: View {
    @State private var typedText = ""

    var body: some View {
        ScrollView {
            Text(typedText.isEmpty ? "Start typing..." : typedText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(typedText.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CodingKeyboardView(text: $typedText)
                .background(alignment: .bottom) {
                    // Extends the keyboard background colour into the home indicator area
                    Color(UIColor.systemGray5)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
    }
}

#Preview {
    ContentView()
        .safeAreaPadding(.bottom, 34)
}
