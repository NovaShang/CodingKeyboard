import SwiftUI

private struct KeyboardHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CodingKeyboardView: View {
    /// Called whenever a key is tapped. The caller decides what to do with the action.
    let onAction: @MainActor (KeyAction) -> Void

    @State private var shiftState: ShiftState = .off
    /// Timestamp of the last shift finger-lift, used to detect double-tap on the next press-down.
    @State private var lastShiftReleaseTime: Date = .distantPast
    /// Set to true when a double-tap is detected on press-down, so the following tap-up is ignored.
    @State private var shiftPressWasDoubleTap = false

    // Portrait constants
    private let keyHeight: CGFloat = 44
    private let shortKeyHeight: CGFloat = 34
    private let gap: CGFloat = 6
    private let totalCols: CGFloat = 10
    private let rowSpacing: CGFloat = 8
    private let sidePadding: CGFloat = 8

    // Landscape constants
    private let lKeyHeight: CGFloat = 40
    private let lGap: CGFloat = 5
    private let lRowSpacing: CGFloat = 6
    private let lSidePadding: CGFloat = 6

    private var isShifted: Bool { shiftState.isActive }

    /// Portrait total height: 4 full-height rows + 2 short rows + 5 row spacings + top padding
    private var portraitHeight: CGFloat {
        keyHeight * 4 + shortKeyHeight * 2 + rowSpacing * 5 + 8
    }

    /// Landscape total height: 5 rows + 4 row spacings + top padding
    private var landscapeHeight: CGFloat {
        lKeyHeight * 5 + lRowSpacing * 4 + 6
    }

    @State private var currentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > 500
            let targetHeight = landscape ? landscapeHeight : portraitHeight

            Group {
                if landscape {
                    landscapeBody(geo: geo)
                } else {
                    portraitBody(geo: geo)
                }
            }
            .preference(key: KeyboardHeightKey.self, value: targetHeight)
        }
        .frame(height: currentHeight > 0 ? currentHeight : portraitHeight)
        .onPreferenceChange(KeyboardHeightKey.self) { newHeight in
            currentHeight = newHeight
        }
    }

    // MARK: - Portrait Layout

    @ViewBuilder
    private func portraitBody(geo: GeometryProxy) -> some View {
        let totalWidth = geo.size.width - sidePadding * 2
        let unitWidth = (totalWidth - (totalCols - 1) * gap) / totalCols
        let halfUnit = (unitWidth + gap) / 2
        let shiftKeyWidth = unitWidth * 1.5 + gap * 0.5

        VStack(alignment: .leading, spacing: rowSpacing) {
            KeyboardRow(keys: buildRow0(shifted: isShifted), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle)
            KeyboardRow(keys: buildRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle)
            KeyboardRow(keys: buildRow2(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
            KeyboardRow(keys: buildRow3(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
                .padding(.horizontal, halfUnit)
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
            KeyboardRow(keys: buildRow5(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle)
        }
        .padding(.top, 8)
        .padding(.horizontal, sidePadding)
    }

    // MARK: - Landscape Layout (Mac-like, 5 rows)

    @ViewBuilder
    private func landscapeBody(geo: GeometryProxy) -> some View {
        let totalWidth = geo.size.width - lSidePadding * 2
        let unitWidth = (totalWidth - (landscapeTotalCols - 1) * lGap) / landscapeTotalCols
        let shiftKeyWidth = unitWidth * 2.25 + lGap * 1.25  // 2.25 units

        VStack(alignment: .leading, spacing: lRowSpacing) {
            // Row 0: ` 1-0 - = ⌫
            KeyboardRow(keys: buildLandscapeRow0(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle)
            // Row 1: ⇥ QWERTYUIOP [ ] backslash
            KeyboardRow(keys: buildLandscapeRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle)
            // Row 2: ☰ ASDFGHJKL ; ' ↵
            KeyboardRow(keys: buildLandscapeRow2(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle)
            // Row 3: ⇧ ZXCVBNM , . / ⇧
            HStack(spacing: lGap) {
                ShiftKeyCap(
                    shiftState: shiftState,
                    width: shiftKeyWidth,
                    height: lKeyHeight,
                    onPressDown: handleShiftPressDown,
                    onTap: handleShiftTap,
                    onLongPressBegin: handleShiftLongPressBegin,
                    onLongPressEnd: handleShiftLongPressEnd
                )
                KeyboardRow(keys: buildLandscapeRow3Body(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle)
                ShiftKeyCap(
                    shiftState: shiftState,
                    width: shiftKeyWidth,
                    height: lKeyHeight,
                    onPressDown: handleShiftPressDown,
                    onTap: handleShiftTap,
                    onLongPressBegin: handleShiftLongPressBegin,
                    onLongPressEnd: handleShiftLongPressEnd
                )
            }
            // Row 4: ↓ ␣ ↓
            KeyboardRow(keys: buildLandscapeRow4(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle)
        }
        .padding(.top, 6)
        .padding(.horizontal, lSidePadding)
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



#Preview("Portrait") {
    CodingKeyboardView(onAction: { _ in })
        .background(alignment: .bottom) {
            Color(UIColor.systemGray6).ignoresSafeArea(edges: .bottom)
        }
        .safeAreaPadding(.bottom, 34)
}

#Preview("Landscape (simulated)") {
    ScrollView(.horizontal) {
        CodingKeyboardView(onAction: { _ in })
            .frame(width: 750)
    }
    .background(Color(UIColor.systemGray6))
}
