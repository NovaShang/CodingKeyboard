import SwiftUI

struct KeyboardSetupView: View {
    @Environment(\.openURL) private var openURL

    /// Escape hatch out of this screen.
    ///
    /// Whether the keyboard is enabled is inferred from `AppleKeyboards`, a key that is
    /// not part of any public API. If that inference is ever wrong — a future OS stops
    /// populating it, or populates it differently — there is otherwise no way past this
    /// screen and the app simply looks broken to someone who has already done what it
    /// asked. That includes an App Review reviewer.
    let onSkip: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "keyboard")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text("Enable Coding Keyboard")
                    .font(.title2.bold())

                Text("Enable this keyboard in Settings,\nthen come back here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                stepRow(number: 1, text: "Tap the button below to open Settings")
                stepRow(number: 2, text: "Select \"Keyboards\"")
                stepRow(number: 3, text: "Enable \"Coding Keyboard\"")
                stepRow(number: 4, text: "Return to this app")
            }
            .padding(.horizontal, 32)

            Button {
                openAppSettings()
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 48)

            Button("I've already enabled it", action: onSkip)
                .font(.subheadline)

            Spacer()
            Spacer()
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.tint))
            Text(text)
                .font(.subheadline)
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
