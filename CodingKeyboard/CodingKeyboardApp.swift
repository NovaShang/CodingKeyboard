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

    private let extensionBundleID = "com.novashang.NovaCodingKeyboard.KeyboardExtension"

    var body: some Scene {
        WindowGroup {
            if isKeyboardEnabled {
                ContentView()
            } else {
                KeyboardSetupView()
            }
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
