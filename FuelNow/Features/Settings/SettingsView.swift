import StoreKit
import SwiftUI

/// Einstellungen als nutzerzentrierte `Form` mit Sections — Liquid Glass nur auf primären Aktionen.
///
/// Reihenfolge: **Kraftstoff & Suche** → **Erscheinungsbild** → **FuelNow Plus** → kleiner Datenquellen-Footer.
/// Werte greifen über `@AppStorage` direkt; Schließen über Toolbar `Fertig` oder Sheet-Swipe.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlementManager

    @AppStorage(AppSettings.UserDefaultsKey.preferredFuelType) private var preferredFuelRaw = FuelType.e10.rawValue
    @AppStorage(AppSettings.UserDefaultsKey.searchRadiusKm) private var searchRadiusKm = AppSettings.SearchRadius.defaultKm
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
                fuelAndSearchSection
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
                        Text("settings.done.close")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel(Text("settings.done.close"))
                    .accessibilityHint("Schließt die Einstellungen.")
                }
            }
            .task {
                await entitlementManager.loadProducts()
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

    private var fuelAndSearchSection: some View {
        Section {
            Picker(selection: fuelBinding) {
                ForEach(FuelType.allCases) { fuel in
                    Text(fuel.displayName).tag(fuel)
                }
            } label: {
                Text("settings.fuel.row.title")
            }
            .pickerStyle(.menu)
            .accessibilityHint(Text("Bestimmt, welche Sorte auf der Karte für Preise verwendet wird."))

            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                HStack {
                    Text("settings.row.radiusTitle")
                    Spacer()
                    Text("\(searchRadiusKm) km")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .ignore)

                Slider(
                    value: Binding(
                        get: { Double(searchRadiusKm) },
                        set: { searchRadiusKm = AppSettings.SearchRadius.clampedKm(sliderValue: $0) }
                    ),
                    in: Double(AppSettings.SearchRadius.minKm)...Double(AppSettings.SearchRadius.maxKm),
                    step: 1
                )
                .tint(TRColors.accent)
                .accessibilityLabel(Text("settings.row.radiusTitle"))
                .accessibilityValue("\(searchRadiusKm) Kilometer")
            }
            .padding(.vertical, TRSpacing.xxs)
        } header: {
            Text("settings.section.fuelType")
        } footer: {
            Text("settings.radius.footer")
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker(selection: appearanceBinding) {
                ForEach(AppSettings.AppearancePreference.allCases) { mode in
                    Text(mode.localizedTitle).tag(mode)
                }
            } label: {
                Text("settings.appearance.header")
            }
            .pickerStyle(.menu)
            .accessibilityHint(Text("settings.appearance.a11yHint"))
        } header: {
            Text("settings.section.displayAndRadius")
        } footer: {
            Text("settings.appearance.footer")
        }
    }

    private var plusSection: some View {
        Section {
            if entitlementManager.isPlusSubscriber {
                Label {
                    Text("settings.plus.status.active")
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(TRColors.accent)
                }
            } else if let product = plusYearlyProduct {
                HStack(alignment: .firstTextBaseline) {
                    Text(product.displayPrice)
                        .font(TRTypography.bodyBold())
                    Text("settings.plus.perYear")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .accessibilityElement(children: .combine)

                Button {
                    Task { await subscribePlusYearly() }
                } label: {
                    Text("settings.plus.subscribe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.trPrimaryGlass)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .disabled(purchase.isBusy)
                .accessibilityHint("Startet den Jahresabo-Kauf über den App Store.")
            } else {
                HStack {
                    ProgressView()
                    Text("settings.plus.priceLoading")
                        .foregroundStyle(.secondary)
                }
            }

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

            Button {
                showPlusUpgradeSheet = true
            } label: {
                Label("settings.plus.learnMore", systemImage: "info.circle")
            }
            .accessibilityHint("Öffnet eine Übersicht der FuelNow-Plus-Vorteile.")
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
    private func subscribePlusYearly() async {
        guard let product = plusYearlyProduct else {
            purchase.alertMessage = String(localized: "settings.plus.priceLoading")
            return
        }
        await purchase.subscribe(to: product, via: entitlementManager)
    }

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

private extension AppSettings.AppearancePreference {
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .system:
            "settings.appearance.system"
        case .light:
            "settings.appearance.light"
        case .dark:
            "settings.appearance.dark"
        }
    }
}
