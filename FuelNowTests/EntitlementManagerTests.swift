import Testing
@testable import FuelNow

/// Deterministic checks only — StoreKit session tests belong in TAN-62.
@MainActor
struct EntitlementManagerTests {
    @Test func initialSubscriptionGateIsClosed() {
        let manager = EntitlementManager()
        #expect(manager.isPlusSubscriber == false)
        #expect(manager.isCarPlayUnlocked == false)
        #expect(manager.products.isEmpty)
    }
}

#if DEBUG
import Foundation

/// Tests für `applyDebugUnlockIfRequested()` und `setDebugForcedPlusUnlock(_:)` (TAN-90).
///
/// Diese Pfade sind ausschließlich in DEBUG-Builds aktiv und brauchen keine `SKTestSession` —
/// sie müssen daher auch dann grün sein, wenn der bekannte Apple-SKTestSession-Bug die
/// `EntitlementManagerStoreKitTests` deaktiviert hält.
///
/// `setDebugForcedPlusUnlock` schreibt in den globalen `UserDefaults.standard`-Container
/// (App-Group ist hier nicht verwendet). Damit Tests sich nicht gegenseitig den Zustand
/// vermüllen, läuft die Suite `.serialized` und jede Schreib-Methode räumt explizit auf.
@MainActor
@Suite("EntitlementManager / DEBUG unlock", .serialized)
struct EntitlementManagerDebugUnlockTests {
    @Test func launchArgumentEnablesPlusUnlock() {
        let manager = EntitlementManager()
        let unlocked = manager.applyDebugUnlockIfRequested(
            arguments: [EntitlementManager.debugUnlockLaunchArg],
            storedFlag: false
        )
        #expect(unlocked == true)
        #expect(manager.isPlusSubscriber == true)
        #expect(manager.isCarPlayUnlocked == true)
    }

    @Test func storedFlagEnablesPlusUnlockWithoutLaunchArgument() {
        let manager = EntitlementManager()
        let unlocked = manager.applyDebugUnlockIfRequested(
            arguments: [],
            storedFlag: true
        )
        #expect(unlocked == true)
        #expect(manager.isPlusSubscriber == true)
    }

    @Test func bothFlagsAbsentLeavesGateClosed() {
        let manager = EntitlementManager()
        let unlocked = manager.applyDebugUnlockIfRequested(
            arguments: [],
            storedFlag: false
        )
        #expect(unlocked == false)
        #expect(manager.isPlusSubscriber == false)
        #expect(manager.isCarPlayUnlocked == false)
    }

    @Test func toggleOnSetsPlusSubscriberSynchronously() {
        defer { UserDefaults.standard.removeObject(forKey: EntitlementManager.debugUnlockStorageKey) }
        let manager = EntitlementManager()
        manager.setDebugForcedPlusUnlock(true)
        #expect(manager.isPlusSubscriber == true)
        #expect(manager.isCarPlayUnlocked == true)
    }

    @Test func toggleOnPersistsAcrossNewManagerInstance() throws {
        let key = EntitlementManager.debugUnlockStorageKey
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let writer = EntitlementManager()
        writer.setDebugForcedPlusUnlock(true)
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        let reader = EntitlementManager()
        let unlocked = reader.applyDebugUnlockIfRequested(arguments: [])
        #expect(unlocked == true)
        #expect(reader.isPlusSubscriber == true)
    }

    @Test func customLaunchArgumentValueDoesNotMatchAccidentally() {
        let manager = EntitlementManager()
        let unlocked = manager.applyDebugUnlockIfRequested(
            arguments: ["--mock-plus-subscriber-typo"],
            storedFlag: false
        )
        #expect(unlocked == false)
        #expect(manager.isPlusSubscriber == false)
    }
}
#endif
