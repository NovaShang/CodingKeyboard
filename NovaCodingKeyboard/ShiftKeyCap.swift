//
//  ShiftKeyCap.swift
//  NovaCodingKeyboard
//
//  Created by Nova on 3/1/26.
//


import SwiftUI

struct ShiftKeyCap: View {
    let shiftState: ShiftState
    let width: CGFloat
    let height: CGFloat
    let customLabel: String?
    let onPressDown: @MainActor () -> Void
    let onTap: @MainActor () -> Void
    let onLongPressBegin: @MainActor () -> Void
    let onLongPressEnd: @MainActor () -> Void

    init(shiftState: ShiftState, width: CGFloat, height: CGFloat,
         label: String? = nil,
         onPressDown: @escaping @MainActor () -> Void,
         onTap: @escaping @MainActor () -> Void,
         onLongPressBegin: @escaping @MainActor () -> Void,
         onLongPressEnd: @escaping @MainActor () -> Void) {
        self.shiftState = shiftState
        self.width = width
        self.height = height
        self.customLabel = label
        self.onPressDown = onPressDown
        self.onTap = onTap
        self.onLongPressBegin = onLongPressBegin
        self.onLongPressEnd = onLongPressEnd
    }

    @State private var isPressed = false
    @State private var longPressTask: Task<Void, Never>? = nil
    @State private var didLongPress = false

    private let longPressThreshold: TimeInterval = 0.15

    private var label: String {
        if let customLabel { return customLabel }
        return shiftState == .locked ? "⇪" : "⇧"
    }

    private var backgroundColor: Color {
        let active = shiftState.isActive
        return Color(UIColor(dynamicProvider: { t in
            if t.userInterfaceStyle == .dark {
                return active ? UIColor(white: 0.55, alpha: 1) : UIColor(white: 0.38, alpha: 1)
            } else {
                return active ? UIColor(white: 0.50, alpha: 1) : UIColor(white: 0.72, alpha: 1)
            }
        }))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            Text(label)
                .font(customLabel != nil
                      ? .system(size: 13, weight: .medium)
                      : .system(size: 24, weight: .regular))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(shiftState.isActive ? Color.white : Color.primary)
        }
        .frame(width: width, height: height)
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(.easeInOut(duration: 0.08), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    didLongPress = false
                    onPressDown()
                    // Schedule long-press activation
                    longPressTask = Task {
                        try? await Task.sleep(for: .seconds(longPressThreshold))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            didLongPress = true
                            onLongPressBegin()
                        }
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    longPressTask?.cancel()
                    longPressTask = nil
                    if didLongPress {
                        onLongPressEnd()
                    } else {
                        onTap()
                    }
                    didLongPress = false
                }
        )
    }
}
