# FuelNow

**Produktspezifikation (Index):** [`docs/PRODUCT_SPEC.md`](docs/PRODUCT_SPEC.md) — Vision, Konventionen und Links zu allen weiteren Specs im Repo und in Linear.

**Tankerkönig-API-Key:** Beantragung und Eintragung über Linear [**TAN-72**](https://linear.app/tankradar-app/issue/TAN-72).

### Checkliste TAN-72 (betrieblich)

1. Key unter [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) beantragen (Formular, E-Mail bestätigen).
2. Key **nicht** ins Repo: nur lokal — siehe `FuelNow/Support/APIKeys.example.swift` und unten „Simulator“.
3. Team-Secret-Store (z. B. 1Password): Eintrag „FuelNow Tankerkönig API Key“ mit UUID und Hinweis auf Lizenz/CC BY.
4. Repo-Check: `./scripts/verify-api-keys-not-committed.sh` (stellt sicher, dass `APIKeys.swift` nicht getrackt ist). Optional: gezielt `git log -p -S '<kurzes Token aus dem Key>'` — sollte **keine** Treffer liefern.
5. Smoke: App im Simulator oder auf dem Gerät mit gültigem Key starten — Karte lädt echte Stationen (Screenshot oder Logzeile „ok“ im Ticket TAN-72 kommentieren).

**Lokal im Simulator testen (ohne dass der Key bei Git verloren geht):** Auf dem Mac eine Datei **`~/.fuelnow/tankerkoenig-api-key`** mit einer Zeile (UUID) anlegen — die App liest sie im Simulator automatisch (`SIMULATOR_HOST_HOME`). Alternativ Xcode-Scheme: Umgebungsvariable **`TANKERKOENIG_API_KEY`** oder **`TANKERKOENIG_API_KEY_FILE`** mit absolutem Pfad (siehe Kommentar in `APIKeys.example.swift`).

**Datenlizenz:** Tankerkönig / MTS-K — Metadaten in API-Antworten unter **CC BY 4.0**; Details und Attribution: [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/?page=info).

## StoreKit Testing (FuelNow Plus, TAN-43)

- Konfiguration: **`FuelNowPlus.storekit`** (Jahresabo `com.vibecoding.fuelnow.subscription.year`, Gruppe „FuelNow Plus“). Produkt-ID gehört auch zu **`SubscriptionConstants`** im Target.
- Scheme **FuelNow** nutzt diese Datei beim **Run** (lokale Transaktionen ohne Sandbox-Account).
- In Xcode: **Debug → StoreKit → Manage Transactions…** bzw. Transaction Inspector nutzen, um Kauf, Renewal und Ablauf zu simulieren.
- App Store Connect ([TAN-42](https://linear.app/tankradar-app/issue/TAN-42)): dieselbe Product-ID anlegen und mit der `.storekit`-Datei abgleichen — Details unten.

## App Store Connect: FuelNow Plus ([TAN-42](https://linear.app/tankradar-app/issue/TAN-42))

Die Jahres-Subscription wird **in App Store Connect** angelegt; ohne dieses Produkt liefert StoreKit in Sandbox/TestFlight keine kaufbare SKU. Die folgende Checkliste dient der **manuellen Validierung** und dem Abgleich mit Repo und Xcode.

### Pflichtwerte (vor Einreichung bitte verifizieren)

| | |
| --- | --- |
| **Bundle-ID der App** | `com.vibecoding.fuelnow` (siehe Xcode / [TAN-73](https://linear.app/tankradar-app/issue/TAN-73)) |
| **Subscription Group** (Anzeigename) | z. B. **FuelNow Plus** — konsistent mit `FuelNowPlus.storekit` |
| **Product-ID** | **`com.vibecoding.fuelnow.subscription.year`** — **identisch** zu `SubscriptionConstants.plusYearlyProductID` und zum Feld `productID` in `FuelNowPlus.storekit` |
| **Typ / Laufzeit** | Auto-Renewable Subscription, **1 Jahr** |
| **Basispreis** | In ASC das Preisniveau wählen, das zur geplanten **ca. 6 €/Jahr**-Position passt (Endpreise sind länderabhängig; **nicht** als Literal in der App-UI hardcodieren — später nur StoreKit `displayPrice` / Lokalisierung nutzen) |

### Schritte in App Store Connect (überblick)

1. **App** auswählen → **Subscriptions** (oder „In-App-Käufe“ je nach Oberfläche) → **Subscription Group** anlegen, falls noch keine existiert.
2. **Subscription** in dieser Gruppe erstellen: Product-ID exakt wie oben (**nach Erstellung nicht änderbar**).
3. **Lokalisierungen** mindestens **Deutsch** und **Englisch** anlegen — Anzeigenamen und Beschreibung analog zu den Einträgen in `FuelNowPlus.storekit` (`de_DE` / `en_US`); Texte dürfen leicht abweichen, die Product-ID nicht.
4. **Review-Hinweise:** In den App-Review-Notizen oder der Produktbeschreibung klarstellen, dass **CarPlay** zu **FuelNow Plus** gehört (Akzeptanzkriterium im Ticket).
5. **Sandbox:** Unter *Users and Access* einen **Sandbox Tester** anlegen; nach erstem Build mit Kauflogik mit diesem Account auf Gerät oder Simulator (Sandbox) prüfen, dass die Subscription geladen und gekauft werden kann.

### Abgleich Repo ↔ ASC (Checkbox fürs Ticket)

- [ ] Product-ID in ASC = Zeichenkette in `FuelNow/Support/SubscriptionConstants.swift`
- [ ] Gleiche Product-ID in `FuelNowPlus.storekit` unter `productID`
- [ ] App enthält **keinen** fest eingetragenen Jahresabo-Preis für die Plus-UI (aktuell keine Paywall — bei Implementierung nur dynamische StoreKit-Preise)
- [ ] **Screenshot** der Abo-Produktseite in App Store Connect als Anhang an [TAN-42](https://linear.app/tankradar-app/issue/TAN-42)

**IPA / TestFlight:** `./scripts/asc.sh` (Fastlane + ASC API Key) — siehe [`docs/AppStoreConnectUpload.md`](docs/AppStoreConnectUpload.md). Kurz: `.env.asc.local` → `./scripts/asc.sh ios asc_verify` → `./scripts/asc.sh ios asc_ship_testflight`.

## Simulator-UI: [AXe CLI](https://www.axe-cli.com/)

Lokale UI-Automation (Taps, Screenshots, Batches) über die Accessibility-API — nützlich für schnelle Smokes und Agent-Workflows.

- **Install:** `brew tap cameroncooke/axe && brew install axe`
- **Build, App starten, Smoke-Batch:** `./scripts/build-run-and-axe.sh`  
  Optional: `SIMULATOR_NAME`, `AXE_LAUNCH_WAIT_SECONDS` (Standard 4), `AXE_STEPS_FILE`, `AXE_VERBOSE=1`
- **Nur Batch** (Simulator muss laufen, App idealerweise im Vordergrund): `./scripts/run-axe-batch.sh` oder `./scripts/run-axe-batch.sh pfad/zu.flow.steps`
- **Schritte:** `scripts/axe/fuelnow-smoke.steps` anpassen — `axe batch` unterstützt **keine** `screenshot`-Zeilen (nur Interaktion + `sleep`). `run-axe-batch.sh` ruft danach **immer** `axe screenshot` auf (**auch wenn der Batch fehlschlägt**), Standardausgabe **`scripts/axe/output/fuelnow-launch.png`**. Ohne PNG: `AXE_SKIP_POST_SCREENSHOT=1`; eigener Pfad (z. B. Linear-Nachweis): `AXE_SCREENSHOT_PATH="$HOME/Desktop/TAN-XX-kurz.png"`.

## Siri & Kurzbefehle — QA ([TAN-53](https://linear.app/tankradar-app/issue/TAN-53/siri-shortcuts-qa-edge-cases-ohne-carplay-map))

Manuelle Checkliste (Shortcuts-App, Siri DE/EN, Edge Cases, **ohne CarPlay**): **`docs/SiriShortcutsQA.md`**. Screenshots/Videos lokal erzeugen (**nicht** ins Repo) und am Linear-Issue **anhängen**.
