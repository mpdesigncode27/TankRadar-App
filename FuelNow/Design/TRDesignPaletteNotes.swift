import Foundation

/// Dokumentation zu semantischen Farben (Linear **TAN-74**) und Token-Schicht (**TAN-75**).
///
/// **Rendering:** `Design/TRDesignAssets.xcassets` — Xcode generiert `Color.tr*` / `Image(.brandGlyph)`.
/// **App-Zugriff:** `TRColors` statt Roh-Hex in Feature-Views.
///
/// **Light-Referenz-Hex** (Regressionstests: `TRPaletteHex`): Teal/Navy-Palette; Dark-Varianten nur im Asset-Katalog.
///
/// **Kontrast (geschätzt, sRGB):** Label Primary auf Background ~15.5:1; Secondary ~5.1:1 (Light);
/// Accent auf Background ~2:1 — nicht für kleinen Fließtext allein.
///
/// **SwiftLint (optional):** Custom Rule „kein `#RRGGBB` außerhalb `FuelNow/Design/`“ — bei Bedarf im Team-Repo ergänzen.
enum TRDesignPaletteNotes {
    static let assetCatalogName = "TRDesignAssets"
}
