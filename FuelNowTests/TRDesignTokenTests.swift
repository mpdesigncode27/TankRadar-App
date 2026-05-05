import Testing
@testable import FuelNow

struct TRDesignTokenTests {
    @Test func spacingReferenceValues() {
        #expect(TRSpacing.xxs == 4)
        #expect(TRSpacing.xs == 8)
        #expect(TRSpacing.s == 12)
        #expect(TRSpacing.m == 16)
        #expect(TRSpacing.l == 24)
        #expect(TRSpacing.xl == 32)
        #expect(TRSpacing.xxl == 40)
    }

    @Test func radiusReferenceValues() {
        #expect(TRRadius.sm == 8)
        #expect(TRRadius.md == 12)
        #expect(TRRadius.lg == 16)
        #expect(TRRadius.xl == 24)
    }

    /// Light-Hex-Werte sind die Quelle der Wahrheit für die Asset-Katalog-Farben.
    /// Bei Token-Anpassungen (z. B. WCAG-AAA-Refresh, TAN-80) muss dieser Test mit aktualisiert werden.
    @Test func paletteHexLightMatchesDesignNotes() {
        #expect(TRPaletteHex.accent == "2EC4B6")
        #expect(TRPaletteHex.accentMuted == "248F85")
        #expect(TRPaletteHex.accentText == "0F5650")
        #expect(TRPaletteHex.background == "F5F7FA")
        #expect(TRPaletteHex.backgroundSecondary == "FFFFFF")
        #expect(TRPaletteHex.backgroundTertiary == "E8ECF2")
        #expect(TRPaletteHex.labelPrimary == "0B1F33")
        #expect(TRPaletteHex.labelSecondary == "3A4350")
        #expect(TRPaletteHex.labelTertiary == "4A5260")
        #expect(TRPaletteHex.separator == "7C8993")
        #expect(TRPaletteHex.danger == "9F2018")
        #expect(TRPaletteHex.success == "065B30")
    }
}
