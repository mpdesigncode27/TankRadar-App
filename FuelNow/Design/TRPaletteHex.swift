import Foundation

/// Referenz-Hexstrings (**ohne** `#`) für die **Light**-Variante der semantischen Farben.
/// Müssen mit `TRDesignAssets.xcassets` und `TRDesignPaletteNotes` übereinstimmen.
///
/// Dient Regressionstests; Rendering erfolgt ausschließlich über den Asset-Katalog.
enum TRPaletteHex {
    static let accent = "2EC4B6"
    static let accentMuted = "248F85"
    static let background = "F5F7FA"
    static let backgroundSecondary = "FFFFFF"
    static let backgroundTertiary = "E8ECF2"
    static let labelPrimary = "0B1F33"
    static let labelSecondary = "5C6B7A"
    static let labelTertiary = "8E9AA5"
    static let separator = "D1D9E0"
    static let danger = "D92D20"
    static let success = "1F8A55"
}
