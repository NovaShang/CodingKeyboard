import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var hostingController: UIHostingController<CodingKeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        let keyboardView = CodingKeyboardView(onAction: { [weak self] action in
            self?.handle(action)
        })

        let hosting = UIHostingController(rootView: keyboardView)
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

    // Allow the system to switch to another keyboard when needed
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
}
