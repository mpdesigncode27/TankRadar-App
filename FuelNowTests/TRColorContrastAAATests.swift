import Foundation
import Testing
@testable import FuelNow

/// Regressions-Tests für **WCAG 2.2 AAA** (Linear TAN-80) — Schwerpunkt Farben & Kontraste.
///
/// Quellen:
/// * [W3C: Understanding SC 1.4.6 Contrast (Enhanced) AAA](https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced)
/// * [W3C: Understanding SC 1.4.11 Non-text Contrast AA](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast)
///
/// Die Tests rechnen ausschließlich auf den **Light-Mode-Hexwerten** in `TRPaletteHex`. Dark-Mode-Werte
/// werden ergänzend gegen ihren bekannten Hex geprüft. Dadurch entfällt die UIKit/SwiftUI-Abhängigkeit
/// und der Test ist deterministisch (keine UI-Pipeline notwendig).
struct TRColorContrastAAATests {

    // MARK: - Light Mode (Pflicht)

    /// `SC 1.4.6 Contrast (Enhanced)` — Text ≥ **7:1** auf den App-Backgrounds.
    @Test func aaaTextContrastLightOnBackground() throws {
        let bg = try sRGB(hex: TRPaletteHex.background)

        try expect(.ratio(at: 7.0), of: TRPaletteHex.labelPrimary,   on: bg, "labelPrimary on background")
        try expect(.ratio(at: 7.0), of: TRPaletteHex.labelSecondary, on: bg, "labelSecondary on background")
        try expect(.ratio(at: 7.0), of: TRPaletteHex.labelTertiary,  on: bg, "labelTertiary on background")
        try expect(.ratio(at: 7.0), of: TRPaletteHex.success,        on: bg, "success on background (text/glyph tint)")
        try expect(.ratio(at: 7.0), of: TRPaletteHex.danger,         on: bg, "danger on background (text/glyph tint)")
        try expect(.ratio(at: 7.0), of: TRPaletteHex.accentText,     on: bg, "accentText on background (Accent-Text/Buttons)")
    }

    /// Auch auf Karten (`backgroundSecondary` = weiß) müssen Text-Tokens AAA halten.
    @Test func aaaTextContrastLightOnCards() throws {
        let card = try sRGB(hex: TRPaletteHex.backgroundSecondary)
        try expect(.ratio(at: 7.0), of: TRPaletteHex.labelPrimary,   on: card, "labelPrimary on white card")
        try expect(.ratio(at: 7.0), of: TRPaletteHex.labelSecondary, on: card, "labelSecondary on white card")
        try expect(.ratio(at: 7.0), of: TRPaletteHex.labelTertiary,  on: card, "labelTertiary on white card")
        try expect(.ratio(at: 7.0), of: TRPaletteHex.accentText,     on: card, "accentText on white card")
    }

    /// `SC 1.4.6` für **Buttons mit weißer Schrift**: weiß auf `accentText` ≥ 7:1.
    @Test func aaaWhiteTextOnAccentTextSurface() throws {
        let surface = try sRGB(hex: TRPaletteHex.accentText)
        let white = SRGB(r: 1, g: 1, b: 1)
        let ratio = wcagContrast(white, surface)
        #expect(ratio >= 7.0, "white-on-accentText must be AAA (got \(ratio.rounded(toPlaces: 2)):1)")
    }

    /// `SC 1.4.11 Non-text Contrast AA` — Status-Punkte (success/danger) als reine Indikator-Surfaces.
    @Test func aaNonTextContrastForStatusDots() throws {
        let bg = try sRGB(hex: TRPaletteHex.background)
        try expect(.ratio(at: 3.0), of: TRPaletteHex.success, on: bg, "success dot on background (non-text 3:1)")
        try expect(.ratio(at: 3.0), of: TRPaletteHex.danger,  on: bg, "danger dot on background (non-text 3:1)")
    }

    /// `SC 1.4.11` — Separator als UI-Komponente.
    @Test func aaNonTextContrastForSeparator() throws {
        let bg = try sRGB(hex: TRPaletteHex.background)
        try expect(.ratio(at: 3.0), of: TRPaletteHex.separator, on: bg, "separator on background (non-text 3:1)")
    }

    /// **Bewusst dokumentiert** (TAN-80): Brand-Teal `accent` ist Surface/Tint/Glow und
    /// soll **nicht** als kleiner Text auf hellem Background stehen — der Kontrast bleibt < 3:1.
    /// Für Text-Verwendungen wird `accentText` benutzt.
    @Test func brandAccentIsSurfaceOnlyAndDocumentedBelowAAA() throws {
        let bg = try sRGB(hex: TRPaletteHex.background)
        let accent = try sRGB(hex: TRPaletteHex.accent)
        let ratio = wcagContrast(accent, bg)
        #expect(ratio < 3.0, "brand accent purposely below 3:1 — verify accentText is used for text/glyphs")
    }

    // MARK: - Dark Mode (Pflicht — Hex auf Asset-Katalog-Werten)

    /// Dark-Mode-Hexwerte sind im Asset-Katalog hinterlegt, aber der Test referenziert sie hier
    /// als „bekannte Werte" — Drift wird unmittelbar sichtbar.
    @Test func aaaTextContrastDarkOnBackground() throws {
        let bg = SRGB(hex: "0B1F33")
        // Text-Tokens (Dark-Variante laut Asset-Katalog)
        try expect(.ratio(at: 7.0), of: "F5F7FA", on: bg, "labelPrimary Dark on bg")
        try expect(.ratio(at: 7.0), of: "A8B4C0", on: bg, "labelSecondary Dark on bg") // #A8B4C0 ≈ 0.659/0.706/0.753
        try expect(.ratio(at: 7.0), of: "A2ACB6", on: bg, "labelTertiary Dark on bg (TAN-80)")
        try expect(.ratio(at: 7.0), of: "7DE4D9", on: bg, "accentText Dark on bg (TAN-80)")
    }

    @Test func aaNonTextContrastDarkSeparator() throws {
        let bg = SRGB(hex: "0B1F33")
        try expect(.ratio(at: 3.0), of: "6B7989", on: bg, "separator Dark on bg (TAN-80)")
    }
}

// MARK: - WCAG helpers (sRGB → relative luminance → contrast)

/// Lineare RGB-Komponente (0...1) → relative Luminanz-Beitrag (vor Gewichtung).
/// WCAG-Formel: `c <= 0.03928 ? c/12.92 : ((c+0.055)/1.055)^2.4`.
private func linearize(_ c: Double) -> Double {
    c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
}

/// Relative Luminanz nach WCAG 2.x: `0.2126·R + 0.7152·G + 0.0722·B`.
private func relativeLuminance(_ color: SRGB) -> Double {
    0.2126 * linearize(color.r) + 0.7152 * linearize(color.g) + 0.0722 * linearize(color.b)
}

/// Kontrast `(L1+0.05)/(L2+0.05)` mit `L1` ≥ `L2`.
internal func wcagContrast(_ a: SRGB, _ b: SRGB) -> Double {
    let la = relativeLuminance(a)
    let lb = relativeLuminance(b)
    let l1 = max(la, lb)
    let l2 = min(la, lb)
    return (l1 + 0.05) / (l2 + 0.05)
}

internal struct SRGB {
    let r: Double
    let g: Double
    let b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.r = Double((value & 0xFF0000) >> 16) / 255.0
        self.g = Double((value & 0x00FF00) >> 8) / 255.0
        self.b = Double(value & 0x0000FF) / 255.0
    }
}

private func sRGB(hex: String) throws -> SRGB { SRGB(hex: hex) }

private enum AAAExpectation { case ratio(at: Double) }

private func expect(
    _ expectation: AAAExpectation,
    of foregroundHex: String,
    on background: SRGB,
    _ label: String,
    sourceLocation: SourceLocation = #_sourceLocation
) throws {
    let fg = SRGB(hex: foregroundHex)
    let ratio = wcagContrast(fg, background)
    switch expectation {
    case .ratio(let target):
        #expect(
            ratio >= target,
            "\(label): expected ≥\(target):1, got \(ratio.rounded(toPlaces: 2)):1",
            sourceLocation: sourceLocation
        )
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
