# CarPlay — Capability, Entitlement & Apple-Antrag

Gehört zu **Linear-Ticket TAN-54** (Phase 7) und bereitet die CarPlay-Folge-Tickets
[TAN-55](https://linear.app/tankradar-app/issue/TAN-55) (POI/Liste/Detail mit Plus)
und [TAN-57](https://linear.app/tankradar-app/issue/TAN-57) (Limited UX ohne Plus) vor.

> **Kategorie:** CarPlay Fueling (`com.apple.developer.carplay-fueling`, iOS 16+).
> **Template-Tiefe:** max. 3 Templates (Fueling-Limit laut HIG).
> **Plus-Gating:** Volle POI-Erfahrung nur für FuelNow-Plus-Abonnent\:innen
> (TAN-44 / TAN-45). Free-Nutzer\:innen erhalten Plan B (siehe unten).

---

## 1. Operationaler Antrag bei Apple

### 1.1 Antrag stellen

URL: <https://developer.apple.com/contact/carplay/>

Ausfüllen mit dem unten stehenden Antragsdraft. Apple antwortet typisch in 1–2
Wochen mit einer Tracking-ID. Diese **im Linear-Ticket TAN-54 als Kommentar
hinterlegen** (idealerweise mit Screenshot/Mail).

### 1.2 Antragsdraft

> **App:** FuelNow (Bundle-ID `com.vibecoding.fuelnow`, Apple-ID-Reservierung
> bereits via TAN-73 erfolgt).
>
> **Kategorie:** **CarPlay Fueling** (`com.apple.developer.carplay-fueling`).
> Wir beantragen ausschließlich diese Kategorie — **nicht** Navigation oder
> andere Categories.
>
> **Funktion:** FuelNow ist ein Tankstellenpreis-Finder für Deutschland. Die
> iPhone-App zeigt umliegende Tankstellen (Datenquelle: Tankerkönig / MTS-K,
> CC BY 4.0) inklusive aktueller Preise pro Sorte und Öffnungsstatus auf
> einer Karte. Nutzer\:innen wählen ihre bevorzugte Kraftstoffsorte (E5, E10,
> Diesel); die App zeigt immer alle Tankstellen im maximal von Tankerkönig
> erlaubten 25-km-Umkreis (TAN-79) und ermöglicht von dort eine
> Tankstellen-Routenführung in Apple Maps.
>
> **CarPlay-Erfahrung:** Während der Fahrt zeigt FuelNow die nächsten und
> günstigsten Tankstellen entlang oder im Umkreis als POIs
> (`CPPointOfInterestTemplate`) und ermöglicht das Übergeben einer Tankstelle
> an Apple Maps für die Routenführung. Eingaben sind auf eine sehr flache
> Tiefe begrenzt (max. 3 Templates laut Apple Fueling-Guideline). Wir nutzen
> ausschließlich Standard-Templates (`CPPointOfInterestTemplate`,
> `CPListTemplate`, `CPInformationTemplate`).
>
> **Monetarisierung:** Die volle CarPlay-Funktionalität ist Teil des
> kostenpflichtigen Jahresabos „FuelNow Plus“ (StoreKit 2, 6 €/Jahr). Free-
> Nutzer\:innen erhalten in CarPlay einen ehrlichen Hinweis-Screen
> (`CPInformationTemplate` „FuelNow Plus aktivieren auf dem iPhone…“),
> **ohne** Pseudo-POI-Daten oder Dark Patterns.
>
> **Datenquellen:** Tankerkönig-API (CC BY 4.0, MTS-K als Originalquelle).
> Standortdaten kommen ausschließlich vom Gerät (CoreLocation, „While Using
> the App“-Berechtigung) — keine externen Trackingsysteme.
>
> **Begründung der Fueling-Kategorie:** FuelNow erfüllt das Apple-Kriterium
> für Fueling-Apps („station locations, pump control, payment“) im Bereich
> *station locations* vollständig; Pumpensteuerung und Bezahlung sind nicht
> Teil unseres Funktionsumfangs und wurden nie behauptet. Wir beantragen
> bewusst **keine** Navigation- oder Maps-Entitlements, da wir Routenführung
> an Apple Maps übergeben statt eigene Turn-by-Turn-UI zu rendern.
>
> **Plan B bei Verweigerung:** Sollte Apple das Fueling-Entitlement nicht
> erteilen, fahren wir mit der iPhone-App ohne CarPlay aus. Die
> CarPlay-spezifischen Code-Pfade sind durch Compile-Time-Flags gegen das
> Hauptbundle entkoppelt; ein Folge-Ticket würde sie sauber entfernen.

### 1.3 Akzeptanzkriterium TAN-54 → Linear-Kommentar

Sobald der Antrag raus ist, im Linear-Ticket TAN-54 ergänzen:

* **Datum / Uhrzeit** des Submits
* **Tracking-ID** aus Apples Bestätigungsmail
* **Screenshot** der eingereichten Felder (oder Bestätigungs-Mail)
* **Apple-Status** (Pending/Approved/Rejected) plus Update sobald Antwort kommt

---

## 2. Technische Vorbereitung im Code (dieses Ticket)

### 2.1 Entitlements-Datei

`FuelNow/FuelNow.entitlements` ist neu angelegt und im Build-Setting
`CODE_SIGN_ENTITLEMENTS = FuelNow/FuelNow.entitlements` (Debug + Release)
verlinkt. Inhalt:

```xml
<key>com.apple.developer.carplay-fueling</key>
<true/>
```

* **Simulator-Builds** (z. B. `./scripts/build-and-run-simulator.sh`):
  funktionieren weiterhin, weil der Simulator das Entitlement nicht gegen
  ein Provisioning-Profil prüft.
* **Device-Builds** (TestFlight/Release): scheitern in der Code-Signing-Phase,
  bis Apple das Entitlement im Provisioning-Profil freigegeben hat
  (`com.apple.developer.carplay-fueling`). Vor dem Apple-Approval also
  weiterhin nur Simulator-Build. Nach Approval: kein Code-Change nötig — das
  Provisioning-Profil zieht das Flag automatisch.

> Die Entitlements-Datei ist absichtlich **jetzt schon committed**, damit nach
> dem Approval kein Branch-Race entsteht. Bis dahin ist sie inert.

### 2.2 Scene-Manifest (für TAN-55 vorgesehen)

Aktuell nutzt FuelNow die SwiftUI-`@main App`-Scene (`UIWindowSceneSessionRoleApplication`)
ohne explizites Scene-Manifest (`INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES`).
Damit CarPlay zusätzlich zur iPhone-Scene aktiv wird, muss in **TAN-55** das
Manifest expandiert werden auf etwa:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <!-- iPhone-Scene bleibt SwiftUI-WindowGroup -->
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneClassName</key>
                <string>UIWindowScene</string>
            </dict>
        </array>
        <!-- CarPlay-Scene neu, an Stub-Klasse angekoppelt (TAN-55) -->
        <key>CPTemplateApplicationSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>FuelNow CarPlay Scene</string>
                <key>UISceneClassName</key>
                <string>CPTemplateApplicationScene</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).FuelNowCarPlaySceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

> **Bewusst nicht jetzt aktivieren**, weil der `FuelNowCarPlaySceneDelegate`
> noch nicht existiert. Würde das Manifest jetzt expanded und gleichzeitig der
> Delegate fehlen, würde iOS bei einer CarPlay-Verbindung crashen — was bis
> zum Apple-Approval ohnehin nicht passieren kann, aber sauberer ist es,
> Delegate und Manifest gemeinsam in TAN-55 einzuziehen.

### 2.3 Asset-Compliance

* **App-Icon:** Aktuell ein `1024×1024`-Universal-Asset
  (`FuelNow/Assets.xcassets/AppIcon.appiconset`). Für CarPlay (iOS 26+) reicht
  das, da Apple das App-Icon-Set vereinheitlicht und CarPlay daraus die
  passende Variante zieht. Kein zusätzliches `CarPlay`-AppIcon-Set nötig.
* **POI-Pin / List-Item-Glyphen:** SF-Symbols sind die offizielle Empfehlung
  laut CarPlay HIG (44×44 pt). Konkrete Symbole (`fuelpump.fill`, `leaf.fill`,
  `fuelpump.circle.fill`) liegen bereits in `FuelType.settingsCardSymbolName`
  (siehe `FuelTypePresentation.swift` aus TAN-78) und sind 1:1 für CarPlay
  wiederverwendbar.
* **Tab-Bar-Icons:** Werden in TAN-55 ergänzt, falls eine `CPTabBarTemplate`
  zum Einsatz kommt — sonst brauchen wir keine.

### 2.4 Plan B — CPInformationTemplate ohne Plus / ohne Approval

Falls Apple das Entitlement verweigert oder Nutzer\:innen kein Plus-Abo haben,
zeigen wir in CarPlay einen ehrlichen Hinweis statt Pseudo-POIs. Pseudocode-Skizze
für TAN-57:

```swift
// In FuelNowCarPlaySceneDelegate.templateApplicationScene(_:didConnect:):
let infoTemplate = CPInformationTemplate(
    title: String(localized: "carplay.limited.title"),
    layout: .leading,
    items: [
        CPInformationItem(
            title: String(localized: "carplay.limited.body"),
            detail: nil
        )
    ],
    actions: []
)
interfaceController.setRootTemplate(infoTemplate, animated: false)
```

* **Copy-Idee:** „Öffne FuelNow auf dem iPhone, um CarPlay zu nutzen.“ /
  „Open FuelNow on iPhone to use CarPlay.“
* **Keine** Marketing-Animationen, kein Subscribe-CTA in CarPlay
  (Driver-Distraction-Vorgabe).

---

## 3. Testing-Notiz

* **CarPlay-Simulator** in Xcode öffnen via *Simulator → I/O → External Displays
  → CarPlay* (Standard-Workflow). Vor dem Apple-Approval kann FuelNow dort
  **nicht** als Fueling-App erscheinen, weil das Entitlement im
  Provisioning-Profil fehlt — geplante Verifikation also erst in TAN-55 nach
  Approval (oder gegen ein Wildcard-Profile, falls verfügbar).
* **Unit-Tests** sind aktuell nicht betroffen (keine CarPlay-Code-Pfade in
  diesem Ticket).
