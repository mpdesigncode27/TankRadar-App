import SwiftUI

extension View {
    /// Standard-Kartenfläche mit Liquid Glass und abgerundeten Ecken; Material-Fallback bei „Transparenz reduzieren“.
    func trCardBackground(cornerRadius: CGFloat = TRRadius.lg) -> some View {
        modifier(TRAdaptiveGlassSurfaceModifier(surface: .card(cornerRadius: cornerRadius)))
    }
}
