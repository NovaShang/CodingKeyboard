import SwiftUI

struct KeyboardSetupView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "keyboard")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text("Enable Nova Coding Keyboard")
                    .font(.title2.bold())

                Text("Enable this keyboard in Settings,\nthen come back here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                stepRow(number: 1, text: "Tap the button below to open Settings")
                stepRow(number: 2, text: "Select \"Keyboards\"")
                stepRow(number: 3, text: "Enable \"NovaCodingKeyboard\"")
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
