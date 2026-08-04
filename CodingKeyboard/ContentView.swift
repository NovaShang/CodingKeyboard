import SwiftUI

/// The two things this app is for once the keyboard is enabled: somewhere to type, and
/// somewhere to see what typing actually sent.
private enum Pane: String, CaseIterable {
    case scratch = "Scratch"
    case terminal = "Terminal"
}

struct ContentView: View {
    @State private var typedText = ""
    @State private var showsBytes = false
    @State private var pane: Pane = .scratch
    @FocusState private var isFocused: Bool

    /// Compact height means a phone on its side, where the keyboard claims most of the
    /// screen and every row of chrome above it is one fewer row of content.
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isShort: Bool { verticalSizeClass == .compact }

    var body: some View {
        VStack(spacing: 0) {
            // Hint banner. Dropped in landscape on a phone: with the keyboard up there is
            // barely a hundred points left, and a line of advice about how to summon the
            // keyboard is worth least at the moment the keyboard is already up.
            if !isShort {
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
            }

            Picker("Pane", selection: $pane) {
                ForEach(Pane.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, isShort ? 6 : 0)
            .padding(.bottom, isShort ? 4 : 8)
            .background(.bar)

            switch pane {
            case .scratch: scratch
            case .terminal: EchoTerminal()
            }
        }
    }

    private var scratch: some View {
        VStack(spacing: 0) {
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
