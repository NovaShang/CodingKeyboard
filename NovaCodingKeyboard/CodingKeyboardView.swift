import SwiftUI

struct CodingKeyboardView: View {
    /// Called whenever a key is tapped. The caller decides what to do with the action.
    let onAction: @MainActor (KeyAction) -> Void

    @State private var isShifted = false

    private let keyHeight: CGFloat = 44
    private let gap: CGFloat = 6
    private let totalCols: CGFloat = 11
    private let rowSpacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let unitWidth = (totalWidth - (totalCols - 1) * gap) / totalCols
            let halfUnit = (unitWidth + gap) / 2

            VStack(alignment: .leading, spacing: rowSpacing) {
                KeyboardRow(keys: buildRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                KeyboardRow(keys: buildRow2(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                    .padding(.leading, halfUnit)
                KeyboardRow(keys: buildRow3(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                KeyboardRow(keys: buildRow4(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                    .padding(.leading, (unitWidth + gap) * 0.25)
                KeyboardRow(keys: buildRow5(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
            }
            .padding(.top, 8)
        }
        .frame(height: keyHeight * 5 + rowSpacing * 4 + 8)
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
