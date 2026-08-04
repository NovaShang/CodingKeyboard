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
    /// The word "caps" on the landscape caps-lock key — a word, not a glyph.
    static let capsLockSize: CGFloat = 13
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
