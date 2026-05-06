import Foundation
import Observation
import StoreKit

// Lives under Services so a future CarPlay extension target can add this file to compile membership.

private final class TransactionUpdatesSubscription {
    private var task: Task<Void, Never>?

    func replace(with newTask: Task<Void, Never>) {
        task?.cancel()
        task = newTask
    }

    deinit {
        task?.cancel()
    }
}

/// StoreKit-2 subscription state for FuelNow Plus. Same entitlement gates CarPlay (Phase 7).
@Observable @MainActor
final class EntitlementManager {
    /// Loaded subscription products (ASC / `.storekit` Local Testing).
    private(set) var products: [Product] = []

    /// True when an active FuelNow Plus subscription is in `Transaction.currentEntitlements`.
    private(set) var isPlusSubscriber = false

    /// Alias for product roadmap — today identical to Plus.
    var isCarPlayUnlocked: Bool { isPlusSubscriber }

    @ObservationIgnored private let transactionUpdates = TransactionUpdatesSubscription()

    #if DEBUG
    /// Lokales Debug-Override: wenn `true`, gilt der User als Plus-Abonnent ohne echten Kauf
    /// (siehe `applyDebugUnlockIfRequested()`). Niemals im Release aktiv.
    @ObservationIgnored private var debugForcedPlusUnlock = false
    #endif

    init() {}

    /// Loads products, refreshes entitlements, then observes `Transaction.updates` for the app lifetime.
    /// Im DEBUG-Build wird zusätzlich `applyDebugUnlockIfRequested()` aufgerufen, damit Launch-Args
    /// und der Settings-Demo-Toggle (TAN-90) den Plus-Status ohne Sandbox-Apple-ID setzen können.
    func start() async {
        await loadProducts()
        await refreshEntitlements()
        #if DEBUG
        applyDebugUnlockIfRequested()
        #endif
        guard ProcessInfo.processInfo.environment["UITESTING"] != "1" else { return }
        observeTransactionUpdates()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: SubscriptionConstants.productIDs)
            products.sort { $0.id < $1.id }
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case let .success(verification):
            let transaction = try Self.unwrapVerification(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled:
            throw EntitlementManagerError.userCancelled
        case .pending:
            throw EntitlementManagerError.pending
        @unknown default:
            throw EntitlementManagerError.unknownPurchaseResult
        }
    }

    /// Restore via Apple account sync, then re-read current entitlements.
    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var plus = false
        for await entitlement in Transaction.currentEntitlements {
            guard case let .verified(transaction) = entitlement else { continue }
            guard transaction.revocationDate == nil else { continue }
            if SubscriptionConstants.productIDs.contains(transaction.productID) {
                plus = true
                break
            }
        }
        #if DEBUG
        if debugForcedPlusUnlock { plus = true }
        #endif
        isPlusSubscriber = plus
    }

    #if DEBUG
    /// Liest Launch-Arg `--mock-plus-subscriber` und das `@AppStorage`-Flag `__debug__forcePlusUnlocked`.
    /// Wenn eines aktiv ist, wird `isPlusSubscriber = true` ohne echten Kauf gesetzt — nützlich für
    /// Smoke-Tests via `xcrun simctl launch` (kein StoreKit-Local-Testing) und für UI-/CarPlay-Demos
    /// im Simulator (TAN-90). Im Release-Build vollständig ausgeschlossen via `#if DEBUG`.
    @discardableResult
    func applyDebugUnlockIfRequested(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        storedFlag: Bool? = nil
    ) -> Bool
    {
        let launchArgUnlock = arguments.contains(EntitlementManager.debugUnlockLaunchArg)
        let storage = storedFlag ?? UserDefaults.standard.bool(forKey: EntitlementManager.debugUnlockStorageKey)
        let unlock = launchArgUnlock || storage
        debugForcedPlusUnlock = unlock
        if unlock {
            isPlusSubscriber = true
        }
        return unlock
    }

    /// Setzt das Debug-Override zur Laufzeit (vom Settings-Demo-Toggle aufgerufen). Persistiert in
    /// `UserDefaults` und passt `isPlusSubscriber` sofort an, damit die UI ohne App-Restart umschaltet.
    func setDebugForcedPlusUnlock(_ unlock: Bool) {
        debugForcedPlusUnlock = unlock
        UserDefaults.standard.set(unlock, forKey: EntitlementManager.debugUnlockStorageKey)
        if unlock {
            isPlusSubscriber = true
        } else {
            Task { await refreshEntitlements() }
        }
    }

    static let debugUnlockLaunchArg = "--mock-plus-subscriber"
    static let debugUnlockStorageKey = "__debug__forcePlusUnlocked"
    #endif

    private func observeTransactionUpdates() {
        transactionUpdates.replace(with: Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(transactionUpdate: update)
            }
        })
    }

    private func handle(transactionUpdate: VerificationResult<Transaction>) async {
        guard case let .verified(transaction) = transactionUpdate else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    private static func unwrapVerification(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case let .verified(transaction):
            transaction
        case let .unverified(_, error):
            throw error
        }
    }
}

enum EntitlementManagerError: Error, Equatable {
    case userCancelled
    case pending
    case unknownPurchaseResult
}
