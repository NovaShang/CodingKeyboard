import Foundation
import CoreGraphics

// MARK: - ShiftState

/// The latch state of a sticky modifier. Named for Shift because Shift had it first,
/// but Control and Option in terminal mode run on exactly the same four states.
enum ShiftState {
    case off
    case on        // single tap: resets after next character key
    case momentary // long press held: resets on finger lift, not on character key
    case locked    // double tap: stays until the key is pressed again

    var isActive: Bool { self != .off }
}

// MARK: - ModifierLatch

/// The press/release state machine behind Shift, Control and Option.
///
/// Extracted out of the view once a second and third key needed it: three hand-kept
/// copies of this bookkeeping would have drifted apart within a release. The rules are
/// the ones Shift already had — the modifier engages the instant the finger lands, never
/// on lift and never after a delay, so holding it with one thumb and typing with the
/// other works from the very first keystroke. What the press *meant* (a one-shot tap, a
/// held modifier, or a lock) is resolved on release instead.
struct ModifierLatch {
    /// The haptic the caller should play. Returned rather than played here so this type
    /// stays free of UIKit — and so the logic can be reasoned about on its own.
    enum Feedback {
        case light
        case medium
    }

    private(set) var state: ShiftState = .off
    /// True while a finger rests on the key.
    private(set) var isHeld = false

    /// Finger-lift time of the previous press, used to spot a double tap on the next
    /// press-down.
    private var lastReleaseTime: Date = .distantPast
    /// Set when press-down already resolved the press as a double tap, so the matching
    /// lift leaves the lock alone.
    private var pressWasDoubleTap = false
    /// When the current press began, used to tell a tap from a deliberate hold.
    private var pressTime: Date = .distantPast
    /// The state before the current press, used to resolve a tap into a toggle.
    private var stateBeforePress: ShiftState = .off
    /// Whether any key was pressed while this modifier was held down.
    private var didTypeWhileHeld = false

    private static let doubleTapWindow: TimeInterval = 0.3
    /// Above this, a press with nothing typed reads as an abandoned hold rather than a
    /// tap. Shared with the long-press keys so every "held on purpose" gesture on this
    /// keyboard agrees on what counts as long.
    static let holdThreshold: TimeInterval = 0.5

    var isActive: Bool { state.isActive }

    mutating func pressDown(now: Date = Date()) -> Feedback? {
        let timeSinceRelease = now.timeIntervalSince(lastReleaseTime)
        stateBeforePress = state
        pressTime = now
        didTypeWhileHeld = false
        isHeld = true

        if timeSinceRelease < Self.doubleTapWindow && state == .on {
            // Second tap quickly after the first → lock
            state = .locked
            pressWasDoubleTap = true
            return .medium
        }
        pressWasDoubleTap = false
        if state == .off {
            state = .momentary
            return .light
        }
        return nil
    }

    mutating func release(now: Date = Date()) -> Feedback? {
        defer {
            lastReleaseTime = now
            isHeld = false
        }
        // The lock was already applied on press-down; leave it alone.
        if pressWasDoubleTap {
            pressWasDoubleTap = false
            return nil
        }
        // Used as a held modifier — the modified keys are already sent, so drop it.
        if didTypeWhileHeld {
            state = .off
            return nil
        }
        // Held deliberately but never used: treat as cancelled rather than leaving the
        // modifier armed for a key the user never meant to modify.
        if now.timeIntervalSince(pressTime) >= Self.holdThreshold {
            state = .off
            return nil
        }
        // A plain tap: toggle relative to whatever the state was before this press.
        switch stateBeforePress {
        case .off:
            state = .on
        case .on, .locked, .momentary:
            state = .off
        }
        return .light
    }

    /// Call for every non-modifier key press. Spends a one-shot latch and records that
    /// a held modifier was actually used for something.
    mutating func noteKeyPress() {
        if isHeld {
            didTypeWhileHeld = true
        }
        // .on resets after one key; .momentary and .locked persist
        if state == .on {
            state = .off
        }
    }
}

// MARK: - KeyModifiers

/// Which sticky modifiers were live at the moment of a key press.
///
/// The keyboard view owns the latches, but the host controller is the one that has to
/// decide whether ⌃C means the letter c or the byte 0x03 — so the modifier state travels
/// with the press rather than being read back out of the view.
struct KeyModifiers: OptionSet {
    let rawValue: Int

    static let shift = KeyModifiers(rawValue: 1 << 0)
    static let control = KeyModifiers(rawValue: 1 << 1)
    static let option = KeyModifiers(rawValue: 1 << 2)
}

// MARK: - KeyAction

enum KeyAction {
    case character(String)
    case backspace
    case shift
    case control
    case option
    case tab
    case enter
    case space
    case escape
    case cursorLeft
    case cursorRight
    case cursorUp
    case cursorDown
    case home
    case end
    case pageUp
    case pageDown
    /// Forward delete — the key a full-size keyboard labels `⌦`, not Backspace.
    case forwardDelete
    /// F1 through F12. Carried as a number rather than twelve cases because every one of
    /// them is the same sequence with a different parameter.
    case function(Int)
    case dismiss
    case nextKeyboard
    case toggleTerminalMode
}

// MARK: - KeyEvent

/// A key press plus everything the host controller needs to turn it into bytes.
struct KeyEvent {
    let action: KeyAction
    let modifiers: KeyModifiers
    /// Terminal mode as it stood at the moment of the press. Carried along instead of
    /// re-read from UserDefaults per keystroke, which also keeps the byte encoding a
    /// pure function of the event.
    let isTerminalMode: Bool
}

// MARK: - TerminalMode

enum TerminalMode {
    /// Deliberately a key in the *extension's own* `UserDefaults.standard`, not an App
    /// Group suite. This keyboard declares `RequestsOpenAccess = false` so it can promise
    /// it has no network capability, and without full access an extension cannot reach a
    /// shared container at all — a suiteName here would silently read back nothing. The
    /// consequence is that the container app cannot see or change this setting. That is
    /// known and accepted; the switch lives on the keyboard itself.
    static let defaultsKey = "terminalMode"
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
    /// Fired instead of `action` when the key is held past the long-press threshold.
    /// A key that has one sends its primary action on finger-*up* rather than
    /// finger-down, so holding it does not also type the thing you were trying to avoid.
    let longPressAction: KeyAction?

    init(label: String, action: KeyAction, units: CGFloat = 1.0,
         normalLabel: String? = nil, shiftedLabel: String? = nil, isShifted: Bool = false,
         longPressAction: KeyAction? = nil) {
        self.label = label
        self.action = action
        self.units = units
        self.normalLabel = normalLabel
        self.shiftedLabel = shiftedLabel
        self.isShifted = isShifted
        self.longPressAction = longPressAction
    }

    static func letter(_ upper: String, shifted: Bool) -> KeyDef {
        let ch = shifted ? upper : upper.lowercased()
        return KeyDef(label: ch, action: .character(ch))
    }

    /// A key that displays both its normal and shifted labels, with styling based on current shift state.
    static func shiftable(_ normal: String, _ shiftedChar: String, isShifted: Bool,
                          units: CGFloat = 1.0) -> KeyDef {
        let ch = isShifted ? shiftedChar : normal
        return KeyDef(label: ch, action: .character(ch), units: units,
                      normalLabel: normal, shiftedLabel: shiftedChar, isShifted: isShifted)
    }

    /// A dual-label key whose two faces are different *actions*, not just different
    /// characters — the landscape cursor keys, which become Home and End under Shift.
    static func shiftableAction(_ normal: String, _ normalAction: KeyAction,
                                _ shifted: String, _ shiftedAction: KeyAction,
                                isShifted: Bool, units: CGFloat = 1.0) -> KeyDef {
        KeyDef(label: isShifted ? shifted : normal,
               action: isShifted ? shiftedAction : normalAction,
               units: units,
               normalLabel: normal, shiftedLabel: shifted, isShifted: isShifted)
    }

    static func char(_ s: String) -> KeyDef {
        KeyDef(label: s, action: .character(s))
    }
}
