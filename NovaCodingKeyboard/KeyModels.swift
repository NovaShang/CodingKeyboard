import Foundation
import CoreGraphics

// MARK: - ShiftState

enum ShiftState {
    case off
    case on        // single tap: resets after next character key
    case momentary // long press held: resets on finger lift, not on character key
    case locked    // double tap: stays until shift is pressed again

    var isActive: Bool { self != .off }
}

// MARK: - KeyAction

enum KeyAction {
    case character(String)
    case backspace
    case shift
    case tab
    case enter
    case space
    case cursorLeft
    case cursorRight
    case dismiss
    case nextKeyboard
}

// MARK: - KeyDef

struct KeyDef {
    let label: String
    let action: KeyAction
    /// Width in standard key units (1.0 = one standard key)
    var units: CGFloat
    /// The unshifted label, shown in the lower/primary position (nil for non-shiftable keys)
    let normalLabel: String?
    /// The shifted label, shown in the upper/secondary position (nil for non-shiftable keys)
    let shiftedLabel: String?
    /// Whether the key is currently in shifted state (affects which label is primary)
    let isShifted: Bool

    init(label: String, action: KeyAction, units: CGFloat = 1.0,
         normalLabel: String? = nil, shiftedLabel: String? = nil, isShifted: Bool = false) {
        self.label = label
        self.action = action
        self.units = units
        self.normalLabel = normalLabel
        self.shiftedLabel = shiftedLabel
        self.isShifted = isShifted
    }

    static func letter(_ upper: String, shifted: Bool) -> KeyDef {
        let ch = shifted ? upper : upper.lowercased()
        return KeyDef(label: ch, action: .character(ch))
    }

    /// A key that displays both its normal and shifted labels, with styling based on current shift state.
    static func shiftable(_ normal: String, _ shiftedChar: String, isShifted: Bool) -> KeyDef {
        let ch = isShifted ? shiftedChar : normal
        return KeyDef(label: ch, action: .character(ch),
                      normalLabel: normal, shiftedLabel: shiftedChar, isShifted: isShifted)
    }

    static func char(_ s: String) -> KeyDef {
        KeyDef(label: s, action: .character(s))
    }
}
