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
    /// Called whenever a key is tapped. The caller decides what to do with the event.
    let onAction: @MainActor (KeyEvent) -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Shift, Control and Option all run the same latch. Control and Option are only on
    // screen in terminal mode, but they are kept here unconditionally so that toggling
    // the mode never strands a latch in the on state with no key left to turn it off.
    @State private var shift = ModifierLatch()
    @State private var control = ModifierLatch()
    @State private var option = ModifierLatch()

    /// Persisted in this process's own `UserDefaults` — see `TerminalMode.defaultsKey`
    /// for why it is deliberately not an App Group.
    @AppStorage(TerminalMode.defaultsKey) private var terminalMode = false

    // Portrait constants
    private let keyHeight: CGFloat = 44
    private let shortKeyHeight: CGFloat = 34
    private let gap: CGFloat = 6
    private let rowSpacing: CGFloat = 8
    /// Visible margin from the screen edge to the outermost key. Kept tight so the keys
    /// get the width instead; must stay >= gap/2, since the container padding is this
    /// minus the half-gap the edge keys already carry.
    private let sidePadding: CGFloat = 4

    // Landscape constants
    private let lSidePadding: CGFloat = 4

    /// Horizontal separation between keys in the wide layout. Wider on an iPad for the
    /// same reason the rows are taller there: a 5pt channel between two 91pt caps reads as
    /// no channel at all, and the keys run together into a solid block. On an iPhone in
    /// landscape the caps are a third of that width and 5pt is already visible.
    private var lGap: CGFloat { isVerticallyCompact ? 5 : 8 }

    /// True on iPhone in landscape, false on iPad in either orientation. The 14.5-column
    /// layout is shared by both, but their vertical budgets are not remotely alike: at
    /// 42pt rows this keyboard covers 63% of an iPhone landscape screen and only 30% of
    /// an iPad's, so the row metrics have to bend where the screen is short.
    private var isVerticallyCompact: Bool { verticalSizeClass == .compact }

    /// Two different problems, so two different numbers.
    ///
    /// On an iPhone in landscape the constraint is the screen: at 34pt rows the keyboard
    /// already takes half of it, and every point added comes straight out of whatever the
    /// user is typing into.
    ///
    /// An iPad has no such shortage, and the earlier 42pt row — picked to match the system
    /// keyboard's ~40.5pt density — turned out to be the wrong thing to match. Density is
    /// an iPhone concern. On an iPad the keys are already wide (about 91pt per unit on a
    /// 13" in landscape), so a 42pt row made every cap a letterbox and left the whole
    /// keyboard shorter than the system's own. 63pt brings the total to 373pt, in line
    /// with what iPadOS puts on screen, and gives the caps a shape closer to square.
    private var lKeyHeight: CGFloat { isVerticallyCompact ? 34 : 63 }
    private var lRowSpacing: CGFloat { isVerticallyCompact ? 5 : 10.5 }

    private var isShifted: Bool { shift.isActive }

    // Handed to the keys that are not built by KeyboardRow — the modifier caps and the
    // globe — so their touch area matches a KeyCap's exactly. These used to receive the
    // same padding from the call site, but applied there it lands outside their gesture
    // and the strip between keys goes dead.
    private var portraitHitInsets: EdgeInsets {
        EdgeInsets(top: rowSpacing / 2, leading: gap / 2, bottom: rowSpacing / 2, trailing: gap / 2)
    }

    private var landscapeHitInsets: EdgeInsets {
        EdgeInsets(top: lRowSpacing / 2, leading: lGap / 2, bottom: lRowSpacing / 2, trailing: lGap / 2)
    }

    /// The same width arithmetic `KeyButton` applies to a `KeyDef`, for the keys that are
    /// rendered outside a `KeyboardRow` and so have to size themselves.
    private func width(units: CGFloat, unit: CGFloat, gap: CGFloat) -> CGFloat {
        unit * units + gap * (units - 1)
    }

    /// A gap the exact size of the key that would otherwise be there. Wider than `width`
    /// by one gap, because a key's footprint in a row includes the hit padding it carries
    /// on either side.
    private func blankSlot(units: CGFloat, unit: CGFloat, gap: CGFloat, height: CGFloat) -> some View {
        Color.clear.frame(width: width(units: units, unit: unit, gap: gap) + gap, height: height)
    }

    // Both totals count one full rowSpacing *per row*, not per gap between rows: every
    // key carries rowSpacing/2 of hit padding above and below it, so a row occupies its
    // key height plus a whole rowSpacing. Counting gaps instead left the declared height
    // short of the content, which squeezes the bottom row.

    /// Portrait: 4 full-height rows (QWERTY, ASDF, ZXCV, bottom) + 2 short rows + top
    /// inset — 300pt. Terminal mode scrolls Row 0 rather than adding a row, so this is
    /// the height in both modes.
    private var portraitHeight: CGFloat {
        keyHeight * 4 + shortKeyHeight * 2 + rowSpacing * 6 + 8
    }

    /// Landscape: 5 rows + top inset. Terminal mode pays for its extra keys within the
    /// rows it already has, so the keyboard is the same height in both modes.
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
            // Only the wide layout on a tall screen — an iPad. The phone layouts keep the
            // sizes in `KeyboardFont` as written, which is what they were tuned against.
            .environment(\.keyFontScale, landscape && !isVerticallyCompact ? 1.2 : 1)
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
        let unitWidth = (totalWidth - (portraitTotalCols - 1) * gap) / portraitTotalCols
        let halfUnit = (unitWidth + gap) / 2
        let shiftKeyWidth = width(units: 1.5, unit: unitWidth, gap: gap)

        VStack(alignment: .leading, spacing: 0) {
            portraitRow0(unitWidth: unitWidth)
            KeyboardRow(keys: buildRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            KeyboardRow(keys: buildRow2(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            // No .padding here: the half-key inset is handed to A and L as hit area
            // instead, which places them identically but leaves no dead strip.
            KeyboardRow(keys: buildRow3(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing, edgeHitPadding: halfUnit)
            HStack(spacing: 0) {
                ShiftKeyCap(
                    shiftState: shift.state,
                    width: shiftKeyWidth,
                    height: keyHeight,
                    hitPadding: portraitHitInsets,
                    onPressDown: { play(shift.pressDown()) },
                    onRelease: { play(shift.release()); onAction(event(.shift)) }
                )
                KeyboardRow(keys: buildRow4Body(shifted: isShifted), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            }
            HStack(spacing: 0) {
                if showsGlobeKey {
                    GlobeKeyButton(width: unitWidth, height: keyHeight, hitPadding: portraitHitInsets)
                }
                // Same Ctrl / Term / Opt order as landscape, on the three slots `\`, `/`
                // and `` ` `` gave up when they moved to the scrolling row above.
                if terminalMode {
                    ShiftKeyCap(
                        shiftState: control.state,
                        width: unitWidth,
                        height: keyHeight,
                        label: "Ctrl",
                        accessibilityName: "Control",
                        hitPadding: portraitHitInsets,
                        onPressDown: { play(control.pressDown()) },
                        onRelease: { play(control.release()); onAction(event(.control)) }
                    )
                } else {
                    // Control's slot, filled by the hide key rather than held open: normal
                    // mode has no Control to put here, and hide has no row of its own to
                    // go back to. Term still keeps its column in both modes, which is the
                    // only thing the slot was ever reserved for.
                    KeyButton(key: hideKey(), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: { handle($0) }, rowSpacing: rowSpacing)
                }
                ShiftKeyCap(
                    shiftState: terminalMode ? .locked : .off,
                    width: unitWidth,
                    height: keyHeight,
                    label: "Term",
                    accessibilityName: "Terminal mode",
                    hitPadding: portraitHitInsets,
                    onPressDown: { handle(.toggleTerminalMode) },
                    onRelease: {}
                )
                if terminalMode {
                    ShiftKeyCap(
                        shiftState: option.state,
                        width: unitWidth,
                        height: keyHeight,
                        label: "Opt",
                        accessibilityName: "Option",
                        hitPadding: portraitHitInsets,
                        onPressDown: { play(option.pressDown()) },
                        onRelease: { play(option.release()); onAction(event(.option)) }
                    )
                }
                // Whatever the keys to the left of the space bar do not use goes to the
                // space bar, so the row always totals 10 units.
                KeyboardRow(keys: buildRow5Body(shifted: isShifted, spaceUnits: portraitSpaceUnits), unitWidth: unitWidth, keyHeight: keyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
            }
        }
        .padding(.top, 8)
        // Reduced by half a gap because the outermost keys already carry gap/2 of hit
        // padding on their outer edge. Padding by the full sidePadding made every row
        // exactly one gap wider than its container, and .leading alignment dumped that
        // overflow on the right — an 11pt left margin against a 5pt right one.
        .padding(.horizontal, sidePadding - gap / 2)
    }

    /// Row 0 is the only portrait row whose contents outgrow the ten columns. It scrolls
    /// sideways rather than spilling into a row of its own, so that both modes keep the
    /// same six rows on the same grid and the keyboard does not change height when the
    /// mode is toggled. Nothing is pinned: the mode switch is the `Term` key on the bottom
    /// row, which is on screen in both modes, so no key here has to stay reachable.
    @ViewBuilder
    private func portraitRow0(unitWidth: CGFloat) -> some View {
        if terminalMode {
            ScrollView(.horizontal) {
                KeyboardRow(keys: buildRow0Body(shifted: isShifted, terminal: true), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing, scrollSafe: true)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        } else {
            // Normal mode fits on one screen once squeezed, so it stays an ordinary row —
            // scrolling it would cost every key its press-down firing for nothing.
            KeyboardRow(keys: buildRow0Body(shifted: isShifted), unitWidth: unitWidth, keyHeight: shortKeyHeight, gap: gap, onTap: handle, rowSpacing: rowSpacing)
        }
    }

    /// Bottom row: 🌐(1) [·|Ctrl](1) Term(1) [Opt(1)] then the body. Only Option's slot
    /// comes and goes — Control's is held open — so the space bar is the single unit wider
    /// in normal mode.
    private var portraitSpaceUnits: CGFloat {
        let base: CGFloat = terminalMode ? 2.5 : 3.5
        return showsGlobeKey ? base : base + 1.0
    }

    // MARK: - Landscape Layout (Mac-like, 5 rows)

    @ViewBuilder
    private func landscapeBody(geo: GeometryProxy) -> some View {
        let totalWidth = geo.size.width - lSidePadding * 2
        let unitWidth = (totalWidth - (landscapeTotalCols - 1) * lGap) / landscapeTotalCols
        // See the note on `landscapeTotalCols`: terminal mode pays for its extra keys out
        // of the row they land on, never out of the grid.
        let shiftKeyWidth = width(units: 2.25, unit: unitWidth, gap: lGap)
        // The right Shift alone shrinks, handing its unit to the ↑ beside it.
        let rightShiftWidth = width(units: terminalMode ? 1.25 : 2.25, unit: unitWidth, gap: lGap)
        let capsLockWidth = width(units: 2.0, unit: unitWidth, gap: lGap)
        let bottomModifierWidth = width(units: 1.5, unit: unitWidth, gap: lGap)
        // Globe and Option are the narrow pair on the bottom row: one is a single glyph
        // and the other a three-letter label, and neither needs the width Ctrl and Term do.
        let narrowModifierWidth = width(units: 1.0, unit: unitWidth, gap: lGap)

        VStack(alignment: .leading, spacing: 0) {
            // Row 0: ` 1-0 - = ⌫, which fits exactly — plus, in terminal mode, Esc ahead
            // of it and the navigation and function keys behind, which do not. It scrolls
            // only in the mode that overflows: made to scroll unconditionally, the number
            // keys would give up firing on press-down for nothing (see `KeyCap.scrollSafe`).
            if terminalMode {
                ScrollView(.horizontal) {
                    KeyboardRow(keys: buildLandscapeRow0(shifted: isShifted, terminal: true), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing, scrollSafe: true)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            } else {
                KeyboardRow(keys: buildLandscapeRow0(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
            }
            // Row 1: ⇥ QWERTYUIOP [ ] backslash
            KeyboardRow(keys: buildLandscapeRow1(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
            // Row 2: caps ASDFGHJKL ; ' ↵
            HStack(spacing: 0) {
                ShiftKeyCap(
                    shiftState: shift.state,
                    width: capsLockWidth,
                    height: lKeyHeight,
                    label: "Caps",
                    accessibilityName: "Caps lock",
                    hitPadding: landscapeHitInsets,
                    onPressDown: { play(shift.pressDown()) },
                    onRelease: { play(shift.release()); onAction(event(.shift)) }
                )
                KeyboardRow(keys: buildLandscapeRow2Body(shifted: isShifted), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
            }
            // Row 3: ⇧ ZXCVBNM , . / [↑] ⇧
            HStack(spacing: 0) {
                ShiftKeyCap(
                    shiftState: shift.state,
                    width: shiftKeyWidth,
                    height: lKeyHeight,
                    hitPadding: landscapeHitInsets,
                    onPressDown: { play(shift.pressDown()) },
                    onRelease: { play(shift.release()); onAction(event(.shift)) }
                )
                KeyboardRow(keys: buildLandscapeRow3Body(shifted: isShifted, terminal: terminalMode), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
                ShiftKeyCap(
                    shiftState: shift.state,
                    width: rightShiftWidth,
                    height: lKeyHeight,
                    hitPadding: landscapeHitInsets,
                    onPressDown: { play(shift.pressDown()) },
                    onRelease: { play(shift.release()); onAction(event(.shift)) }
                )
            }
            // Row 4: 🌐 term [ctrl opt] ␣ cursor keys hide
            HStack(spacing: 0) {
                if showsGlobeKey {
                    GlobeKeyButton(width: narrowModifierWidth, height: lKeyHeight, hitPadding: landscapeHitInsets, symbolPointSize: 17)
                }
                if terminalMode {
                    ShiftKeyCap(
                        shiftState: control.state,
                        width: bottomModifierWidth,
                        height: lKeyHeight,
                        label: "Ctrl",
                        accessibilityName: "Control",
                        hitPadding: landscapeHitInsets,
                        onPressDown: { play(control.pressDown()) },
                        onRelease: { play(control.release()); onAction(event(.control)) }
                    )
                } else {
                    // Control's slot, held open. Term sits between Control and Option in
                    // both modes, and closing this gap when the mode is off would slide
                    // Term a key and a half to the left every time it was toggled — the
                    // one key guaranteed to be pressed again next is the worst one to move.
                    blankSlot(units: 1.5, unit: unitWidth, gap: lGap, height: lKeyHeight)
                }
                // Highlighted like a locked Shift when the mode is on, which is the only
                // thing marking terminal mode in landscape — the layout change is too
                // subtle on its own.
                ShiftKeyCap(
                    shiftState: terminalMode ? .locked : .off,
                    width: bottomModifierWidth,
                    height: lKeyHeight,
                    label: "Term",
                    accessibilityName: "Terminal mode",
                    hitPadding: landscapeHitInsets,
                    onPressDown: { handle(.toggleTerminalMode) },
                    onRelease: {}
                )
                if terminalMode {
                    ShiftKeyCap(
                        shiftState: option.state,
                        width: narrowModifierWidth,
                        height: lKeyHeight,
                        label: "Opt",
                        accessibilityName: "Option",
                        hitPadding: landscapeHitInsets,
                        onPressDown: { play(option.pressDown()) },
                        onRelease: { play(option.release()); onAction(event(.option)) }
                    )
                }
                // Nothing holds Option's slot open: everything to the right of Term is
                // the space bar, which simply grows into it.
                KeyboardRow(keys: buildLandscapeRow4Body(shifted: isShifted, spaceUnits: landscapeSpaceUnits, terminal: terminalMode), unitWidth: unitWidth, keyHeight: lKeyHeight, gap: lGap, onTap: handle, rowSpacing: lRowSpacing)
            }
        }
        .padding(.top, 6)
        // Same half-gap correction as the portrait layout.
        .padding(.horizontal, lSidePadding - lGap / 2)
    }

    /// Bottom row: 🌐(1.5) term(1.5) [ctrl(1.5) opt(1.5)] then the body. Terminal mode
    /// spends four extra units on modifiers and cursor keys against one extra column.
    private var landscapeSpaceUnits: CGFloat {
        // 4.75, not the 5.0 that would fill the row, and that quarter unit is the whole
        // point: it is what puts ← at column 11.25 and so ↓ at 12.25, directly under the ↑
        // that Row 3 lands at 12.25. Row 3 fixes that column — ⇧(2.25) + ZXCVBNM + `,./`
        // — and cannot be adjusted to meet Row 4 instead, because widening the left Shift
        // would carry the whole letter block sideways with it.
        //
        // The quarter unit comes off the end of the row rather than out of a key: with ↓
        // pinned at 12.25 and every arrow a square 1.0, → ends at 14.25 and the last
        // quarter of the row is simply empty. Spending it on a wider → would close the gap
        // at the cost of the cluster no longer being three keys of the same size.
        //
        // Normal mode has no ↑ to line up with, so it fills its row exactly.
        let base: CGFloat = terminalMode ? 4.75 : 7.0
        return showsGlobeKey ? base : base + 1.0
    }

    // MARK: - Modifier plumbing

    /// Haptics live here rather than in `ModifierLatch` so the latch stays pure logic.
    /// They are a no-op inside the extension anyway — see the note in `KeyCap`.
    private func play(_ feedback: ModifierLatch.Feedback?) {
        switch feedback {
        case .light:  UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case nil:     break
        }
    }

    private var activeModifiers: KeyModifiers {
        var modifiers = KeyModifiers()
        if shift.isActive { modifiers.insert(.shift) }
        if control.isActive { modifiers.insert(.control) }
        if option.isActive { modifiers.insert(.option) }
        return modifiers
    }

    private func event(_ action: KeyAction) -> KeyEvent {
        KeyEvent(action: action, modifiers: activeModifiers, isTerminalMode: terminalMode)
    }

    // MARK: - General key handler

    private func handle(_ action: KeyAction) {
        switch action {
        case .shift, .control, .option:
            // Owned by the latches, which report press and release directly.
            return
        case .toggleTerminalMode:
            terminalMode.toggle()
            return
        default:
            break
        }
        // Snapshot before the one-shot latches are spent: ⌃ has to travel with the C it
        // was pressed for, not with whatever comes after.
        let pressed = event(action)
        shift.noteKeyPress()
        control.noteKeyPress()
        option.noteKeyPress()
        onAction(pressed)
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
