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

    /// Only deletion and cursor movement repeat while held, matching the system
    /// keyboard. Repeating character keys would turn a brief pause into duplicates.
    private var repeatsOnHold: Bool {
        switch key.action {
        case .backspace, .cursorLeft, .cursorRight: return true
        default:                                    return false
        }
    }

    /// Most keys read fine as their own label, but the symbol-only modifier keys do not.
    private var voiceOverLabel: String? {
        switch key.action {
        case .backspace:   return "Delete"
        case .enter:       return "Return"
        case .tab:         return "Tab"
        case .space:       return "Space"
        case .cursorLeft:  return "Move left"
        case .cursorRight: return "Move right"
        case .dismiss:     return "Dismiss keyboard"
        case .shift:       return "Shift"
        case .nextKeyboard: return "Next keyboard"
        case .character:   return nil
        }
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
            hitPadding: hitInsets,
            repeatsOnHold: repeatsOnHold,
            voiceOverLabel: voiceOverLabel
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
                    // Forwarded through a closure literal rather than passing
                    // `onTap` directly: the literal picks up the @Sendable
                    // inference KeyButton's initializer expects, which a bare
                    // property reference does not.
                    onTap: { onTap($0) },
                    rowSpacing: rowSpacing
                )
            }
        }
    }
}
