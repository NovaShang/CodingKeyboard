import SwiftUI
import UIKit

/// A UIKit-backed globe key that uses the system `handleInputModeList(from:with:)`
/// to provide native tap-to-switch and long-press-to-pick behavior.
struct GlobeKeyButton: View {
    let width: CGFloat
    let height: CGFloat

    private var backgroundColor: Color {
        Color(
            UIColor(dynamicProvider: { t in
                t.userInterfaceStyle == .dark
                    ? UIColor(white: 0.25, alpha: 1)
                    : UIColor(white: 0.80, alpha: 1)
            })
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            GlobeButtonRepresentable()
        }
        .frame(width: width, height: height)
    }
}

/// UIViewRepresentable that wraps a UIButton wired to `handleInputModeList(from:with:)`.
private struct GlobeButtonRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "globe", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.backgroundColor = .clear

        // The system handles tap (advance) and long-press (picker) automatically
        // when we target handleInputModeList(from:with:) for .allTouchEvents.
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.forwardToInputViewController(_:event:)),
            for: .allTouchEvents
        )

        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
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
