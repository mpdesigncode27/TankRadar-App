import StoreKit
import SwiftUI

/// Optionales Upgrade-Sheet für FuelNow Plus.
///
/// Reine Opt-in-Surface: wird ausschließlich aus den Einstellungen heraus geöffnet
/// („Was ist FuelNow Plus?"). Es gibt **keine** automatische Einblendung, keinen
/// Nag-Banner und keine „kostenlos probieren"-Copy — `FuelNowPlus.storekit`
/// definiert keinen `introductoryOffer`. Subscription-Pipeline kommt komplett
/// aus dem geteilten `PlusPurchaseController` + `EntitlementManager` (TAN-44).
struct PlusUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlementManager

    @State private var purchase = PlusPurchaseController()

    private var plusYearlyProduct: Product? {
        entitlementManager.products.first { $0.id == SubscriptionConstants.plusYearlyProductID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TRSpacing.l) {
                    heroSection
                    benefitsSection
                    purchaseSection
                    secondaryActionsSection
                    fineprintSection
                }
                .padding(TRSpacing.m)
                .padding(.bottom, TRSpacing.l)
            }
            .navigationTitle(Text("plus.sheet.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(TRColors.labelSecondary)
                    }
                    .accessibilityLabel("plus.sheet.close")
                    .accessibilityHint("Schließt das FuelNow-Plus-Fenster.")
                }
            }
            .task {
                await entitlementManager.loadProducts()
            }
            .alert(
                Text("settings.plus.alert.title"),
                isPresented: Binding(
                    get: { purchase.alertMessage != nil },
                    set: { if !$0 { purchase.alertMessage = nil } }
                ),
                actions: {
                    Button("settings.plus.alert.ok", role: .cancel) {
                        purchase.alertMessage = nil
                    }
                },
                message: {
                    if let message = purchase.alertMessage {
                        Text(message)
                    }
                }
            )
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            Text("plus.hero.eyebrow")
                .font(TRTypography.caption())
                .textCase(.uppercase)
                .foregroundStyle(TRColors.accentText)
                .accessibilityAddTraits(.isHeader)

            Text("plus.hero.headline")
                .font(TRTypography.title())
                .foregroundStyle(TRColors.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("plus.hero.subhead")
                .font(TRTypography.body())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.m) {
            ForEach(Self.benefits) { benefit in
                BenefitRow(benefit: benefit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if entitlementManager.isPlusSubscriber {
            VStack(alignment: .leading, spacing: TRSpacing.s) {
                Label {
                    Text("settings.plus.status.active")
                        .font(TRTypography.bodyBold())
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(TRColors.accentText)
                }
                Text("plus.status.active.detail")
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else if let product = plusYearlyProduct {
            VStack(spacing: TRSpacing.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text(product.displayPrice)
                        .font(TRTypography.title2())
                    Text("settings.plus.perYear")
                        .font(TRTypography.body())
                        .foregroundStyle(TRColors.labelSecondary)
                    Spacer()
                }
                .accessibilityElement(children: .combine)

                Button {
                    Task { await purchase.subscribe(to: product, via: entitlementManager) }
                } label: {
                    Group {
                        if purchase.isPurchasing {
                            ProgressView()
                        } else {
                            Text("plus.sheet.subscribe")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.trPrimaryGlass)
                .disabled(purchase.isBusy)
                .accessibilityLabel("plus.sheet.subscribe")
                .accessibilityHint("Startet den Jahresabo-Kauf über den App Store.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: TRSpacing.s) {
                ProgressView()
                Text("settings.plus.priceLoading")
                    .foregroundStyle(TRColors.labelSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var secondaryActionsSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            Button {
                Task { await purchase.restore(via: entitlementManager) }
            } label: {
                Label("settings.plus.restore", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(purchase.isBusy)
            .foregroundStyle(TRColors.accentText)
            .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")

            Button {
                openURL(Self.manageSubscriptionsURL)
            } label: {
                Label("settings.plus.manage", systemImage: "creditcard")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(TRColors.accentText)
            .accessibilityHint("Öffnet die Abonnementverwaltung deines Apple-ID-Kontos.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fineprintSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.xs) {
            Text("plus.sheet.footer.billing")
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("plus.sheet.footer.cancel")
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Benefits

private extension PlusUpgradeView {
    struct Benefit: Identifiable {
        let id: String
        let systemImage: String
        let title: LocalizedStringResource
        let description: LocalizedStringResource
    }

    static let benefits: [Benefit] = [
        Benefit(
            id: "carplay",
            systemImage: "car.fill",
            title: "plus.benefit.carplay.title",
            description: "plus.benefit.carplay.description"
        ),
        Benefit(
            id: "support",
            systemImage: "heart.fill",
            title: "plus.benefit.support.title",
            description: "plus.benefit.support.description"
        ),
        Benefit(
            id: "future",
            systemImage: "sparkles",
            title: "plus.benefit.future.title",
            description: "plus.benefit.future.description"
        ),
    ]

    /// Apple-zentrale Abonnementübersicht (Review-konform für „Manage").
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}

private struct BenefitRow: View {
    let benefit: PlusUpgradeView.Benefit

    var body: some View {
        HStack(alignment: .top, spacing: TRSpacing.m) {
            Image(systemName: benefit.systemImage)
                .font(.title2)
                .foregroundStyle(TRColors.accentText)
                .frame(width: 32, height: 32, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                Text(benefit.title)
                    .font(TRTypography.bodyBold())
                    .foregroundStyle(TRColors.labelPrimary)
                Text(benefit.description)
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("Light") {
    PlusUpgradeView()
        .environment(EntitlementManager())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PlusUpgradeView()
        .environment(EntitlementManager())
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    PlusUpgradeView()
        .environment(EntitlementManager())
        .environment(\.dynamicTypeSize, .accessibility3)
}
