import SwiftUI

// MARK: - KeyCapStyle

enum KeyCapStyle {
    case normal    // white key
    case modifier  // darker key (shift, backspace, enter, tab)
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

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                )
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .frame(width: width, height: height)
    }

    private var backgroundColor: Color {
        switch style {
        case .normal, .space:
            // Light: near-white; Dark: mid-gray — matches system keyboard normal key
            return Color(UIColor(dynamicProvider: { t in
                t.userInterfaceStyle == .dark
                    ? UIColor(white: 0.32, alpha: 1)
                    : UIColor(white: 1.0, alpha: 1)
            }))
        case .modifier:
            // Light: light gray; Dark: slightly darker than normal — matches system modifier key
            return Color(UIColor(dynamicProvider: { t in
                t.userInterfaceStyle == .dark
                    ? UIColor(white: 0.25, alpha: 1)
                    : UIColor(white: 0.82, alpha: 1)
            }))
        }
    }
}
#Preview("Light") {
    HStack(spacing: 6) {
        KeyCap(label: "a",     style: .normal,   width: 44, height: 44, action: {})
        KeyCap(label: "⇧",    style: .modifier, width: 66, height: 44, action: {})
        KeyCap(label: "space", style: .space,    width: 88, height: 44, action: {})
    }
    .padding()
    .background(Color(UIColor.systemGray6))
}

#Preview("Dark") {
    HStack(spacing: 6) {
        KeyCap(label: "a",     style: .normal,   width: 44, height: 44, action: {})
        KeyCap(label: "⇧",    style: .modifier, width: 66, height: 44, action: {})
        KeyCap(label: "space", style: .space,    width: 88, height: 44, action: {})
    }
    .padding()
    .background(Color(UIColor.systemGray6))
    .preferredColorScheme(.dark)
}

