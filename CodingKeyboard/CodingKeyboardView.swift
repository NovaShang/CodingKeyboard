import SwiftUI

private struct KeyboardHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CodingKeyboardView: View {
    /// Whether to draw our own globe key. False where the system already provides one
    /// below the keyboard, in which case the freed slot goes to the space bar rather
    /// than being left as a gap. Driven by `needsInputModeSwitchKey` in the host
    /// controller — never by a device-model check.
    var showsGlobeKey: Bool = true
    /// Called whenever a key is tapped. The caller decides what to do with the action.
    let onAction: @MainActor (KeyAction) -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var shiftState: ShiftState = .off
    /// Timestamp of the last shift finger-lift, used to detect double-tap on the next press-down.
    @State private var lastShiftReleaseTime: Date = .distantPast
    /// Set to true when a double-tap is detected on press-down, so the following lift is ignored.
    @State private var shiftPressWasDoubleTap = false
    /// True while a finger is resting on a Shift key.
    @State private var isShiftHeld = false
    /// When the current Shift press began, used to tell a tap from a deliberate hold.
    @State private var shiftPressTime: Date = .distantPast
    /// Shift's state before the current press, used to resolve a tap into a toggle.
    @State private var shiftStateBeforePress: ShiftState = .off
    /// Whether any key was pressed while Shift was being held down.
    @State private var didTypeWhileShiftHeld = false

    private let shiftDoubleTapWindow: TimeInterval = 0.3
    /// Above this, a press with nothing typed reads as an abandoned hold rather than a tap.
    private let shiftHoldThreshold: TimeInterval = 0.5

    // Portrait constants
    private let keyHeight: CGFloat = 44
    private let shortKeyHeight: CGFloat = 34
    private let gap: CGFloat = 6
    private let totalCols: CGFloat = 10
    private let rowSpacing: CGFloat = 8
    /// Visible margin from the screen edge to the outermost key. Kept tight so the keys
    /// get the width instead; must stay >= gap/2, since the container padding is this
    /// minus the half-gap the edge keys already carry.
    private let sidePadding: CGFloat = 4

    // Landscape constants
    private let lGap: CGFloat = 5
    private let lSidePadding: CGFloat = 4

    /// True on iPhone in landscape, false on iPad in either orientation. The 14.5-column
    /// layout is shared by both, but their vertical budgets are not remotely alike: at
    /// 42pt rows this keyboard covers 63% of an iPhone landscape screen and only 30% of
    /// an iPad's, so the row metrics have to bend where the screen is short.
    private var isVerticallyCompact: Bool { verticalSizeClass == .compact }

    /// Sized so a row occupies about 39.6pt including spacing, against the system
    /// keyboard's ~40.5pt (162pt over 4 rows). The total still exceeds the system's
    /// because this layout has five rows, not four — the density matches, the row
    /// count is the deliberate difference.
    private var lKeyHeight: CGFloat { isVerticallyCompact ? 34 : 42 }
    private var lRowSpacing: CGFloat { isVerticallyCompact ? 5 : 7 }

    private var isShifted: Bool { shiftState.isActive }

    // Handed to the keys that are not built by KeyboardRow — Shift and the globe — so
    // their touch area matches a KeyCap's exactly. These two used to receive the same
    // padding from the call site, but applied there it lands outside their gesture and
    // the strip between keys goes dead.
    private var portraitHitInsets: EdgeInsets {
        EdgeInsets(top: rowSpacing / 2, leading: gap / 2, bottom: rowSpacing / 2, trailing: gap / 2)
    }

    private var landscapeHitInsets: EdgeInsets {
        EdgeInsets(top: lRowSpacing / 2, leading: lGap / 2, bottom: lRowSpacing / 2, trailing: lGap / 2)
    }

    // Both totals count one full rowSpacing *per row*, not per gap between rows: every
    // key carries rowSpacing/2 of hit padding above and below it, so a row occupies its
    // key height plus a whole rowSpacing. Counting gaps instead left the declared height
    // short of the content, which squeezes the bottom row.

    /// Portrait: 4 full-height rows (QWERTY, ASDF, ZXCV, bottom) + 2 short rows + top inset.
    private var portraitHeight: CGFloat {
        keyHeight * 4 + shortKeyHeight * 2 + rowSpacing * 6 + 8
    }

    /// Landscape: 5 rows + top inset.
    private var landscapeHeight: CGFloat {
        lKeyHeight * 5 + lRowSpacing * 5 + 6
    }

    @State private var currentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            // Chosen purely on available width, never on device idiom: an iPad in
            // Slide Over or a narrow split is only ~320pt wide, and forcing the
            // 14.5-column layout there shrinks every key to about 17pt.
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

        VStack(alignment: .leading, spacing: 0) {
            KeyboardRow(keys: buildRow0(shifted: isShifted), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            KeyboardRow(keys: buildRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            KeyboardRow(keys: buildRow2(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            // No .padding here: the half-key inset is handed to A and L as hit area
            // instead, which places them identically but leaves no dead strip.
            KeyboardRow(keys: buildRow3(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing, edgeHitPadding: halfUnit)
            HStack(spacing: 0) {
                ShiftKeyCap(
                    shiftState: shiftState,
                    width: shiftKeyWidth,
                    height: keyHeight,
                    hitPadding: portraitHitInsets,
                    onPressDown: handleShiftPressDown,
                    onRelease: handleShiftRelease
                )
                KeyboardRow(keys: buildRow4Body(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            }
            HStack(spacing: 0) {
                if showsGlobeKey {
                    GlobeKeyButton(width: unitWidth, height: keyHeight, hitPadding: portraitHitInsets)
                }
                // Without the globe key the row is one unit short; it goes to the space bar.
                KeyboardRow(keys: buildRow5Body(shifted: isShifted, spaceUnits: showsGlobeKey ? 2.0 : 3.0), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            }
        }
        .padding(.top, 8)
        // Reduced by half a gap because the outermost keys already carry gap/2 of hit
        // padding on their outer edge. Padding by the full sidePadding made every row
        // exactly one gap wider than its container, and .leading alignment dumped that
        // overflow on the right — an 11pt left margin against a 5pt right one.
        .padding(.horizontal, sidePadding - gap / 2)
    }

    // MARK: - Landscape Layout (Mac-like, 5 rows)

    @ViewBuilder
    private func landscapeBody(geo: GeometryProxy) -> some View {
        let totalWidth = geo.size.width - lSidePadding * 2
        let unitWidth = (totalWidth - (landscapeTotalCols - 1) * lGap) / landscapeTotalCols
        let shiftKeyWidth = unitWidth * 2.25 + lGap * 1.25  // 2.25 units
        let capsLockWidth = unitWidth * 2.0 + lGap * 1.0   // 2.0 units

        VStack(alignment: .leading, spacing: 0) {
            // Row 0: ` 1-0 - = ⌫
            KeyboardRow(keys: buildLandscapeRow0(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
            // Row 1: ⇥ QWERTYUIOP [ ] backslash
            KeyboardRow(keys: buildLandscapeRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
            // Row 2: caps ASDFGHJKL ; ' ↵
            HStack(spacing: 0) {
                ShiftKeyCap(
                    shiftState: shiftState,
                    width: capsLockWidth,
                    height: lKeyHeight,
                    label: "caps",
                    hitPadding: landscapeHitInsets,
                    onPressDown: handleShiftPressDown,
                    onRelease: handleShiftRelease
                )
                KeyboardRow(keys: buildLandscapeRow2Body(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
            }
            // Row 3: ⇧ ZXCVBNM , . / ⇧
            HStack(spacing: 0) {
                ShiftKeyCap(
                    shiftState: shiftState,
                    width: shiftKeyWidth,
                    height: lKeyHeight,
                    hitPadding: landscapeHitInsets,
                    onPressDown: handleShiftPressDown,
                    onRelease: handleShiftRelease
                )
                KeyboardRow(keys: buildLandscapeRow3Body(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
                ShiftKeyCap(
                    shiftState: shiftState,
                    width: shiftKeyWidth,
                    height: lKeyHeight,
                    hitPadding: landscapeHitInsets,
                    onPressDown: handleShiftPressDown,
                    onRelease: handleShiftRelease
                )
            }
            // Row 4: 🌐 ↓ ␣ ↓
            HStack(spacing: 0) {
                if showsGlobeKey {
                    let globeWidth = unitWidth * 1.5 + lGap * 0.5
                    GlobeKeyButton(width: globeWidth, height: lKeyHeight, hitPadding: landscapeHitInsets)
                }
                // Without the globe key the row is 1.5 units short; they go to the space bar.
                KeyboardRow(keys: buildLandscapeRow4Body(shifted: isShifted, spaceUnits: showsGlobeKey ? 8.0 : 9.5), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
            }
        }
        .padding(.top, 6)
        // Same half-gap correction as the portrait layout.
        .padding(.horizontal, lSidePadding - lGap / 2)
    }

    // MARK: - Shift gesture handlers

    // Shift takes effect the moment the finger lands, never on lift and never after a
    // delay, so holding Shift with one thumb and typing with the other capitalizes from
    // the very first keystroke. What the press *meant* is resolved on release instead.
    private func handleShiftPressDown() {
        let timeSinceRelease = Date().timeIntervalSince(lastShiftReleaseTime)
        shiftStateBeforePress = shiftState
        shiftPressTime = Date()
        didTypeWhileShiftHeld = false
        isShiftHeld = true

        if timeSinceRelease < shiftDoubleTapWindow && shiftState == .on {
            // Second tap quickly after the first → lock
            shiftState = .locked
            shiftPressWasDoubleTap = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }
        shiftPressWasDoubleTap = false
        if shiftState == .off {
            shiftState = .momentary
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func handleShiftRelease() {
        defer {
            lastShiftReleaseTime = Date()
            isShiftHeld = false
        }
        // The lock was already applied on press-down; leave it alone.
        if shiftPressWasDoubleTap {
            shiftPressWasDoubleTap = false
            return
        }
        // Used as a held modifier — the capitals are already typed, so drop it.
        if didTypeWhileShiftHeld {
            shiftState = .off
            return
        }
        // Held deliberately but never used: treat as cancelled rather than leaving Shift
        // armed for a character the user never meant to capitalize.
        if Date().timeIntervalSince(shiftPressTime) >= shiftHoldThreshold {
            shiftState = .off
            return
        }
        // A plain tap: toggle relative to whatever Shift was before this press.
        switch shiftStateBeforePress {
        case .off:
            shiftState = .on
        case .on, .locked, .momentary:
            shiftState = .off
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onAction(.shift)
    }

    // MARK: - General key handler

    private func handle(_ action: KeyAction) {
        if case .shift = action { return }  // shift handled separately
        if isShiftHeld {
            didTypeWhileShiftHeld = true
        }
        // .on resets after one character; .momentary and .locked persist
        if shiftState == .on {
            shiftState = .off
        }
        onAction(action)
    }
}


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
