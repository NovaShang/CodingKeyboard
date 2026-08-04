import SwiftUI

/// The keyboard's typeface, in one place.
///
/// Every key label goes through here — the characters, both halves of a dual-label
/// symbol key, and the modifier glyphs (⇧ ⌫ ↵ ⇥ caps) — so trying a different font is a
/// one-line change to `design` rather than a hunt through the views.
///
/// The keyboard used to mix two typefaces: character keys were `.monospaced` while the
/// modifier glyphs quietly fell back to `.default`. They are unified now. If you decide
/// you want that contrast back deliberately, split `design` into two constants here
/// instead of editing the call sites again.
enum KeyboardFont {

    /// The switch.
    ///
    /// - `.rounded`     — SF Rounded: softer and fuller, distinct from the system keyboard.
    /// - `.monospaced`  — SF Mono: strongest separation between 0/O and 1/l/I.
    /// - `.default`     — SF Pro: exactly what the system keyboard uses.
    /// - `.serif`       — New York.
    static let design: Font.Design = .rounded

    // Point sizes. Gathered here because the modifier glyphs are drawn by two different
    // views — ShiftKeyCap renders its own ⇧ while KeyCap draws ⌫ ↵ ⇥ — and nothing else
    // would keep the two in step.

    /// Letters, digits, and single-label symbols.
    static let characterSize: CGFloat = 19
    /// Modifier glyphs: ⇧ ⌫ ↵ ⇥. Deliberately above `characterSize` — these read as icons
    /// rather than text and want the extra presence.
    static let modifierSize: CGFloat = 24
    /// Modifier keys labelled with a word rather than a glyph: caps, esc, ctrl, opt,
    /// term, home, end. `modifierSize` is tuned for single glyphs, and four letters at
    /// that size only fit by being auto-shrunk to whatever the key happens to allow,
    /// which makes no two of these keys agree on their text size.
    static let wordSize: CGFloat = 13
    /// SF Symbol keys, currently just the dismiss-keyboard icon. Set below the text
    /// glyphs because a symbol fills its bounding box far more solidly than a character
    /// does, so an equal point size renders as a noticeably heavier key. Not a `design`
    /// matter — SF Symbols ignore the typeface.
    static let symbolSize: CGFloat = 16

    /// A key label at the given size and weight, in whatever `design` is set to.
    static func label(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: design)
    }
}

// MARK: - Per-layout scaling

/// How much to enlarge every size above, set once by `CodingKeyboardView` and read by the
/// two views that draw labels.
///
/// The sizes are tuned for a phone, where a key is about as wide as it is tall. An iPad
/// key is not: at 14.5 columns across a 13" screen a unit is roughly 91pt wide against a
/// 63pt row, so a 19pt character sits in the middle of a cap with room to spare and reads
/// as undersized. Scaling here rather than at the call sites keeps the ratios between
/// characters, glyphs and words intact — they were chosen relative to each other, and
/// only the whole set should move.
///
/// Deliberately an environment value rather than an idiom check inside `KeyboardFont`:
/// the layout itself is chosen on available width, so that an iPad in Slide Over gets the
/// phone layout. Type has to follow the same rule or a 320pt-wide iPad would draw large
/// labels on small keys.
private struct KeyFontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var keyFontScale: CGFloat {
        get { self[KeyFontScaleKey.self] }
        set { self[KeyFontScaleKey.self] = newValue }
    }
}
