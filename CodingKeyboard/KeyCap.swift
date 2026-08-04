import SwiftUI

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

    // Key repeat timing (matches system keyboard feel)
    private let repeatDelay: TimeInterval = 0.4
    private let repeatInterval: TimeInterval = 0.1

    @State private var isPressed = false
    @State private var repeatTask: Task<Void, Never>? = nil
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
        voiceOverLabel: String? = nil
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
    }

    var body: some View {
        ZStack {
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
        .contentShape(Rectangle())
        .onAppear { feedbackGenerator.prepare() }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    feedbackGenerator.impactOccurred()
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
                }
        )
        // Collapse the dual-label keys into a single spoken element; otherwise
        // VoiceOver reads both the normal and the shifted character.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel ?? label)
        .accessibilityAddTraits(.isKeyboardKey)
    }

    @ViewBuilder
    private var keyContent: some View {
        if let normal = normalLabel, let shifted = shiftedLabel {
            // Dual-label layout: normal in bottom-left, shifted in top-right (ZStack, may overlap)
            ZStack(alignment: .center) {
                Text(shifted)
                    .font(
                        .system(
                            size: isShifted ? 15 : 11,
                            weight: isShifted ? .semibold : .regular,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        isShifted ? Color.primary : Color.secondary
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topTrailing
                    )
                Text(normal)
                    .font(
                        .system(
                            size: isShifted ? 11 : 15,
                            weight: isShifted ? .regular : .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        isShifted ? Color.secondary : Color.primary
                    )
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
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Single-label layout for letters, modifiers, space etc.
            Text(label)
                .font(
                    .system(
                        size: style == .modifier ? 24 : 19,
                        weight: style == .modifier ? .regular : .semibold,
                        design: style == .modifier ? .default : .monospaced
                    )
                )
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
