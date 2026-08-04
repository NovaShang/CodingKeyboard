import SwiftUI
import SwiftTerm

/// A VT100 emulator with nothing behind it.
///
/// Terminal mode's claim is that the keyboard sends the bytes a real keyboard would have
/// sent. The hex dump on the scratch pad proves the *cause* — that ⌃C produced one byte,
/// 0x03 — but a row of hex is a poor way to believe it. This pane shows the *effect*:
/// ⌃C prints `^C` and drops to a fresh prompt, the arrow keys really move the caret,
/// Home and End really jump. That is not a mock-up of those behaviours, it is SwiftTerm's
/// actual xterm state machine reacting to the actual bytes.
///
/// There is deliberately no shell. iOS gives an App Store app no way to spawn one —
/// SwiftTerm's own `LocalProcessTerminalView` is macOS-only for exactly that reason — and
/// the alternative, dialling out over SSH, would put a network stack inside an app whose
/// entire premise is that it has none. So this is a line discipline and nothing else: it
/// echoes, it handles erase, and it lets escape sequences through to the emulator.
struct EchoTerminal: UIViewRepresentable {

    func makeUIView(context: Context) -> TerminalView {
        let view = TerminalView(
            frame: .zero,
            font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        )
        view.terminalDelegate = context.coordinator
        view.nativeBackgroundColor = UIColor(white: 0.07, alpha: 1)
        view.nativeForegroundColor = UIColor(white: 0.86, alpha: 1)
        view.caretColor = UIColor(red: 0.30, green: 0.78, blue: 0.55, alpha: 1)
        view.backgroundColor = view.nativeBackgroundColor

        // SwiftTerm ships a `TerminalAccessory` bar by default — esc, ctrl, tab, arrows,
        // a handful of symbols. That is precisely the thing this keyboard exists to make
        // unnecessary, and leaving it here would both clutter the pane and argue against
        // the product inside its own demo.
        view.inputAccessoryView = nil

        context.coordinator.greet(view)

        // The pane is worthless without a keyboard up, and nothing else in the view
        // hierarchy is going to ask for one.
        DispatchQueue.main.async { view.becomeFirstResponder() }
        return view
    }

    func updateUIView(_ view: TerminalView, context: Context) {}

    func makeCoordinator() -> LineDiscipline { LineDiscipline() }
}

// MARK: - Line discipline

/// The part a kernel would normally own: echo, erase, and deciding what a byte means.
///
/// Bytes arrive here from `TerminalView`, which is a `UIKeyInput` — so a custom keyboard's
/// `insertText` lands in this method without any wiring of ours. What we send back with
/// `feed` is what a program on the other end of a PTY would have printed.
final class LineDiscipline: NSObject, TerminalViewDelegate {

    private let prompt = "$ "

    /// Cells written since the prompt. Erase stops here rather than eating the prompt
    /// itself, which is the one thing a real line discipline also refuses to do.
    private var column = 0

    func greet(_ view: TerminalView) {
        // Hard-wrapped narrow rather than left to the emulator: the pane is as wide as
        // the phone it is on, and a paragraph reflowed at 55 columns breaks words in the
        // middle. Short lines look deliberate at every width.
        let banner = """
        Coding Keyboard — echo terminal

        Nothing runs here. This is a VT100
        emulator with no shell behind it. It
        shows what your keystrokes send.

        Switch the keyboard to terminal mode,
        then try ^C, Esc, and the arrows.

        """
        view.feed(text: banner.replacingOccurrences(of: "\n", with: "\r\n"))
        view.feed(text: prompt)
        column = 0
    }

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        var out: [UInt8] = []
        var i = data.startIndex

        while i < data.endIndex {
            let byte = data[i]

            switch byte {
            case 0x0D, 0x0A:
                // Both spellings of Return land here. A terminal echoes CR as CRLF —
                // the carriage return alone would overwrite the line just typed.
                out += [0x0D, 0x0A]
                out += Array(prompt.utf8)
                column = 0
                i += 1

            case 0x7F, 0x08:
                // Erase is three bytes, not one: step left, paint a space over the glyph,
                // step left again. Sending DEL onward would delete nothing — it is an
                // input byte, and this side of the wire is output.
                if column > 0 {
                    out += [0x08, 0x20, 0x08]
                    column -= 1
                }
                i += 1

            case 0x1B:
                if let end = Self.escapeSequence(in: data, at: i) {
                    // A real sequence: hand it to the emulator so the caret actually
                    // moves. This is the whole point of the pane — ESC [ D is not
                    // *described* as "cursor left" here, it performs it.
                    out += data[i..<end]
                    i = end
                } else {
                    // A lone ESC, which is what the esc key sends. Show it the way stty
                    // echoctl would rather than swallowing it.
                    out += Self.caret(byte)
                    column += 2
                    i += 1
                }

            case 0x00...0x1F:
                out += Self.caret(byte)
                column += 2
                i += 1

            default:
                out.append(byte)
                column += 1
                i += 1
            }
        }

        source.feed(byteArray: out[...])
    }

    /// The end index of an escape sequence starting at `i`, or nil if these bytes are not
    /// one. Shaped after ECMA-48: CSI is `ESC [`, parameters, intermediates, then a final
    /// byte in 0x40–0x7E; SS3 is `ESC O` and a single final byte.
    private static func escapeSequence(in data: ArraySlice<UInt8>, at i: Int) -> Int? {
        var j = i + 1
        guard j < data.endIndex else { return nil }

        let introducer = data[j]
        guard introducer == 0x5B || introducer == 0x4F else { return nil }
        j += 1

        if introducer == 0x5B {
            while j < data.endIndex, (0x30...0x3F).contains(data[j]) { j += 1 }
            while j < data.endIndex, (0x20...0x2F).contains(data[j]) { j += 1 }
        }

        guard j < data.endIndex, (0x40...0x7E).contains(data[j]) else { return nil }
        return j + 1
    }

    /// `^X` notation. The control byte and the character it is named after differ by
    /// exactly the 0x40 bit that `KeyboardViewController` clears to produce it.
    private static func caret(_ byte: UInt8) -> [UInt8] {
        byte == 0x7F ? Array("^?".utf8) : [0x5E, byte + 0x40]
    }

    // MARK: Delegate methods with nothing to do
    //
    // TerminalViewDelegate has no default implementations, and none of the rest applies
    // to a terminal with no process, no title to set and no links to open.

    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: TerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    func scrolled(source: TerminalView, position: Double) {}
    func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {}
    func bell(source: TerminalView) {}
    func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {}
    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}

    // Clipboard access goes through OSC 52, which only a program on the far end can ask
    // for. There is no far end, so these stay closed rather than handing the general
    // pasteboard to an escape sequence.
    func clipboardCopy(source: TerminalView, content: Data) {}
    func clipboardRead(source: TerminalView) -> Data? { nil }
}
