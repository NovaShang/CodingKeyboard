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
        case .backspace, .enter, .shift, .control, .option, .tab, .escape,
             .cursorLeft, .cursorRight, .cursorUp, .cursorDown,
             .home, .end, .pageUp, .pageDown, .forwardDelete, .function,
             .dismiss, .nextKeyboard, .toggleTerminalMode:
            return .modifier
        case .space:
            return .space
        case .character:
            return .normal
        }
    }

    var rowSpacing: CGFloat = 0
    /// Extra hit area on the outer edges, used by the first and last key of a centred
    /// row so the centring inset is live rather than dead space.
    var extraLeadingHit: CGFloat = 0
    var extraTrailingHit: CGFloat = 0
    /// Forwarded to `KeyCap` — see the note there. Set for the portrait terminal row.
    var scrollSafe: Bool = false

    private var hitInsets: EdgeInsets {
        EdgeInsets(
            top: rowSpacing / 2,
            leading: gap / 2 + extraLeadingHit,
            bottom: rowSpacing / 2,
            trailing: gap / 2 + extraTrailingHit
        )
    }

    /// Only deletion and cursor movement repeat while held, matching the system
    /// keyboard. Repeating character keys would turn a brief pause into duplicates.
    ///
    /// A key with a long-press action is excluded whatever it does: holding it is how you
    /// reach that action, so repeat would fire the primary one all the way there.
    private var repeatsOnHold: Bool {
        guard key.longPressAction == nil else { return false }
        switch key.action {
        case .backspace, .forwardDelete, .pageUp, .pageDown,
             .cursorLeft, .cursorRight, .cursorUp, .cursorDown: return true
        default:                                               return false
        }
    }

    /// Most keys read fine as their own label, but the symbol-only modifier keys do not.
    private var voiceOverLabel: String? {
        switch key.action {
        case .backspace:   return "Delete"
        case .enter:       return "Return"
        case .tab:         return "Tab"
        case .space:       return "Space"
        case .escape:      return "Escape"
        case .cursorLeft:  return "Move left"
        case .cursorRight: return "Move right"
        case .cursorUp:    return "Move up"
        case .cursorDown:  return "Move down"
        case .home:        return "Home"
        case .end:         return "End"
        case .pageUp:      return "Page up"
        case .pageDown:    return "Page down"
        case .forwardDelete: return "Forward delete"
        case .function(let n): return "F\(n)"
        case .dismiss:     return "Dismiss keyboard"
        case .shift:       return "Shift"
        case .control:     return "Control"
        case .option:      return "Option"
        case .nextKeyboard: return "Next keyboard"
        case .toggleTerminalMode: return "Terminal mode"
        case .character:   return nil
        }
    }

    /// Built here rather than inline as `longPressAction.map { … }`: the closure has to
    /// be written as a literal in a position already typed `@MainActor () -> Void` to
    /// pick up the @Sendable inference KeyCap expects. Nested inside `map`'s closure it
    /// does not, and the conversion warns. Same reason as the `onTap` note below.
    private var longPressHandler: (@MainActor () -> Void)? {
        guard let longPressAction = key.longPressAction else { return nil }
        return { onTap(longPressAction) }
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
            voiceOverLabel: voiceOverLabel,
            onLongPress: longPressHandler,
            scrollSafe: scrollSafe
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
    /// Hit area handed to the outer edge of the first and last key. A centred row (the
    /// ASDFGHJKL row) is inset by half a key at each end; without this that inset is
    /// dead space, where the system keyboard lets the edge keys claim it.
    var edgeHitPadding: CGFloat = 0
    /// Forwarded to every key in the row — see the note on `KeyCap.scrollSafe`.
    var scrollSafe: Bool = false

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
                    rowSpacing: rowSpacing,
                    extraLeadingHit: i == keys.indices.first ? edgeHitPadding : 0,
                    extraTrailingHit: i == keys.indices.last ? edgeHitPadding : 0,
                    scrollSafe: scrollSafe
                )
            }
        }
    }
}
