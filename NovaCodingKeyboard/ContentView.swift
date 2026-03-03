import SwiftUI

struct ContentView: View {
    @State private var typedText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Hint banner
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.body.weight(.semibold))
                Text("Long-press  \(Image(systemName: "globe"))  on the keyboard to switch to **Nova Coding Keyboard**")
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)

            // Text area
            TextEditor(text: $typedText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .focused($isFocused)
                .onAppear { isFocused = true }
        }
    }
}

#Preview {
    ContentView()
}
