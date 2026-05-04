import SwiftUI

/// Varianten der Liquid-Glass-Oberflächen mit Material-Fallback bei „Transparenz reduzieren“ (TAN-21).
enum TRAdaptiveGlassSurface {
    case pill(interactive: Bool)
    case circleInteractive
    case card(cornerRadius: CGFloat)
    case primaryTintCapsule
    case softCapsule
}

struct TRAdaptiveGlassSurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let surface: TRAdaptiveGlassSurface

    func body(content: Content) -> some View {
        switch surface {
        case let .pill(interactive):
            if reduceTransparency {
                content.background(.regularMaterial, in: Capsule())
            } else {
                let style = interactive ? Glass.regular.interactive() : Glass.regular
                content.glassEffect(style, in: .capsule)
            }

        case .circleInteractive:
            if reduceTransparency {
                content.background(.regularMaterial, in: Circle())
            } else {
                content.glassEffect(Glass.regular.interactive(), in: Circle())
            }

        case let .card(cornerRadius):
            if reduceTransparency {
                content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                content.glassEffect(Glass.regular, in: .rect(cornerRadius: cornerRadius))
            }

        case .primaryTintCapsule:
            if reduceTransparency {
                content
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(TRColors.accent.opacity(0.5), lineWidth: 1))
            } else {
                content.glassEffect(Glass.regular.tint(TRColors.accent.opacity(0.35)).interactive(), in: .capsule)
            }

        case .softCapsule:
            if reduceTransparency {
                content.background(.regularMaterial, in: Capsule())
            } else {
                content.glassEffect(Glass.regular.interactive(), in: .capsule)
            }
        }
    }
}
