import SwiftUI

extension View {
    /// Kompakte Glas-Pille (z. B. Badges, Chips); bei „Transparenz reduzieren“ Material statt Glas.
    func trGlassPill(interactive: Bool = false) -> some View {
        modifier(TRAdaptiveGlassSurfaceModifier(surface: .pill(interactive: interactive)))
    }
}
