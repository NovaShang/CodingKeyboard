import Foundation
import CoreGraphics

// MARK: - KeyAction

enum KeyAction {
    case character(String)
    case backspace
    case shift
    case enter
    case space
}

// MARK: - KeyDef

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

    /// A key that shows its unshifted character normally and its shifted character when Shift is active.
    static func shiftable(_ normal: String, _ shiftedChar: String, isShifted: Bool) -> KeyDef {
        let ch = isShifted ? shiftedChar : normal
        return KeyDef(label: ch, action: .character(ch))
    }

    static func char(_ s: String) -> KeyDef {
        KeyDef(label: s, action: .character(s))
    }
}
