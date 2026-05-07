import SwiftUI

/// Vollflächiger Offline-Splash über der Karte (TAN-91).
///
/// Wird angezeigt, sobald `NetworkMonitor.shouldShowOfflineSplash` true ist — also entweder
/// wenn das System keinen Pfad mehr meldet (Flugmodus, kein WLAN) oder wenn der zuletzt
/// versuchte Tankerkönig-Fetch mit `URLError(.notConnectedToInternet)` /
/// `URLError(.timedOut)` fehlschlug. Verschwindet automatisch, sobald wieder eine
/// erfolgreiche Verbindung steht (`NetworkMonitor` setzt `lastFetchSuggestsOffline` zurück
/// bei erfolgreichem Fetch oder bei `path.status == .satisfied`).
///
/// **Animation:** Zwei pulsierende Ringe um ein SF-Symbol, mit `accessibilityReduceMotion`
/// als Off-Schalter — bei aktivierter Bewegungsreduktion erscheint die Grafik statisch und
/// der Text bleibt unverändert lesbar (WCAG 2.2 AAA).
struct OfflineSplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulse = false

    private var scrimOpacity: Double {
        colorScheme == .dark ? 0.62 : 0.42
    }

    private var ringColor: Color {
        TRColors.accent
    }

    private var iconSymbol: String {
        "wifi.slash"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(scrimOpacity)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: TRSpacing.l) {
                animatedIcon
                    .accessibilityHidden(true)

                VStack(spacing: TRSpacing.xs) {
                    Text("offline.splash.title")
                        .font(TRTypography.title())
                        .foregroundStyle(TRColors.labelPrimary)
                        .multilineTextAlignment(.center)

                    Text("offline.splash.subtitle")
                        .font(TRTypography.body())
                        .foregroundStyle(TRColors.labelSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, TRSpacing.m)
            }
            .padding(.vertical, TRSpacing.xl)
            .padding(.horizontal, TRSpacing.l)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: TRRadius.xl, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TRRadius.xl, style: .continuous)
                    .strokeBorder(TRColors.separator.opacity(0.6), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.55 : 0.18), radius: 28, y: 12)
            .padding(TRSpacing.l)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("offline.splash.a11y.label"))
        .accessibilityHint(Text("offline.splash.a11y.hint"))
        .onAppear {
            guard !reduceMotion else { return }
            pulse = true
        }
        .onChange(of: reduceMotion) { _, newValue in
            pulse = !newValue
        }
    }

    private var animatedIcon: some View {
        ZStack {
            if !reduceMotion {
                pulsingRing(scaleStart: 0.85, scaleEnd: 1.65, opacityStart: 0.55, delay: 0)
                pulsingRing(scaleStart: 0.85, scaleEnd: 1.85, opacityStart: 0.35, delay: 0.55)
            }

            Circle()
                .fill(TRColors.accent.opacity(0.18))
                .frame(width: 96, height: 96)

            Image(systemName: iconSymbol)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(TRColors.accentText)
                .modifier(IconBreathingEffect(active: !reduceMotion))
        }
        .frame(width: 160, height: 160)
    }

    private func pulsingRing(scaleStart: CGFloat, scaleEnd: CGFloat, opacityStart: Double, delay: Double) -> some View {
        Circle()
            .stroke(ringColor, lineWidth: 2)
            .frame(width: 96, height: 96)
            .scaleEffect(pulse ? scaleEnd : scaleStart)
            .opacity(pulse ? 0 : opacityStart)
            .animation(
                .easeOut(duration: 1.6)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: pulse
            )
    }
}

/// Sanfte „Atmung" auf dem zentralen Symbol — auf 1.0 bleibt es bei `accessibilityReduceMotion`.
private struct IconBreathingEffect: ViewModifier {
    let active: Bool
    @State private var inhale = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(active && inhale ? 1.06 : 1.0)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    inhale = true
                }
            }
    }
}

#Preview("Light") {
    OfflineSplashView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OfflineSplashView()
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    OfflineSplashView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
