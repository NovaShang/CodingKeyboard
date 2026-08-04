import SwiftUI

/// Fill laid under a key's full hit rectangle, including the padding that widens it.
///
/// Hit testing here follows actually-rendered content: a region made only of padding is
/// empty, and `.contentShape(Rectangle())` alone did not make it tappable. That left a
/// dead strip along every gap between keys — 8pt between rows, 6pt between columns —
/// which felt like the keys simply being smaller than they look.
///
/// This gives the whole rectangle real content to hit-test against. The alpha sits far
/// below the threshold of visibility, but it is deliberately not zero.
let keyHitFill = Color.black.opacity(0.002)

// MARK: - KeyCapStyle

enum KeyCapStyle {
    case normal    // white key
    case modifier  // action key (shift, backspace, enter, tab, dismiss)
    case space     // space bar
}

// MARK: - KeyCap
// Pure visual component — knows nothing about KeyDef or KeyAction.
// All style and interaction feedback changes go here.

struct KeyCap: View {
    let label: String
    let style: KeyCapStyle
    let width: CGFloat
    let height: CGFloat
    let action: @MainActor () -> Void
    /// If set, the key shows two labels: shiftedLabel on top, normalLabel on bottom.
    let normalLabel: String?
    let shiftedLabel: String?
    let isShifted: Bool
    /// Extra padding around the visual key that extends the hit area.
    let hitPadding: EdgeInsets
    /// Whether holding the key down repeats the action. Only navigation and deletion
    /// keys should repeat; a character key that repeats turns an ordinary pause with
    /// a finger resting on the key into a run of duplicated characters.
    let repeatsOnHold: Bool
    /// Spoken description for VoiceOver. The visible label is often a bare symbol
    /// (⌫, ↵, ⇥) that does not read usefully on its own.
    let voiceOverLabel: String?
    /// Fired instead of `action` when the key is held past the long-press threshold.
    ///
    /// A key that has one gives up this keyboard's usual fire-on-press-down behaviour and
    /// sends its primary action on finger-*up* instead — otherwise holding ⇥ to switch
    /// modes would also type the tab you were holding it to avoid. The trade is only
    /// worth making for keys nobody types at speed.
    let onLongPress: (@MainActor () -> Void)?
    /// Set for keys that live inside a horizontally scrolling row, which are driven by a
    /// `Button` rather than by this keyboard's usual drag gesture — see `keyBody`.
    ///
    /// Such a key cannot commit on finger-down the way the rest of the keyboard does: the
    /// same touch may still turn out to be a scroll, and firing first would mean every
    /// attempt to scroll the row typed a character. It types on the lift instead, and the
    /// scroll view drops the press outright once the finger starts panning.
    var scrollSafe: Bool = false

    // Key repeat timing (matches system keyboard feel)
    private let repeatDelay: TimeInterval = 0.4
    private let repeatInterval: TimeInterval = 0.1

    @State private var isPressed = false
    @State private var repeatTask: Task<Void, Never>? = nil
    @State private var longPressTask: Task<Void, Never>? = nil
    /// Set once the hold threshold fires, so the following lift does not also type.
    @State private var didLongPress = false
    /// Set when a scroll-safe press has already produced output before the finger came
    /// up, so the lift does not add one more. Only scroll-safe keys need it: everywhere
    /// else the press-down always types and the lift never does.
    @State private var didTypeDuringPress = false
    // NOTE: haptics are a no-op inside the keyboard extension. iOS only lets a
    // keyboard play haptic feedback when the user grants "Allow Full Access", and
    // this keyboard deliberately declares RequestsOpenAccess = false so it can
    // guarantee it has no network capability. The calls are kept because they cost
    // nothing, still work in the container app and in previews, and start working
    // automatically for anyone who forks this and opts into open access.
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    init(
        label: String,
        style: KeyCapStyle,
        width: CGFloat,
        height: CGFloat,
        action: @MainActor @escaping () -> Void,
        normalLabel: String? = nil,
        shiftedLabel: String? = nil,
        isShifted: Bool = false,
        hitPadding: EdgeInsets = .init(),
        repeatsOnHold: Bool = false,
        voiceOverLabel: String? = nil,
        onLongPress: (@MainActor () -> Void)? = nil,
        scrollSafe: Bool = false
    ) {
        self.label = label
        self.style = style
        self.width = width
        self.height = height
        self.action = action
        self.normalLabel = normalLabel
        self.shiftedLabel = shiftedLabel
        self.isShifted = isShifted
        self.hitPadding = hitPadding
        self.repeatsOnHold = repeatsOnHold
        self.voiceOverLabel = voiceOverLabel
        self.onLongPress = onLongPress
        self.scrollSafe = scrollSafe
    }

    var body: some View {
        keyBody
            // Collapse the dual-label keys into a single spoken element; otherwise
            // VoiceOver reads both the normal and the shifted character.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(voiceOverLabel ?? label)
            .accessibilityAddTraits(.isKeyboardKey)
    }

    @ViewBuilder
    private var keyBody: some View {
        let cap = ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            keyContent
        }
        .frame(width: width, height: height)
        .scaleEffect(isPressed ? 0.94 : 1.0)
        // Highlight instantly on press-down and only fade on release. Easing *into* the
        // pressed state meant a fast tap could finish before the animation arrived, so
        // the key barely appeared to react at all.
        .animation(isPressed ? nil : .easeOut(duration: 0.16), value: isPressed)
        .padding(hitPadding)
        .background(keyHitFill)
        .contentShape(Rectangle())
        .onAppear { feedbackGenerator.prepare() }

        if scrollSafe {
            // A Button, not a gesture. This is the whole reason a key can live inside a
            // scrolling row: a scroll view knows how to cancel a button press once the
            // finger turns out to be panning, and it cannot do that to a DragGesture —
            // one attached to a key claims the touch and the row simply will not scroll,
            // with or without `simultaneousGesture`. The cost is that these keys type on
            // the lift rather than on the press, which is exactly what makes them safe.
            Button {
                // A press that already typed on the way down has done its work; one that
                // resolved as a long press did something else entirely.
                if !didTypeDuringPress && !didLongPress { action() }
                didLongPress = false
            } label: {
                cap
            }
            .buttonStyle(PressReportingStyle(onPressChange: pressChanged))
        } else {
            cap.gesture(pressGesture)
        }
    }

    /// Mirrors a `Button`'s own press tracking into the state the key already draws from,
    /// so a scroll-safe key looks and repeats exactly like every other key.
    private struct PressReportingStyle: ButtonStyle {
        let onPressChange: (Bool) -> Void

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .onChange(of: configuration.isPressed) { _, pressed in
                    onPressChange(pressed)
                }
        }
    }

    private func pressChanged(_ pressed: Bool) {
        guard pressed else {
            isPressed = false
            repeatTask?.cancel()
            repeatTask = nil
            longPressTask?.cancel()
            longPressTask = nil
            return
        }
        isPressed = true
        // Cleared on the way down rather than on the way up: the button's action runs
        // after the press ends and has to see what *this* press already did.
        didTypeDuringPress = false
        feedbackGenerator.impactOccurred()

        if let onLongPress {
            didLongPress = false
            longPressTask = Task {
                try? await Task.sleep(for: .seconds(ModifierLatch.holdThreshold))
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    didLongPress = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onLongPress()
                }
            }
            return
        }

        // Everything else in a scrolling row waits for the lift, but a repeating key has
        // to answer on the way down: holding ← to run the cursor left is the entire point
        // of it, and deferring would leave the cursor still until repeat kicked in half a
        // second later. Doing it here is safe despite the scroll view — a press only
        // registers at all once UIScrollView has held the touch back long enough to rule
        // a pan out, and a pan starting after that cancels the press outright.
        guard repeatsOnHold else { return }
        didTypeDuringPress = true
        action()
        repeatTask = Task {
            try? await Task.sleep(for: .seconds(repeatDelay))
            while !Task.isCancelled {
                await MainActor.run {
                    feedbackGenerator.impactOccurred()
                    action()
                }
                try? await Task.sleep(for: .seconds(repeatInterval))
            }
        }
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isPressed else { return }
                isPressed = true
                feedbackGenerator.impactOccurred()

                if let onLongPress {
                    didLongPress = false
                    longPressTask = Task {
                        try? await Task.sleep(for: .seconds(ModifierLatch.holdThreshold))
                        await MainActor.run {
                            // Checked here rather than before the hop: a finger lifting
                            // in between would cancel the task too late to stop this
                            // block, and the key would both type and switch modes.
                            guard !Task.isCancelled else { return }
                            didLongPress = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onLongPress()
                        }
                    }
                    return
                }

                action()
                guard repeatsOnHold else { return }
                // Start repeat after initial delay
                repeatTask = Task {
                    try? await Task.sleep(for: .seconds(repeatDelay))
                    while !Task.isCancelled {
                        await MainActor.run {
                            feedbackGenerator.impactOccurred()
                            action()
                        }
                        try? await Task.sleep(for: .seconds(repeatInterval))
                    }
                }
            }
            .onEnded { _ in
                isPressed = false
                repeatTask?.cancel()
                repeatTask = nil
                longPressTask?.cancel()
                longPressTask = nil
                // Deferred from press-down: a key with a long-press alternative only
                // knows which of the two the user meant once the finger comes up.
                if onLongPress != nil && !didLongPress {
                    action()
                }
                didLongPress = false
            }
    }

    @ViewBuilder
    private var keyContent: some View {
        if let normal = normalLabel, let shifted = shiftedLabel {
            // Dual-label layout: normal in bottom-left, shifted in top-right (ZStack, may overlap)
            ZStack(alignment: .center) {
                Text(shifted)
                    .font(
                        KeyboardFont.label(
                            size: isShifted ? 15 : 11,
                            weight: isShifted ? .semibold : .regular
                        )
                    )
                    .foregroundStyle(
                        isShifted ? Color.primary : Color.secondary
                    )
                    // Word faces (the landscape cursor keys carry "Home" and "End") are
                    // far wider than the single characters this layout was drawn for.
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topTrailing
                    )
                Text(normal)
                    .font(
                        KeyboardFont.label(
                            size: isShifted ? 11 : 15,
                            weight: isShifted ? .regular : .semibold
                        )
                    )
                    .foregroundStyle(
                        isShifted ? Color.secondary : Color.primary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottomLeading
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        } else if label.hasPrefix("sf:") {
            // SF Symbol icon (e.g. "sf:globe")
            Image(systemName: String(label.dropFirst(3)))
                .font(.system(size: KeyboardFont.symbolSize, weight: .regular))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Single-label layout for letters, modifiers, space etc.
            Text(label)
                .font(singleLabelFont)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// A modifier key spelled with a word — esc, home, end — is text, not an icon, and
    /// needs `wordSize` rather than the glyph size tuned for ⇧ ⌫ ↵ ⇥.
    private var singleLabelFont: Font {
        guard style == .modifier else {
            return KeyboardFont.label(size: KeyboardFont.characterSize, weight: .semibold)
        }
        if label.count > 1 {
            return KeyboardFont.label(size: KeyboardFont.wordSize, weight: .medium)
        }
        return KeyboardFont.label(size: KeyboardFont.modifierSize, weight: .regular)
    }

    /// Pressing swaps the key toward the opposite tone, the way the system keyboard does:
    /// in light mode a white character key darkens and a gray modifier key turns white;
    /// in dark mode both simply brighten, since there is no lighter surface to fall back
    /// to. A scale change alone reads as almost nothing at typing speed.
    private var backgroundColor: Color {
        let pressed = isPressed
        switch style {
        case .normal, .space:
            return Color(
                UIColor(dynamicProvider: { t in
                    t.userInterfaceStyle == .dark
                        ? UIColor(white: pressed ? 0.62 : 0.40, alpha: 1)
                        : UIColor(white: pressed ? 0.78 : 1.0, alpha: 1)
                })
            )
        case .modifier:
            return Color(
                UIColor(dynamicProvider: { t in
                    t.userInterfaceStyle == .dark
                        ? UIColor(white: pressed ? 0.46 : 0.25, alpha: 1)
                        : UIColor(white: pressed ? 1.0 : 0.80, alpha: 1)
                })
            )
        }
    }
}
#Preview("Light — unshifted") {
    HStack(spacing: 6) {
        KeyCap(
            label: "1",
            style: .normal,
            width: 44,
            height: 44,
            action: {},
            normalLabel: "1",
            shiftedLabel: "!",
            isShifted: false
        )
        KeyCap(label: "a", style: .normal, width: 44, height: 44, action: {})
        KeyCap(label: "⇧", style: .modifier, width: 66, height: 44, action: {})
    }
    .padding()
    .background(Color(UIColor.systemGray6))
}

#Preview("Light — shifted") {
    HStack(spacing: 6) {
        KeyCap(
            label: "!",
            style: .normal,
            width: 44,
            height: 44,
            action: {},
            normalLabel: "1",
            shiftedLabel: "!",
            isShifted: true
        )
        KeyCap(label: "A", style: .normal, width: 44, height: 44, action: {})
        KeyCap(label: "⇧", style: .modifier, width: 66, height: 44, action: {})
    }
    .padding()
    .background(Color(UIColor.systemGray6))
}

#Preview("Dark — unshifted") {
    HStack(spacing: 6) {
        KeyCap(
            label: "1",
            style: .normal,
            width: 44,
            height: 44,
            action: {},
            normalLabel: "1",
            shiftedLabel: "!",
            isShifted: false
        )
        KeyCap(label: "a", style: .normal, width: 44, height: 44, action: {})
        KeyCap(label: "⇧", style: .modifier, width: 66, height: 44, action: {})
    }
    .padding()
    .background(Color(UIColor.systemGray6))
    .preferredColorScheme(.dark)
}
