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
            onAction: { [weak self] action in
                self?.handle(action)
            }
        )
    }

    private func handle(_ action: KeyAction) {
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
        case .shift:
            break  // shift state is managed inside CodingKeyboardView
        case .dismiss:
            dismissKeyboard()
        case .nextKeyboard:
            advanceToNextInputMode()
        }
    }
}
