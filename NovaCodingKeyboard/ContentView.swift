import SwiftUI

struct ContentView: View {
    @State private var typedText = ""

    var body: some View {
        ScrollView {
            Text(typedText.isEmpty ? "Start typing..." : typedText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(typedText.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CodingKeyboardView(onAction: handleAction)
                .background(alignment: .bottom) {
                    Color(UIColor.systemGray6)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
    }

    private func handleAction(_ action: KeyAction) {
        switch action {
        case .character(let c): typedText.append(c)
        case .backspace:        if !typedText.isEmpty { typedText.removeLast() }
        case .enter:            typedText.append("\n")
        case .space:            typedText.append(" ")
        case .shift:            break
        }
    }
}

#Preview {
    ContentView()
        .safeAreaPadding(.bottom, 34)
}
