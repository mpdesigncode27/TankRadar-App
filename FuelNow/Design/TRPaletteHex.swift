import Foundation

/// Referenz-Hexstrings (**ohne** `#`) für die **Light**-Variante der semantischen Farben.
/// Müssen mit `TRDesignAssets.xcassets` und `TRDesignPaletteNotes` übereinstimmen.
///
/// Dient Regressionstests (u. a. `TRColorPaletteTests`, `TRColorContrastAAATests` für TAN-80);
/// Rendering erfolgt ausschließlich über den Asset-Katalog.
enum TRPaletteHex {
    static let accent = "2EC4B6"
    static let accentMuted = "248F85"
    /// AAA-konforme Accent-Variante für **Text** und Buttons mit weißer Schrift im Light-Mode.
    /// 7.93:1 auf `background` (#F5F7FA) und 8.51:1 mit weißer Schrift (TAN-80).
    static let accentText = "0F5650"
    static let background = "F5F7FA"
    static let backgroundSecondary = "FFFFFF"
    static let backgroundTertiary = "E8ECF2"
    static let labelPrimary = "0B1F33"
    /// AAA: 9.32:1 auf `background` (TAN-80, war zuvor `5C6B7A`/5.10:1).
    static let labelSecondary = "3A4350"
    /// AAA: 7.34:1 auf `background` (TAN-80, war zuvor `8E9AA5`/2.67:1).
    static let labelTertiary = "4A5260"
    /// AA non-text floor ≥ 3:1 (TAN-80, Light 3.34:1 / Dark 3.75:1).
    static let separator = "7C8993"
    /// AAA-Text 7.26:1 in Light (TAN-80).
    static let danger = "9F2018"
    /// AAA-Text 7.68:1 in Light (TAN-80).
    static let success = "065B30"
}
