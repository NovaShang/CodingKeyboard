import SwiftUI

struct CodingKeyboardView: View {
    /// Called whenever a key is tapped. The caller decides what to do with the action.
    let onAction: @MainActor (KeyAction) -> Void

    @State private var isShifted = false

    private let keyHeight: CGFloat = 44
    private let gap: CGFloat = 6
    private let totalCols: CGFloat = 10
    private let rowSpacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let unitWidth = (totalWidth - (totalCols - 1) * gap) / totalCols
            let halfUnit = (unitWidth + gap) / 2  // 0.5-unit indent for centering 9-key rows

            VStack(alignment: .leading, spacing: rowSpacing) {
                // Row 0: ⇥(2x) [ ] \ ` / ' ⌨ — 9 units, right-aligned (1-unit gap on left)
                let row0LeadPad = unitWidth + gap
                KeyboardRow(keys: buildRow0(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                // Row 1: numbers (10 keys, full width)
                KeyboardRow(keys: buildRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                // Row 2: QWERTY (10 keys, full width)
                KeyboardRow(keys: buildRow2(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                // Row 3: ASDFGHJKL (9 keys, centered with 0.5-unit padding each side)
                KeyboardRow(keys: buildRow3(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                    .padding(.horizontal, halfUnit)
                // Row 4: Shift(1.5) + ZXCVBNM + Backspace(1.5) (10 units, full width)
                KeyboardRow(keys: buildRow4(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                // Row 5: , . - = Space(2x) ; ' / Enter (10 units, full width)
                KeyboardRow(keys: buildRow5(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
            }
            .padding(.top, 8)
        }
        .frame(height: keyHeight * 6 + rowSpacing * 5 + 8)
    }

    private func handle(_ action: KeyAction) {
        if case .shift = action {
            isShifted.toggle()
        } else {
            if isShifted { isShifted = false }
        }
        onAction(action)
    }
}

#Preview {
    CodingKeyboardView(onAction: { _ in })
        .background(alignment: .bottom) {
            Color(UIColor.systemGray6).ignoresSafeArea(edges: .bottom)
        }
        .safeAreaPadding(.bottom, 34)
}
