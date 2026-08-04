//
//  ShiftKeyCap.swift
//  CodingKeyboard
//
//  Created by Nova on 3/1/26.
//


import SwiftUI

/// A latching modifier cap: Shift, Caps Lock, and — in terminal mode — Control, Option
/// and the terminal-mode switch itself.
///
/// It draws an active state that an ordinary `KeyCap` has no concept of, and it reports
/// finger-down and finger-up separately instead of a single tap. All five keys need both,
/// so they share this one view rather than each growing its own copy; the state machine
/// that interprets the two callbacks is `ModifierLatch`.
struct ShiftKeyCap: View {
    let shiftState: ShiftState
    let width: CGFloat
    let height: CGFloat
    let customLabel: String?
    /// What VoiceOver calls this key. The visible label is either a bare glyph or a
    /// four-letter abbreviation, and neither reads out usefully.
    let accessibilityName: String
    /// Extra padding around the visual key that extends the hit area, exactly as KeyCap
    /// takes it. It must be applied *inside* this view: applied by the caller it lands
    /// outside the gesture modifier, leaving the gap between keys dead.
    let hitPadding: EdgeInsets
    let onPressDown: @MainActor () -> Void
    let onRelease: @MainActor () -> Void

    init(shiftState: ShiftState, width: CGFloat, height: CGFloat,
         label: String? = nil,
         accessibilityName: String? = nil,
         hitPadding: EdgeInsets = .init(),
         onPressDown: @escaping @MainActor () -> Void,
         onRelease: @escaping @MainActor () -> Void) {
        self.shiftState = shiftState
        self.width = width
        self.height = height
        self.customLabel = label
        self.accessibilityName = accessibilityName ?? label ?? "Shift"
        self.hitPadding = hitPadding
        self.onPressDown = onPressDown
        self.onRelease = onRelease
    }

    @State private var isPressed = false

    private var label: String {
        if let customLabel { return customLabel }
        return shiftState == .locked ? "⇪" : "⇧"
    }

    private var backgroundColor: Color {
        let active = shiftState.isActive
        let pressed = isPressed
        return Color(UIColor(dynamicProvider: { t in
            if t.userInterfaceStyle == .dark {
                if pressed { return UIColor(white: active ? 0.70 : 0.46, alpha: 1) }
                return active ? UIColor(white: 0.55, alpha: 1) : UIColor(white: 0.25, alpha: 1)
            } else {
                if pressed { return UIColor(white: active ? 0.35 : 1.0, alpha: 1) }
                return active ? UIColor(white: 0.50, alpha: 1) : UIColor(white: 0.80, alpha: 1)
            }
        }))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            Text(label)
                .font(customLabel != nil
                      ? KeyboardFont.label(size: KeyboardFont.wordSize, weight: .medium)
                      : KeyboardFont.label(size: KeyboardFont.modifierSize))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(shiftState.isActive ? Color.white : Color.primary)
        }
        .frame(width: width, height: height)
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(isPressed ? nil : .easeOut(duration: 0.16), value: isPressed)
        .padding(hitPadding)
        .background(keyHitFill)
        // Rectangular on purpose: without it the hit shape follows the rounded
        // background, so the four corners of the key do not respond.
        .contentShape(Rectangle())
        // Deliberately timer-free: the key reports only finger-down and finger-up, and
        // the parent resolves what the press meant. Shift has to take effect the
        // instant the finger lands, or holding it with one thumb and typing with the
        // other produces lowercase until some threshold elapses.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    onPressDown()
                }
                .onEnded { _ in
                    isPressed = false
                    onRelease()
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(shiftState.isActive ? "on" : "off")
        .accessibilityAddTraits(.isKeyboardKey)
    }
}
