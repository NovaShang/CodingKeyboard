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
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(backgroundColor)
                        .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 1)
                )
                .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
        .frame(width: width, height: height)
    }

    private var backgroundColor: Color {
        switch style {
        case .normal, .space:
            return Color(UIColor.systemBackground)
        case .modifier:
            return Color(UIColor.systemGray3)
        }
    }
}
#Preview("All styles") {
    HStack(spacing: 6) {
        KeyCap(label: "a",     style: .normal,   width: 44, height: 44, action: {})
        KeyCap(label: "⇧",    style: .modifier, width: 66, height: 44, action: {})
        KeyCap(label: "space", style: .space,    width: 88, height: 44, action: {})
    }
    .padding()
    .background(Color(UIColor.systemGray5))
}

