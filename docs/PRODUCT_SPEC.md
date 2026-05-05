# FuelNow — Produktspezifikation (Index)

Diese Datei ist die **zentrale Einstiegs-Spezifikation** im Repo: Kurzfassung von Produkt, Konventionen und Verweisen. Sie ersetzt keine Detail-Specs in Linear oder Code — bei Abweichungen gilt **Linear-Issue + Implementierung**, und dieser Index soll angepasst werden.

## Produktüberblick

- **FuelNow** ist eine native iOS-App: Tankstellen in der Nähe auf der Karte, Öffnungsstatus und Preise; Kraftstoffsorte (z. B. Super, Super95, Diesel) in den Einstellungen.
- **Daten:** Tankerkönig (Deutschland); API-Details und Decoding-Fallen: [`.cursor/skills/tankerkoenig-api/SKILL.md`](../.cursor/skills/tankerkoenig-api/SKILL.md).
- **Geplant / Roadmap:** Siri (nächste/günstigste Station), CarPlay-kartenlastig, Abo-Gate (CarPlay u. a. für Abonnenten; Preisrichtung z. B. ~6 €/Jahr — finale Preise über StoreKit, nicht hardcodieren).
- **Backend-Richtung:** Appwrite (Swift SDK) — siehe Architektur-/Ticket-Kontext in Linear.

## Naming / Repo

- Produkt-Target: **FuelNow**. Historisch heißen Repo-Pfad und Remote weiter **TankRadar** — bewusster Mismatch, nicht „bereinigen“ ohne Abstimmung.

## Technische Konstanten

| Thema | Wert / Ort |
| --- | --- |
| Bundle-ID | `com.vibecoding.fuelnow` |
| Tankerkönig-Key (Simulator/Debug) | `README.md`, `FuelNow/Support/APIKeys.example.swift` — nie Key committen |
| Plus-Abo Product-ID | `com.vibecoding.fuelnow.subscription.year` (`SubscriptionConstants`, `FuelNowPlus.storekit`) |

## Kernflows (Nutzer)

1. Karte öffnen → Standort → Stationen laden → Annotation auswählen → Details (Preis, Status).
2. Einstellungen → Kraftstoffsorte (und weitere App-Einstellungen).
3. (Roadmap) Siri / Kurzbefehle, CarPlay, Subscription.

## UI-Konventionen (FuelNow)

- Öffnungsstatus: **farbiger Punkt** (grün offen / rot zu), kein separates Status-Icon.
- Preise: **zwei Nachkommastellen** (z. B. `1,89`), **ohne** „€/l“-Label in der Anzeige.
- „In Apple Maps öffnen“: **Turn-by-turn-Navigation** zur Station, nicht nur Kartenansicht.
- Sheets: **Schließen-Icon**, kein „Fertig“-Button als Standard.

## Nicht-Ziele dieses Dokuments

- Keine vollständige API-Referenz (Tankerkönig-Skill + offizielle Doku).
- Keine Release- oder ASC-Schrittfolge (siehe `README.md` und `docs/AppStoreConnectUpload.md`).
- Keine testbare Akzeptanzkriterien pro Feature — die stehen in **Linear** mit DoD und Checkboxen.

## Verweise (Specs verteilt)

| Bereich | Dokument / Ort |
| --- | --- |
| Betrieb, Keys, StoreKit, AXe | [README.md](../README.md) |
| Agent-/Team-Workflow, Backlog-Reihenfolge, Kurzfakten | [AGENTS.md](../AGENTS.md) |
| Siri & Kurzbefehle QA | [docs/SiriShortcutsQA.md](SiriShortcutsQA.md) |
| App Store Connect Upload | [docs/AppStoreConnectUpload.md](AppStoreConnectUpload.md) |
| Light/Dark & Linear-Tickets | [docs/LightDarkModeLinearTickets.md](LightDarkModeLinearTickets.md) |
| Tankerkönig API | [`.cursor/skills/tankerkoenig-api/SKILL.md`](../.cursor/skills/tankerkoenig-api/SKILL.md) |
| SDD-Arbeitsweise (Planung/Umsetzung/Audit) | [`.cursor/skills/sdd-*.md`](../.cursor/skills/) |
| Feature-Scope, Akzeptanzkriterien, Epics | [Linear — FuelNow App](https://linear.app/tankradar-app) |

## Pflege

Nach größeren Produkt- oder Branding-Änderungen: dieses Index-Dokument und ggf. erste Absätze in `README.md` / `AGENTS.md` abstimmen. Detailed Specs bleiben in Linear pro Ticket nachziehbar.
