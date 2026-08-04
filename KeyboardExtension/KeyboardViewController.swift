import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var hostingController: UIHostingController<CodingKeyboardView>?

    /// Whether this keyboard has to draw its own globe key. Starts as `true` so that an
    /// early or stale reading can never strand the user with no way off this keyboard —
    /// an extra key is recoverable, a missing one is not. Corrected in
    /// `syncInputModeSwitchKey()` before the keyboard is ever shown.
    private var showsGlobeKey = true

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        let hosting = UIHostingController(rootView: makeKeyboardView())
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        hostingController = hosting

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Earliest point where the value is trustworthy, and still before the keyboard
        // is on screen, so correcting it here costs no visible flash.
        syncInputModeSwitchKey()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Re-checked every layout pass because the answer is not fixed for the lifetime
        // of the extension: attaching a hardware keyboard or the host switching to a
        // number pad both change it.
        syncInputModeSwitchKey()
    }

    /// `needsInputModeSwitchKey` is false wherever the system draws its own globe key —
    /// full-screen iPhones put one below the keyboard for us. Drawing a second one there
    /// duplicates a system-provided control, which the HIG explicitly warns against; not
    /// drawing one where the system provides nothing leaves the user trapped, which is a
    /// review rejection. So the platform is asked rather than the device model guessed.
    private func syncInputModeSwitchKey() {
        let needed = needsInputModeSwitchKey
        guard needed != showsGlobeKey else { return }
        showsGlobeKey = needed
        hostingController?.rootView = makeKeyboardView()
    }

    private func makeKeyboardView() -> CodingKeyboardView {
        CodingKeyboardView(
            showsGlobeKey: showsGlobeKey,
            onAction: { [weak self] event in
                self?.handle(event)
            }
        )
    }

    private func handle(_ event: KeyEvent) {
        if event.isTerminalMode {
            handleTerminal(event)
        } else {
            handleNormal(event.action)
        }
    }

    // MARK: - Normal mode

    /// Ordinary text editing, unchanged since before terminal mode existed. Every key
    /// here does what the host app's text field expects: Return inserts a newline, Delete
    /// asks the proxy to delete, and the cursor keys move the insertion point.
    private func handleNormal(_ action: KeyAction) {
        let proxy = textDocumentProxy
        switch action {
        case .character(let c):
            proxy.insertText(c)
        case .backspace:
            proxy.deleteBackward()
        case .enter:
            proxy.insertText("\n")
        case .space:
            proxy.insertText(" ")
        case .tab:
            proxy.insertText("\t")
        case .cursorLeft:
            proxy.adjustTextPosition(byCharacterOffset: -1)
        case .cursorRight:
            proxy.adjustTextPosition(byCharacterOffset: 1)
        case .forwardDelete:
            // The nearest thing the proxy offers: step over the next character and delete
            // it backwards. A no-op at the end of the text, where the step does nothing.
            proxy.adjustTextPosition(byCharacterOffset: 1)
            proxy.deleteBackward()
        case .escape, .cursorUp, .cursorDown, .home, .end,
             .pageUp, .pageDown, .function:
            // Unreachable: none of these keys are on a normal-mode layout. They stay
            // silent rather than guessing — `adjustTextPosition` cannot move vertically
            // at all, and there is no proxy call that means Home, Page Up or Escape.
            break
        case .shift, .control, .option:
            break  // modifier state is managed inside CodingKeyboardView
        case .dismiss:
            dismissKeyboard()
        case .nextKeyboard:
            advanceToNextInputMode()
        case .toggleTerminalMode:
            break  // consumed by the view, which owns the mode
        }
    }

    // MARK: - Terminal mode

    /// In terminal mode a key press is a byte sequence, not an editing command.
    ///
    /// A custom keyboard has no API for sending key *events* — `UITextDocumentProxy`
    /// offers insertText, deleteBackward and adjustTextPosition and nothing else. That
    /// turns out not to matter for a terminal, because a terminal does not receive key
    /// events either: the PTY sees a byte stream. So inserting the byte that a real
    /// keyboard would have produced is not an approximation of pressing the key, it is
    /// the same thing, provided the host terminal forwards inserted text to the PTY.
    ///
    /// The corollary is that `deleteBackward()` and `adjustTextPosition` are useless
    /// here: they edit the host app's own text buffer, and the shell — which is the thing
    /// actually holding the line being edited — never hears about it.
    private func handleTerminal(_ event: KeyEvent) {
        let proxy = textDocumentProxy
        let ctrl = event.modifiers.contains(.control)
        let opt = event.modifiers.contains(.option)

        switch event.action {
        case .character(let c):
            // Control ignores Shift — ⌃A and ⌃a are both 0x01 — while Option does not,
            // since ⌥⇧B has to send ESC "B". That falls out for free: Control folds the
            // character through the C0 table, which is case-insensitive by construction,
            // and Option just prefixes whatever character the shift state already chose.
            var out = c
            if ctrl, let control = Self.controlByte(for: c) { out = control }
            // Meta is ESC-prefix. No terminal protocol carries an Alt bit; every one of
            // them spells the modifier as ESC followed by the unmodified key.
            if opt { out = "\u{1B}" + out }
            proxy.insertText(out)

        case .space:
            // ⌃Space is NUL, the one control byte with no letter to reach it through, and
            // what emacs and readline both read as set-mark.
            var out = ctrl ? "\u{0}" : " "
            if opt { out = "\u{1B}" + out }
            proxy.insertText(out)

        case .enter:
            // CR (0x0D), not LF. A terminal line discipline expects the carriage return
            // the Return key actually produces and echoes the newline itself; sending
            // 0x0A submits nothing in most shells. Control adds nothing: ⌃M *is* CR.
            proxy.insertText(opt ? "\u{1B}\r" : "\r")

        case .backspace:
            // The one place the byte-stream rule above does not hold. DEL (0x7F) is what a
            // real terminal sends for Backspace, but inserting it as *text* deletes nothing
            // anywhere: an ordinary text field renders it as an invisible control
            // character, and a terminal app reaches the PTY through deleteBackward()
            // regardless, because that is the only thing the system keyboard's delete key
            // ever calls and every such app has to handle it to be usable at all.
            // Sending the byte left the key visibly dead in every host.
            //
            // Modified, there is no such fallback to reach for — no proxy call means
            // "delete the previous word" — so those go out as bytes and are meaningful
            // only to a real terminal.
            if opt {
                proxy.insertText("\u{1B}\u{7F}")  // ESC DEL — readline's delete-word
            } else if ctrl {
                proxy.insertText("\u{08}")        // BS, the other backspace
            } else {
                proxy.deleteBackward()
            }

        case .tab:
            // Shift makes it back-tab: reverse completion in a shell, reverse focus in a
            // TUI. There is no C0 byte for that one — CSI Z is its only spelling.
            var out = event.modifiers.contains(.shift) ? "\u{1B}[Z" : "\t"
            if opt { out = "\u{1B}" + out }
            proxy.insertText(out)

        case .escape:
            proxy.insertText(opt ? "\u{1B}\u{1B}" : "\u{1B}")

        // Cursor and Home/End keys go out in the normal (CSI, `ESC [`) form rather than
        // the application form (`ESC O`). Which one a terminal wants depends on DECCKM,
        // a mode set by the remote application and invisible to us — `UITextDocumentProxy`
        // gives no way to read the terminal's state. `ESC [` is the safer default of the
        // two: bash/readline, vim and less all accept it, whereas `ESC O` is meaningless
        // to a shell that has not turned application mode on.
        case .cursorUp:
            proxy.insertText(Self.csi("A", event.modifiers))
        case .cursorDown:
            proxy.insertText(Self.csi("B", event.modifiers))

        // ⌥→ and ⌥← are the exception to the CSI rule, for the same reason `ESC [` beat
        // `ESC O` above: readline is the thing most likely to be on the other end, it
        // spells word-forward and word-back as `ESC f` and `ESC b`, and it does not
        // understand `ESC [ 1;3C` at all without a custom inputrc. Control keeps the CSI
        // form, which is what terminals have always sent for ⌃→ and what readline is
        // usually configured to accept alongside the meta pair.
        case .cursorRight:
            proxy.insertText(opt && !ctrl ? "\u{1B}f" : Self.csi("C", event.modifiers))
        case .cursorLeft:
            proxy.insertText(opt && !ctrl ? "\u{1B}b" : Self.csi("D", event.modifiers))

        case .home:
            proxy.insertText(Self.csi("H", event.modifiers))
        case .end:
            proxy.insertText(Self.csi("F", event.modifiers))

        // The `CSI n ~` family. ⌦ is 3, and is the forward delete a terminal expects —
        // Backspace above is the one that sends DEL.
        case .forwardDelete:
            proxy.insertText(Self.tilde(3, event.modifiers))
        case .pageUp:
            proxy.insertText(Self.tilde(5, event.modifiers))
        case .pageDown:
            proxy.insertText(Self.tilde(6, event.modifiers))

        case .function(let n):
            proxy.insertText(Self.functionKey(n, event.modifiers))

        case .shift, .control, .option:
            break  // a modifier press is state, not a byte

        case .dismiss:
            dismissKeyboard()
        case .nextKeyboard:
            advanceToNextInputMode()
        case .toggleTerminalMode:
            break  // consumed by the view, which owns the mode
        }
    }

    /// A cursor-key sequence with xterm's modifier encoding: `ESC [ 1 ; <n> <final>`,
    /// where n is 1 plus a bitmask of Shift(1), Alt(2), Control(4) — so ⇧ is 2, ⌥ is 3,
    /// ⌃ is 5, ⌃⇧ is 6, and so on. Unmodified, the parameters drop away entirely and it
    /// collapses back to the plain `ESC [ <final>` every terminal has always understood.
    private static func csi(_ final: String, _ modifiers: KeyModifiers) -> String {
        let mask = modifierMask(modifiers)
        return mask == 0 ? "\u{1B}[\(final)" : "\u{1B}[1;\(mask + 1)\(final)"
    }

    /// A `CSI n ~` key. Insert, Delete, Page Up/Down and F5 upwards are all this one
    /// shape, told apart only by the number.
    private static func tilde(_ number: Int, _ modifiers: KeyModifiers) -> String {
        let mask = modifierMask(modifiers)
        return mask == 0 ? "\u{1B}[\(number)~" : "\u{1B}[\(number);\(mask + 1)~"
    }

    /// F1–F4 are the odd ones out: unmodified they go as SS3 (`ESC O P`…`ESC O S`), which
    /// is what terminfo lists for xterm and what applications actually match on. Any
    /// modifier switches them to the CSI form, because SS3 has nowhere to put one. From F5
    /// up they are ordinary `CSI n ~` keys, on a numbering that skips 16 and 22 — the gaps
    /// are historical, not a mistake.
    private static func functionKey(_ n: Int, _ modifiers: KeyModifiers) -> String {
        switch n {
        case 1...4:
            let final = ["P", "Q", "R", "S"][n - 1]
            let mask = modifierMask(modifiers)
            return mask == 0 ? "\u{1B}O\(final)" : "\u{1B}[1;\(mask + 1)\(final)"
        default:
            let numbers = [5: 15, 6: 17, 7: 18, 8: 19, 9: 20, 10: 21, 11: 23, 12: 24]
            guard let number = numbers[n] else { return "" }
            return tilde(number, modifiers)
        }
    }

    /// xterm's modifier bitmask: Shift(1), Alt(2), Control(4). Sequences carry it as this
    /// plus one, so an unmodified key is 1 and drops the parameter altogether.
    private static func modifierMask(_ modifiers: KeyModifiers) -> Int {
        var mask = 0
        if modifiers.contains(.shift) { mask |= 1 }
        if modifiers.contains(.option) { mask |= 2 }
        if modifiers.contains(.control) { mask |= 4 }
        return mask
    }

    /// The C0 control byte for ⌃ + a key, or nil where the combination has no byte.
    ///
    /// The whole table is one mask: uppercase the character and clear the top three bits,
    /// which maps @ A…Z [ \ ] ^ _ (0x40–0x5F) onto 0x00–0x1F. That is where ⌃C = 0x03,
    /// ⌃D = 0x04 and ⌃[ = ESC all come from — they are not special cases, they are the
    /// same arithmetic ASCII was designed around.
    private static func controlByte(for character: String) -> String? {
        let upper = character.uppercased().unicodeScalars
        // Some characters uppercase to more than one scalar (ß → SS); those have no
        // control form, and taking just the first scalar would invent a wrong one.
        guard upper.count == 1, let scalar = upper.first,
              (0x40...0x5F).contains(scalar.value) else { return nil }
        return String(UnicodeScalar(UInt8(scalar.value & 0x1F)))
    }
}
