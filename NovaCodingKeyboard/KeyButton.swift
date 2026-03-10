import SwiftUI

// MARK: - KeyButton
// Bridges KeyDef → KeyCap. Computes pixel width from unit grid.

struct KeyButton: View {
    let key: KeyDef
    let unitWidth: CGFloat
    let keyHeight: CGFloat
    let gap: CGFloat
    let onTap: @MainActor (KeyAction) -> Void

    var keyCapWidth: CGFloat {
        unitWidth * key.units + gap * (key.units - 1)
    }

    var style: KeyCapStyle {
        switch key.action {
        case .backspace, .enter, .shift, .tab, .cursorLeft, .cursorRight, .dismiss, .nextKeyboard: return .modifier
        case .space:                     return .space
        default:                         return .normal
        }
    }

    var rowSpacing: CGFloat = 0

    private var hitInsets: EdgeInsets {
        EdgeInsets(top: rowSpacing / 2, leading: gap / 2, bottom: rowSpacing / 2, trailing: gap / 2)
    }

    var body: some View {
        KeyCap(
            label: key.label,
            style: style,
            width: keyCapWidth,
            height: keyHeight,
            action: { onTap(key.action) },
            normalLabel: key.normalLabel,
            shiftedLabel: key.shiftedLabel,
            isShifted: key.isShifted,
            hitPadding: hitInsets
        )
    }
}

// MARK: - KeyboardRow

struct KeyboardRow: View {
    let keys: [KeyDef]
    let unitWidth: CGFloat
    let keyHeight: CGFloat
    let gap: CGFloat
    let onTap: @MainActor (KeyAction) -> Void
    var rowSpacing: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            ForEach(keys.indices, id: \.self) { i in
                KeyButton(
                    key: keys[i],
                    unitWidth: unitWidth,
                    keyHeight: keyHeight,
                    gap: gap,
                    onTap: onTap,
                    rowSpacing: rowSpacing
                )
            }
        }
    }
}
