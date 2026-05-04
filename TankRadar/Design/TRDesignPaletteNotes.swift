import Foundation

/// Dokumentation zu semantischen Farben (Linear **TAN-74**).
///
/// Implementierung: `Design/TRDesignAssets.xcassets`. Xcode generiert SwiftUI-Symbole
/// (z. B. `Color.trAccent`, `Image(.brandGlyph)`).
///
/// DESIGN-3.md ist im Repo nicht vorhanden; diese Hex-Werte definieren die erste TankRadar-Palette (Teal/Navy).
///
/// **Light / Dark**
/// - TRAccent — `#2EC4B6` / `#48E0D1`
/// - TRAccentMuted — `#248F85` / `#2EC4B6`
/// - TRBackground — `#F5F7FA` / `#0B1F33`
/// - TRBackgroundSecondary — `#FFFFFF` / `#142A42`
/// - TRBackgroundTertiary — `#E8ECF2` / `#1E354D`
/// - TRLabelPrimary — `#0B1F33` / `#F5F7FA`
/// - TRLabelSecondary — `#5C6B7A` / `#A8B4C0`
/// - TRLabelTertiary — `#8E9AA5` / `#7A8794`
/// - TRSeparator — `#D1D9E0` / `#2A3F56`
/// - TRDanger — `#D92D20` / `#FF6B5E`
/// - TRSuccess — `#1F8A55` / `#3CCC88`
///
/// **Kontrast (geschätzt, sRGB)**
/// - TRLabelPrimary auf TRBackground: ca. 15.5:1 (Light und Dark).
/// - TRLabelSecondary auf TRBackground (Light): ca. 5.1:1 (≥ AA für Fließtext).
/// - TRAccent auf TRBackground (Light): ca. 2:1 — nicht für kleinen Text allein; Akzent für Buttons/Grafiken.
enum TRDesignPaletteNotes {
    static let assetCatalogName = "TRDesignAssets"
}
