import Foundation

/// Dokumentation zu semantischen Farben (Linear **TAN-74**) und Token-Schicht (**TAN-75**).
///
/// **Rendering:** `Design/TRDesignAssets.xcassets` — Xcode generiert `Color.tr*` / `Image(.brandGlyph)`.
/// **App-Zugriff:** `TRColors` statt Roh-Hex in Feature-Views.
///
/// **Light-Referenz-Hex** (Regressionstests: `TRPaletteHex`): Teal/Navy-Palette; Dark-Varianten nur im Asset-Katalog.
///
/// **WCAG 2.2 AAA — Kontraste (TAN-80):** Tokens für *Text* gegen die App-Backgrounds erfüllen
/// `SC 1.4.6 Contrast (Enhanced)` ≥ 7:1 (Light & Dark):
/// * Primary  ~15.5:1, Secondary ~9.3:1 (Light) / ~7.9:1 (Dark), Tertiary ~7.3:1.
/// * `success` / `danger` als Text-Tinten ≥ 7:1 in Light; in Dark Apple-typisch helle Varianten.
/// * `accent` (Brand-Teal `#2EC4B6`) bleibt **Surface/Tint/Glow** — NIE als kleiner Text auf hellem Background.
///   Für Text mit Accent-Charakter den Token **`accentText`** (`#0F5650` Light, `#7DE4D9` Dark) verwenden.
/// * `separator` ≥ 3:1 (`SC 1.4.11` Non-text floor).
///
/// **SwiftLint (optional):** Custom Rule „kein `#RRGGBB` außerhalb `FuelNow/Design/`“ — bei Bedarf im Team-Repo ergänzen.
enum TRDesignPaletteNotes {
    static let assetCatalogName = "TRDesignAssets"
}
