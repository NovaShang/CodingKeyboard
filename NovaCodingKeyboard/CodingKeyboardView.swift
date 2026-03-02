import SwiftUI

struct CodingKeyboardView: View {
    /// Called whenever a key is tapped. The caller decides what to do with the action.
    let onAction: @MainActor (KeyAction) -> Void

    @State private var shiftState: ShiftState = .off
    /// Timestamp of the last shift finger-lift, used to detect double-tap on the next press-down.
    @State private var lastShiftReleaseTime: Date = .distantPast
    /// Set to true when a double-tap is detected on press-down, so the following tap-up is ignored.
    @State private var shiftPressWasDoubleTap = false

    private let keyHeight: CGFloat = 44
    private let shortKeyHeight: CGFloat = 34
    private let gap: CGFloat = 6
    private let totalCols: CGFloat = 10
    private let rowSpacing: CGFloat = 8
    private let sidePadding: CGFloat = 8

    private var isShifted: Bool { shiftState.isActive }

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width - sidePadding * 2
            let unitWidth = (totalWidth - (totalCols - 1) * gap) / totalCols
            let halfUnit = (unitWidth + gap) / 2  // 0.5-unit indent for centering 9-key rows
            let shiftKeyWidth = unitWidth * 1.5 + gap * 0.5

            VStack(alignment: .leading, spacing: rowSpacing) {
                // Row 0: ⇥(2x) [ ] \ ` / ' ↓ — 9 units, right-aligned (1-unit gap on left)
                KeyboardRow(keys: buildRow0(shifted: isShifted), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle)
                // Row 1: numbers (10 keys, full width)
                KeyboardRow(keys: buildRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle)
                // Row 2: QWERTY (10 keys, full width)
                KeyboardRow(keys: buildRow2(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                // Row 3: ASDFGHJKL (9 keys, centered with 0.5-unit padding each side)
                KeyboardRow(keys: buildRow3(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                    .padding(.horizontal, halfUnit)
                // Row 4: Shift key rendered separately for custom gesture; rest via KeyboardRow
                HStack(spacing: gap) {
                    ShiftKeyCap(
                        shiftState: shiftState,
                        width: shiftKeyWidth,
                        height: keyHeight,
                        onPressDown: handleShiftPressDown,
                        onTap: handleShiftTap,
                        onLongPressBegin: handleShiftLongPressBegin,
                        onLongPressEnd: handleShiftLongPressEnd
                    )
                    KeyboardRow(keys: buildRow4Body(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                }
                // Row 5: , . - = Space(2x) ; ' / Enter (10 units, full width)
                KeyboardRow(keys: buildRow5(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
            }
            .padding(.top, 8)
            .padding(.horizontal, sidePadding)
        }
        .frame(height: keyHeight * 4 + shortKeyHeight * 2 + rowSpacing * 5 + 8)
    }

    // MARK: - Shift gesture handlers

    // Finger touched down: detect double-tap by comparing to the last release time.
    private func handleShiftPressDown() {
        let timeSinceRelease = Date().timeIntervalSince(lastShiftReleaseTime)
        if timeSinceRelease < 0.25 && shiftState == .on {
            // Second tap quickly after the first → lock
            shiftState = .locked
            shiftPressWasDoubleTap = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            shiftPressWasDoubleTap = false
        }
    }

    // Short press completed. If this was the second tap of a double-tap, it was already
    // handled on press-down, so we skip it here to avoid toggling the state back off.
    private func handleShiftTap() {
        defer { lastShiftReleaseTime = Date() }
        if shiftPressWasDoubleTap {
            shiftPressWasDoubleTap = false
            return
        }
        switch shiftState {
        case .off:
            shiftState = .on
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .on:
            shiftState = .off
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .momentary:
            shiftState = .off
        case .locked:
            shiftState = .off
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        onAction(.shift)
    }

    private func handleShiftLongPressBegin() {
        shiftState = .momentary
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func handleShiftLongPressEnd() {
        if shiftState == .momentary {
            shiftState = .off
        }
    }

    // MARK: - General key handler

    private func handle(_ action: KeyAction) {
        if case .shift = action { return }  // shift handled separately
        // .on resets after one character; .momentary and .locked persist
        if shiftState == .on {
            shiftState = .off
        }
        onAction(action)
    }
}

// MARK: - ShiftKeyCap
// Renders the Shift key and dispatches three gesture events to the parent:
//   onPressDown   — finger touched down (used for double-tap detection)
//   onTap         — short press completed (< 300ms)
//   onLongPressBegin / onLongPressEnd — hold ≥ 300ms / finger lifted
//
// Uses a single DragGesture(minimumDistance: 0) for the full down→up lifecycle,
// with a cancellable async Task for the long-press threshold. This avoids the
// SwiftUI issue where LongPressGesture cancels DragGesture and prevents onEnded.

private struct ShiftKeyCap: View {
    let shiftState: ShiftState
    let width: CGFloat
    let height: CGFloat
    let onPressDown: @MainActor () -> Void
    let onTap: @MainActor () -> Void
    let onLongPressBegin: @MainActor () -> Void
    let onLongPressEnd: @MainActor () -> Void

    @State private var isPressed = false
    @State private var longPressTask: Task<Void, Never>? = nil
    @State private var didLongPress = false

    private let longPressThreshold: TimeInterval = 0.15

    private var label: String {
        shiftState == .locked ? "⇪" : "⇧"
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
                .font(.system(size: 24, weight: .regular, design: .default))
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

#Preview {
    CodingKeyboardView(onAction: { _ in })
        .background(alignment: .bottom) {
            Color(UIColor.systemGray6).ignoresSafeArea(edges: .bottom)
        }
        .safeAreaPadding(.bottom, 34)
}
