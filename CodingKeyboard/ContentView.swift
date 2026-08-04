import SwiftUI

struct ContentView: View {
    @State private var typedText = ""
    @State private var showsBytes = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Hint banner
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.body.weight(.semibold))
                Text("Long-press  \(Image(systemName: "globe"))  on the keyboard to switch to **Coding Keyboard**")
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)

            // Byte inspector. Collapsed by default — it is a checking tool, not part of
            // the scratch pad. Terminal mode's whole claim is that ⌃C produces the single
            // byte 0x03 and Return produces 0x0D, and a text field renders neither
            // visibly, so there has to be somewhere to read the bytes back.
            DisclosureGroup(isExpanded: $showsBytes) {
                ScrollView {
                    Text(hexDump)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
                .frame(maxHeight: 160)
            } label: {
                HStack {
                    Text("Bytes")
                    Spacer()
                    Text("\(typedText.utf8.count)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
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

    /// Eight bytes per line, offset on the left and a printable column on the right —
    /// the layout `hexdump -C` uses, because anyone who needs this screen already reads
    /// that one.
    private var hexDump: String {
        let bytes = Array(typedText.utf8)
        guard !bytes.isEmpty else { return "(empty)" }

        return stride(from: 0, to: bytes.count, by: 8).map { offset -> String in
            let chunk = bytes[offset..<min(offset + 8, bytes.count)]
            let hex = chunk
                .map { String(format: "%02X", $0) }
                .joined(separator: " ")
                // 8 bytes come to 23 characters; short final lines pad out so the
                // printable column stays put.
                .padding(toLength: 23, withPad: " ", startingAt: 0)
            let printable = chunk
                .map { (0x20...0x7E).contains($0) ? String(UnicodeScalar($0)) : "." }
                .joined()
            return String(format: "%04X  ", offset) + hex + "  |" + printable + "|"
        }
        .joined(separator: "\n")
    }
}

#Preview {
    ContentView()
}
