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

    @Test func paletteHexLightMatchesDesignNotes() {
        #expect(TRPaletteHex.accent == "2EC4B6")
        #expect(TRPaletteHex.accentMuted == "248F85")
        #expect(TRPaletteHex.background == "F5F7FA")
        #expect(TRPaletteHex.backgroundSecondary == "FFFFFF")
        #expect(TRPaletteHex.backgroundTertiary == "E8ECF2")
        #expect(TRPaletteHex.labelPrimary == "0B1F33")
        #expect(TRPaletteHex.labelSecondary == "5C6B7A")
        #expect(TRPaletteHex.labelTertiary == "8E9AA5")
        #expect(TRPaletteHex.separator == "D1D9E0")
        #expect(TRPaletteHex.danger == "D92D20")
        #expect(TRPaletteHex.success == "1F8A55")
    }
}
