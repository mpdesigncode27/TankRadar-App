import StoreKit
import SwiftUI

/// Einstellungen als nutzerzentrierte `Form` mit Sections — Liquid Glass nur auf primären Aktionen.
///
/// Reihenfolge (TAN-78, angepasst durch TAN-79, TAN-86, TAN-88 und TAN-89):
/// 1. **Kraftstoff** – große Karten-Auswahl (E5 / E10 / Diesel) mit aktiver Glas-Karte als visuellem Anker.
///    Seit TAN-86 ohne 1-Zeilen-Untertitel — nur Glyph + Sortenname; Untertitel bleibt VoiceOver-only.
///    Seit TAN-88 ohne Beschreibungs-Footer — die Karten sind selbsterklärend.
/// 2. **Erscheinungsbild** – Drei-Segmente-Icon-Picker (Auto / Hell / Dunkel) mit Akzent-Glas-Pille
///    auf dem aktiven Segment (TAN-86, ersetzt den zuvor genutzten `Picker(.menu)`). Seit TAN-88
///    ohne Beschreibungs-Footer — der Icon-Picker ist visuell selbsterklärend.
/// 3. **FuelNow Plus** – Mini-Hero mit Eyebrow / Headline / 1–2 Benefits / Preis prominent / einem
///    Glas-CTA, der das volle `PlusUpgradeView`-Sheet (TAN-45) öffnet. Bei aktivem Abo erscheint stattdessen
///    eine schlichte Status-Sektion mit Verwaltungs- und Restore-Aktionen.
/// 4. **Datenquellen-Footer** – unauffälliger Tankerkönig/MTS-K-Hinweis (CC BY 4.0).
///
/// Der frühere „Suchradius"-Slider ist mit TAN-79 entfernt; die App nutzt fest das
/// Tankerkönig-API-Maximum von 25 km (`AppSettings.SearchRadius.apiMaxKm`).
/// Der frühere Stammtankstellen-Platzhalter (Phase 9 / Appwrite-Sync) ist mit TAN-89 entfernt;
/// die zugehörigen `settings.section.favorites.placeholder.*`-Strings bleiben im Catalog
/// erhalten (vom Build automatisch als `extractionState: stale` markiert) und können bei
/// Wiederaufnahme reaktiviert werden.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlementManager

    @AppStorage(AppSettings.UserDefaultsKey.preferredFuelType) private var preferredFuelRaw = FuelType.e10.rawValue
    @AppStorage(AppSettings.UserDefaultsKey.appearancePreference) private var appearanceRaw = AppSettings.AppearancePreference.system.rawValue

    private var appearanceBinding: Binding<AppSettings.AppearancePreference> {
        Binding(
            get: { AppSettings.AppearancePreference.resolved(storedRaw: appearanceRaw) },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    private var fuelBinding: Binding<FuelType> {
        Binding(
            get: { FuelType(rawValue: preferredFuelRaw) ?? .e10 },
            set: { preferredFuelRaw = $0.rawValue }
        )
    }

    @State private var purchase = PlusPurchaseController()
    @State private var showPlusUpgradeSheet = false

    private var plusYearlyProduct: Product? {
        entitlementManager.products.first { $0.id == SubscriptionConstants.plusYearlyProductID }
    }

    var body: some View {
        NavigationStack {
            Form {
                fuelSection
                appearanceSection
                plusSection
                dataSourceFooterSection
            }
            .navigationTitle(Text("settings.title"))
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
                    .accessibilityLabel(Text("settings.done.close"))
                    .accessibilityHint("Schließt die Einstellungen.")
                }
            }
            .task {
                #if DEBUG
                purchase.applyDebugMockIfRequested()
                #endif
                await entitlementManager.loadProducts()
                if let product = plusYearlyProduct {
                    await purchase.refreshTrialOffer(for: product)
                }
            }
            .sheet(isPresented: $showPlusUpgradeSheet) {
                PlusUpgradeView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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

    private var fuelSection: some View {
        Section {
            FuelTypeCardPicker(selection: fuelBinding)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: TRSpacing.xs, leading: 0, bottom: TRSpacing.xs, trailing: 0))
                .listRowSeparator(.hidden)
        } header: {
            Text("settings.section.fuelType")
        }
    }

    private var appearanceSection: some View {
        Section {
            AppearanceIconPicker(selection: appearanceBinding)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: TRSpacing.xs, leading: 0, bottom: TRSpacing.xs, trailing: 0))
                .listRowSeparator(.hidden)
        } header: {
            Text("settings.section.appearance")
        }
    }

    @ViewBuilder
    private var plusSection: some View {
        if entitlementManager.isPlusSubscriber {
            plusActiveSection
        } else {
            plusPromoSection
        }
    }

    /// Promo-Sektion für Nicht-Plus-User: Mini-Hero als einziges visuelles Asset, plus dezente Zweit-Aktionen.
    private var plusPromoSection: some View {
        Section {
            PlusMiniHero(
                product: plusYearlyProduct,
                isLoading: plusYearlyProduct == nil,
                trialOffer: purchase.trialOffer,
                openPlusSheet: { showPlusUpgradeSheet = true }
            )
            .listRowInsets(EdgeInsets(top: TRSpacing.xs, leading: 0, bottom: TRSpacing.xs, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Button {
                Task { await restorePurchases() }
            } label: {
                Label("settings.plus.restore", systemImage: "arrow.clockwise")
            }
            .disabled(purchase.isBusy)
            .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")
        } header: {
            Text("settings.section.plus")
        } footer: {
            Text("settings.plus.footer")
        }
    }

    /// Status-Sektion für aktive Plus-Abonnenten: keine Promo, klare Verwaltungs-Aktionen.
    private var plusActiveSection: some View {
        Section {
            Label {
                Text("settings.plus.status.active")
                    .font(TRTypography.bodyBold())
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(TRColors.accentText)
            }
            .accessibilityElement(children: .combine)

            Button {
                openURL(Self.manageSubscriptionsURL)
            } label: {
                Label("settings.plus.manage", systemImage: "creditcard")
            }
            .accessibilityHint("Öffnet die Abonnementverwaltung deines Apple-ID-Kontos.")

            Button {
                Task { await restorePurchases() }
            } label: {
                Label("settings.plus.restore", systemImage: "arrow.clockwise")
            }
            .disabled(purchase.isBusy)
            .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")
        } header: {
            Text("settings.section.plus")
        } footer: {
            Text("settings.plus.footer")
        }
    }

    /// Datenquellen-Hinweis am Listenende — bewusst klein und ohne eigene Glas-Karte.
    private var dataSourceFooterSection: some View {
        Section {
            EmptyView()
        } footer: {
            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                let attribution = AttributedString(
                    String(
                        format: String(localized: "settings.dataSource.inline"),
                        String(localized: "settings.dataSource.linkLabel")
                    )
                )
                Text(attribution)
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Tankerkönig und MTS-K, Lizenz CC BY 4.0")
                    .accessibilityHint("Doppeltippen, um die Lizenzinformationen zu öffnen.")
                    .onTapGesture {
                        openURL(AppSettings.TankerkoenigAttribution.infoURL)
                    }
            }
            .padding(.top, TRSpacing.xs)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Store actions

    @MainActor
    private func restorePurchases() async {
        await purchase.restore(via: entitlementManager)
    }
}

#Preview("Light") {
    SettingsView()
        .environment(EntitlementManager())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SettingsView()
        .environment(EntitlementManager())
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    SettingsView()
        .environment(EntitlementManager())
        .environment(\.dynamicTypeSize, .accessibility3)
}

private extension SettingsView {
    /// Öffnet die zentrale Apple-Abonnementübersicht (Review-konformes „Manage“).
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}
