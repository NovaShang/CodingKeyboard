import SwiftUI

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

#Preview {
    CodingKeyboardView(text: .constant(""))
        .safeAreaPadding(.bottom, 34)
}
