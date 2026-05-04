enum APIKeys {
    /// Platzhalter — echten Key **nicht** committen. Kopiere diese Datei zu `APIKeys.swift` (gitignored) oder ersetze lokal; Beantragung: Linear **TAN-72**.
    static let tankerkoenig = "PASTE_YOUR_KEY_HERE"

    #if DEBUG
    static func warnIfPlaceholderActive() {
        guard tankerkoenig == "PASTE_YOUR_KEY_HERE" else { return }
        print("⚠️ TankRadar: APIKeys.tankerkoenig ist noch Platzhalter — siehe Linear TAN-72.")
    }
    #endif
}
