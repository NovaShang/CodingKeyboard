import SwiftUI
import UIKit

/// A UIKit-backed globe key that uses the system `handleInputModeList(from:with:)`
/// to provide native tap-to-switch and long-press-to-pick behavior.
struct GlobeKeyButton: View {
    let width: CGFloat
    let height: CGFloat
    /// Extra hit area around the visible cap. The UIButton is laid out across this whole
    /// region while the cap stays inset, so the gaps flanking the key still trigger it —
    /// padding applied by the caller would sit outside the button and be dead.
    var hitPadding: EdgeInsets = .init()

    /// The visible surface is a SwiftUI shape behind a UIButton, so the button's own
    /// highlighting never reaches it. Without this the globe was the one key on the
    /// keyboard that gave no press feedback whatsoever.
    @State private var isPressed = false

    private var backgroundColor: Color {
        let pressed = isPressed
        return Color(
            UIColor(dynamicProvider: { t in
                t.userInterfaceStyle == .dark
                    ? UIColor(white: pressed ? 0.46 : 0.25, alpha: 1)
                    : UIColor(white: pressed ? 1.0 : 0.80, alpha: 1)
            })
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(width: width, height: height)
            // Unconstrained, so it expands to the padded frame below and takes touches
            // from the surrounding gap as well as the cap itself.
            GlobeButtonRepresentable(isPressed: $isPressed)
        }
        .frame(
            width: width + hitPadding.leading + hitPadding.trailing,
            height: height + hitPadding.top + hitPadding.bottom
        )
        .animation(isPressed ? nil : .easeOut(duration: 0.16), value: isPressed)
    }
}

/// UIViewRepresentable that wraps a UIButton wired to `handleInputModeList(from:with:)`.
private struct GlobeButtonRepresentable: UIViewRepresentable {
    @Binding var isPressed: Bool

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "globe", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.backgroundColor = .clear
        // The button carries only an image, so VoiceOver has nothing to announce.
        button.accessibilityLabel = "Next keyboard"

        // The system handles tap (advance) and long-press (picker) automatically
        // when we target handleInputModeList(from:with:) for .allTouchEvents.
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.forwardToInputViewController(_:event:)),
            for: .allTouchEvents
        )
        // Separate targets purely for the highlight. Registering these alongside the
        // .allTouchEvents target above does not disturb it — both fire.
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.pressDown),
            for: [.touchDown, .touchDragEnter]
        )
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.pressUp),
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )

        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        // Refreshed each update so the coordinator never holds a stale binding.
        context.coordinator.isPressed = $isPressed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPressed: $isPressed)
    }

    final class Coordinator: NSObject {
        var isPressed: Binding<Bool>

        init(isPressed: Binding<Bool>) {
            self.isPressed = isPressed
        }

        @objc func pressDown() { isPressed.wrappedValue = true }
        @objc func pressUp() { isPressed.wrappedValue = false }

        @objc func forwardToInputViewController(_ sender: UIView, event: UIEvent) {
            var responder: UIResponder? = sender
            while let next = responder?.next {
                if let inputVC = next as? UIInputViewController {
                    inputVC.handleInputModeList(from: sender, with: event)
                    return
                }
                responder = next
            }
        }
    }
}
