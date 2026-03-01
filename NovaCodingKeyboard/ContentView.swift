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
            CodingKeyboardView(text: $typedText)
                .background(alignment: .bottom) {
                    // Extends the keyboard background colour into the home indicator area
                    Color(UIColor.systemGray5)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
    }
}

#Preview {
    ContentView()
        .safeAreaPadding(.bottom, 34)
}
