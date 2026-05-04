# Siri & Kurzbefehle — QA-Checkliste ([TAN-53](https://linear.app/tankradar-app/issue/TAN-53/siri-shortcuts-qa-edge-cases-ohne-carplay-map))

**Zweck:** Manueller Nachweis für Phase 6 — Intents, Siri und Kurzbefehle **ohne CarPlay**. Dieses Dokument ist die Referenz für Ticket **TAN-53**; Ergebnisse und Screenshots gehören als **QA-Report** und **Kommentar** ins Linear-Issue.

**Explizit out of scope hier:** CarPlay-Karte / POI-QA (separat z. B. [TAN-59](https://linear.app/tankradar-app/issue/TAN-59/carplay-sandbox-qa-plus-vs-kein-plus)).

---

## Voraussetzungen

| Check | Notiz |
| --- | --- |
| Build installiert | Debug oder TestFlight — gleiche Version wie Branch/Commit im Ticket verlinken |
| Tankerkönig-Key | Gerät/Simulator gemäß [README](../README.md) und [TAN-72](https://linear.app/tankradar-app/issue/TAN-72) |
| Standort | „Bei Nutzung erlauben“ für realistische nearest/cheapest-Tests |
| Sprachen | Siri mindestens **Deutsch** und **Englisch** einzeln testen (Gerät oder Siri-Sprache wechseln) |

---

## A. Kurzbefehle-App — alle App Shortcuts manuell

Unter **Kurzbefehle → TankRadar** (bzw. nach App-Namen) jeden Shortcut **einmal ausführen** und Ergebnis markieren.

**ApplicationName** in den App-Shortcuts ist der **Anzeigename der App** („TankRadar“).

| Shortcut (Kurztitel) | Erwartung | OK | Anmerkung |
| --- | --- | --- | --- |
| Nächste Tankstelle | Dialog + Snippet; realistische Station oder klarer Fehlertext (kein Ort, API, leerer Radius) | [ ] | |
| Günstigste Tankstelle | Optional Kraftstoffparameter; sonst Standard-Sprit aus Einstellungen | [ ] | |
| TankRadar öffnen | App springt zur Karte; kein hängender Zustand | [ ] | |
| Tankstelle öffnen | Parameter „Tankstelle“ wählen → App öffnet Fokus auf Station (Deep Link), wenn Daten geladen | [ ] | |

---

## B. Siri — Spracheingabe (Gerät empfohlen)

Pro Sprache mindestens **einen** Satz aus der folgenden Liste (oder nah genug, dass Siri den gleichen Intent trifft). Ersetze „TankRadar“ durch den **tatsächlichen App-Namen**, falls abweichend.

### Deutsch

- „Nächste Tankstelle in TankRadar“
- „Wo ist die nächste Tankstelle in TankRadar“
- „Günstigste Tankstelle in TankRadar“
- „Wo ist die günstigste Tankstelle in TankRadar“
- „Öffne TankRadar“ / „Zeig mir TankRadar“
- „Tankstelle in TankRadar öffnen“ (ggf. mit Nachfrage zur Auswahl)

### English

- „Nearest gas station in TankRadar“
- „Where is the nearest gas station in TankRadar“
- „Cheapest gas station in TankRadar“
- „Where is the cheapest gas station in TankRadar“
- „Open TankRadar“ / „Show TankRadar“
- „Open station in TankRadar“

| Sprache | Getestete Phrase(n) | OK | Anmerkung |
| --- | --- | --- | --- |
| DE | | [ ] | |
| EN | | [ ] | |

---

## C. Edge Cases & Dokumentation

| Szenario | Vorgehen | Ergebnis notieren |
| --- | --- | --- |
| App **beendet** (Switcher swipe), dann Shortcut/Siri | Kurzbefehl oder Siri auslösen | App startet / Intent wird bedient ohne Crash |
| Standort **verweigert** | In iOS-Einstellungen für TankRadar deaktivieren, dann nearest/cheapest | Erwartete Fehlermeldung (Intent), kein stiller Fehler |
| Optional: kein Netz / Flugmodus | Nach nearest/cheapest | Nutzerfreundliche Fehlermeldung |

Im **Abschlusskommentar** bei Linear ausdrücklich erwähnen: QA betrifft **nur Siri/Kurzbefehle und iPhone-App** — **kein CarPlay-Map-Claim**.

---

## D. Nachweise ([TAN-53](https://linear.app/tankradar-app/issue/TAN-53) DoD)

1. Screenshots oder kurzes Video (Simulator oder Gerät): mindestens **ein erfolgreicher Kurzbefehl** und **ein Siri-Flow** (DE oder EN).
2. Ablage lokal beliebig (Desktop, Downloads, …), **nicht committen** — z. B. `TAN-53-siri-de.png`, `TAN-53-shortcuts-nearest.mov`.
3. Linear: Dateien **anhängen** + kurzer Kommentar mit Build/Commit und Checkbox-Verweis auf diese Datei.

---

## Implementierungsreferenz (Code)

| Bereich | Dateien |
| --- | --- |
| Shortcuts & Intents | `TankRadar/Intents/TankRadarAppShortcuts.swift`, `StationSearchIntents.swift`, `OpenMapIntents.swift` |
| Deep Link / Karte | `TankRadar/Navigation/TankRadarDeepLink.swift`, `MapDeepLinkStore.swift`, `MapScreen.swift` |
| Snippet UI | `TankRadar/Intents/StationSnippetView.swift` |

Bei Abweichung zwischen dieser Liste und der App: **Ticket-Beschreibung** oder dieses Dokument nachziehen.
