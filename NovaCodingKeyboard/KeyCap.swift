import SwiftUI

// MARK: - KeyCapStyle

enum KeyCapStyle {
    case normal  // white key
    case modifier  // darker key (shift, backspace, enter, tab)
    case space  // space bar
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

    init(
        label: String,
        style: KeyCapStyle,
        width: CGFloat,
        height: CGFloat,
        action: @MainActor @escaping () -> Void,
        normalLabel: String? = nil,
        shiftedLabel: String? = nil,
        isShifted: Bool = false
    ) {
        self.label = label
        self.style = style
        self.width = width
        self.height = height
        self.action = action
        self.normalLabel = normalLabel
        self.shiftedLabel = shiftedLabel
        self.isShifted = isShifted
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                keyContent
            }
        }
        .buttonStyle(.plain)
        .frame(width: width, height: height)
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
                            weight: isShifted ? .bold : .regular,
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
                            weight: isShifted ? .regular : .bold,
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
        } else {
            // Single-label layout for letters, modifiers, space etc.
            Text(label)
                .font(
                    .system(
                        size: style == .modifier ? 24 : 19,
                        weight: style == .modifier ? .regular : .bold,
                        design: style == .modifier ? .default : .monospaced
                    )
                )
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .normal, .space:
            // Light: near-white; Dark: mid-gray — matches system keyboard normal key
            return Color(
                UIColor(dynamicProvider: { t in
                    t.userInterfaceStyle == .dark
                        ? UIColor(white: 0.32, alpha: 1)
                        : UIColor(white: 1.0, alpha: 1)
                })
            )
        case .modifier:
            return Color(
                UIColor(dynamicProvider: { t in
                    t.userInterfaceStyle == .dark
                        ? UIColor(white: 0.38, alpha: 1)
                        : UIColor(white: 0.72, alpha: 1)
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
