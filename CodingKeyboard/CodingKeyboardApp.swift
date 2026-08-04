//
//  CodingKeyboardApp.swift
//  CodingKeyboard
//
//  Created by Nova on 3/1/26.
//

import SwiftUI

@main
struct CodingKeyboardApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isKeyboardEnabled = false
    /// Remembered, so that a wrong inference does not strand the user again on every
    /// single launch. See `KeyboardSetupView.onSkip`.
    @AppStorage("didSkipKeyboardSetup") private var didSkipSetup = false

    private let extensionBundleID = "com.novashang.NovaCodingKeyboard.KeyboardExtension"

    var body: some Scene {
        WindowGroup {
            Group {
                if isKeyboardEnabled || didSkipSetup {
                    ContentView()
                } else {
                    KeyboardSetupView(onSkip: { didSkipSetup = true })
                }
            }
            // Also checked here, not only on the scene-phase change: onChange fires on
            // transitions, so relying on it alone leaves the first launch depending on
            // a transition that may already have happened.
            .task { checkKeyboardEnabled() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                checkKeyboardEnabled()
            }
        }
    }

    private func checkKeyboardEnabled() {
        let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
        isKeyboardEnabled = keyboards.contains(extensionBundleID)
    }
}
