import Foundation

enum APIKeys {
    private static let placeholder = ""

    /// Repo-Platzhalter-UUID — gilt nicht als konfigurierter Key (siehe kopiertes `APIKeys.swift`).
    static let tankerkoenigRepositoryPlaceholderUUID = "15d034ae-e9bc-016b-ad9e-ca5a87e4cc5a"

    /// Tankerkönig-UUID. **Nie** echten Key committen.
    ///
    /// **Ohne Key in der App (Produktion):** HTTPS-Proxy konfigurieren — siehe ``TankerkoenigAPIConfiguration``
    /// (`TankerkoenigProxyBaseURL` in Info.plist oder Umgebungsvariable `TANKERKOENIG_PROXY_BASE_URL`).
    /// Der Proxy setzt `apikey` nur serverseitig beim Weiterleiten an Tankerkönig.
    ///
    /// **Lokal testen (bleibt bei Git nicht „weg“):**
    /// 1. **Simulator (empfohlen):** Auf dem Mac `mkdir -p ~/.fuelnow` und eine Zeile Key in
    ///    `~/.fuelnow/tankerkoenig-api-key` speichern. Im Simulator wird über
    ///    `SIMULATOR_HOST_HOME` automatisch diese Datei gelesen.
    /// 2. **Umgebungsvariable** `TANKERKOENIG_API_KEY` (Xcode Scheme → Run → Environment Variables).
    /// 3. **Dateipfad** `TANKERKOENIG_API_KEY_FILE` = absoluter Pfad zu einer Textdatei (eine Zeile Key).
    /// 4. Nur **DEBUG:** UserDefaults-Schlüssel `dev.fuelnow.tankerkoenigAPIKey` (z. B. einmalig per Code oder `defaults write`).
    ///
    /// Beantragung Key: Linear **TAN-72**.
    static var tankerkoenig: String {
        if let key = resolvedFromEnvironmentVariable() { return key }
        if let key = resolvedFromExplicitKeyFile() { return key }
        #if DEBUG
        if let key = resolvedFromSimulatorHostHomeKeyFile() { return key }
        if let key = resolvedFromUserDefaults() { return key }
        #endif
        return placeholder
    }

    static func isConfiguredTankerkoenigKey(_ raw: String) -> Bool {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return false }
        guard t != "PASTE_YOUR_KEY_HERE" else { return false }
        return t.caseInsensitiveCompare(tankerkoenigRepositoryPlaceholderUUID) != .orderedSame
    }

    static var isTankerkoenigKeyConfiguredForRequests: Bool {
        isConfiguredTankerkoenigKey(tankerkoenig)
    }

    private static func resolvedFromEnvironmentVariable() -> String? {
        guard let raw = ProcessInfo.processInfo.environment["TANKERKOENIG_API_KEY"] else { return nil }
        return normalizedKey(raw)
    }

    private static func resolvedFromExplicitKeyFile() -> String? {
        guard let path = ProcessInfo.processInfo.environment["TANKERKOENIG_API_KEY_FILE"],
              !path.isEmpty else { return nil }
        return normalizedKey(readKeyFile(at: URL(fileURLWithPath: path, isDirectory: false)))
    }

    #if DEBUG
    private static func resolvedFromSimulatorHostHomeKeyFile() -> String? {
        #if targetEnvironment(simulator)
        guard let hostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"],
              !hostHome.isEmpty else { return nil }
        let url = URL(fileURLWithPath: hostHome, isDirectory: true)
            .appendingPathComponent(".fuelnow", isDirectory: true)
            .appendingPathComponent("tankerkoenig-api-key", isDirectory: false)
        return normalizedKey(readKeyFile(at: url))
        #else
        return nil
        #endif
    }

    private static func resolvedFromUserDefaults() -> String? {
        guard let raw = UserDefaults.standard.string(forKey: "dev.fuelnow.tankerkoenigAPIKey") else { return nil }
        return normalizedKey(raw)
    }
    #endif

    private static func readKeyFile(at url: URL) -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func normalizedKey(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines))
        guard !t.isEmpty, t != placeholder else { return nil }
        return t
    }

    #if DEBUG
    static func warnIfPlaceholderActive() {
        guard !TankerkoenigAPIConfiguration.isLiveAccessConfigured else { return }
        print(
            "⚠️ FuelNow: Kein Tankerkönig-API-Key und kein Proxy — im DEBUG-Build werden "
                + "Mock-Tankstellen aus dem Bundle genutzt. Für Live-Daten: Key wie in diesem "
                + "File beschrieben setzen, Proxy konfigurieren, oder `FUELNOW_USE_LIVE_STATIONS=1` "
                + "zum Testen der Fehler-UI. Linear TAN-72."
        )
    }
    #endif
}
