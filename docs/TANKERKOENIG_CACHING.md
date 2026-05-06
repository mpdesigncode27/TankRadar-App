# ADR — Tankerkönig-Caching-Strategie (Free Tier)

| | |
| --- | --- |
| **Linear** | [TAN-82](https://linear.app/tankradar-app/issue/TAN-82) (Parent: [TAN-41 — Phase 9 Appwrite-Integration](https://linear.app/tankradar-app/issue/TAN-41)) |
| **Status** | Accepted, 2026-05-06 |
| **Geltung** | bis Pfad **E** (kommerzieller Tankerkönig-Vertrag) verhandelt ist — danach Re-Evaluation |
| **Kontextquellen** | [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/), [`info`-Seite](https://creativecommons.tankerkoenig.de/?page=info), `.cursor/skills/tankerkoenig-api/SKILL.md` |

## Kurzfassung

> **Wir spiegeln Tankerkönig-Daten nicht in eine eigene DB mit periodischer (z. B. stündlicher) Aktualisierung.** Das ist im Free Tier explizit verboten, führt zur Sperrung des API-Keys und liefert ohnehin veraltete Preise. Default bleibt **On-Demand**. Wir verbessern stattdessen den **Client-Cache** (`TAN-83`, Pfad A) und legen einen separaten **Stammdaten-Cache** an (`TAN-84`, Pfad C). Ein **server-seitiger On-Demand-Edge-Cache** (`TAN-85`, Pfad B) bleibt als Spike im Backlog hinter `TAN-66` (Appwrite SDK). Echtes Server-seitiges Mirroring ist erst nach einem **kommerziellen Tankerkönig-Vertrag** (Pfad E) zulässig — Business-Thema, nicht jetzt.

## Kontext

FuelNow holt Tankstellen-Preise heute on-demand pro User-Bewegung über
[`FuelNow/Services/TankerkoenigClient.swift`](../FuelNow/Services/TankerkoenigClient.swift)
(eingeführt in [TAN-14](https://linear.app/tankradar-app/issue/TAN-14)). Ein
Caching Layer war in TAN-14 explizit Out of Scope.
[`FuelNow/Services/StationStore.swift`](../FuelNow/Services/StationStore.swift)
hat heute nur einen 30 s + 500 m Debounce — gegen GPS-Jitter, nicht als Cache.

In Diskussion war: ein periodischer (z. B. stündlicher) Server-Cron pollt
Tankerkönig, schreibt Preise und Stammdaten in eine eigene DB (Appwrite),
und die App liest aus der DB statt direkt aus Tankerkönig.

## Was Tankerkönig dazu sagt

Wörtlich aus [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/),
Abschnitte „API-Requests" und „Massendaten":

> „Apps, Websites und andere Systeme: Requests on Demand — auf Useraktion —
> durchführen. **Regelmäßige, nicht explizit vom User initiierte Requests
> sind zu vermeiden.**"

> „Für bestimmte Anwendungen ist es sinnvoll Spritpreise vieler Tankstellen
> aktuell zur Verfügung zu haben. **Die API ist dazu allerdings nicht geeignet
> und Versuche, das durchzuführen werden geblockt (und API-Keys deaktiviert).**
> Falls Bedarf besteht, die kompletten Tankstellendaten auf eigenen Servern
> zur Verbraucherinformation oder Forschungszwecken zu spiegeln, oder
> regelmäßig für viele Tankstellen Informationen zu holen: bitte mit uns in
> Kontakt treten, wir werden zusammen eine Lösung finden."

Zusätzliche harte Limits aus derselben Seite und aus
`.cursor/skills/tankerkoenig-api/SKILL.md`:

- **1 Request/Minute** pro Key (Free Tier).
- **Suchradius ≤ 25 km** (`list.php`-Parameter `rad`).
- **Bis zu 10 IDs** pro `prices.php`.
- **CC BY 4.0** Attribution für Spritpreis-Daten; **BY-NC-SA-4.0** für die
  historischen CSV-Dumps (kommerzielle Nutzung dort nur per Vertrag).
- **MTS-K-Vorgabe:** Apps dürfen Ergebnisse **nicht filtern**, wenn der User
  es nicht explizit so verlangt hat.
- API darf nicht von Mineralöl- oder Tankstellen-Unternehmen oder deren
  IT-Dienstleistern verwendet werden — irrelevant für FuelNow, aber im Hinterkopf.

## Optionen

### A — Besserer Client-Cache *(beschlossen, [TAN-83](https://linear.app/tankradar-app/issue/TAN-83))*

Region-Bucket (z. B. H3-Zelle oder gerundete Koordinaten) als Cache-Key,
TTL ~3–5 min für Preise, Persistenz über App-Neustart, Pull-to-Refresh
bypasst die TTL.

| Aspekt | Bewertung |
| --- | --- |
| Tankerkönig-Konformität | klar **konform** — bleibt user-initiated |
| Komplexität | gering, lokal in `StationStore` |
| Effekt | weniger Re-Fetches bei kurzem Hin-und-Her im selben Areal, weniger Akku/Datenverbrauch |
| Risiko | niedrig (Cache nur aus User-Aktion gespeist) |

### B — On-Demand-Edge-Cache *(Spike im Backlog, [TAN-85](https://linear.app/tankradar-app/issue/TAN-85))*

Appwrite Function als dünner Tankerkönig-Proxy mit Region-Hash + 3–5 min
TTL. **Kein Cron, kein Hintergrund-Polling.** Cache-Hit nur, wenn ein
realer User-Request auf den Endpunkt trifft; mehrere User in derselben
Zelle teilen sich die Antwort (Single-Flight für gleichzeitige Misses).

| Aspekt | Bewertung |
| --- | --- |
| Tankerkönig-Konformität | **grenzwertig** — formell user-initiated, aber bei genug Skalierung sieht Tankerkönig sehr regelmäßige Hits aus einer einzigen Quelle. Vor Production muss Tankerkönig informiert/befragt werden. |
| Komplexität | mittel (Function, Hash, Single-Flight, Attribution-Forwarding, Auth) |
| Effekt | bei wachsender Userbase deutliche Entlastung des Free-Tier-Budgets |
| Risiko | mittel (Key-Sperrung möglich, wenn Pattern doch zu sehr nach Mirror aussieht) |
| Abhängigkeit | [TAN-66](https://linear.app/tankradar-app/issue/TAN-66) (Appwrite SDK), [TAN-82](https://linear.app/tankradar-app/issue/TAN-82) (diese ADR) |

### C — Static-Base-Data-Cache *(beschlossen, [TAN-84](https://linear.app/tankradar-app/issue/TAN-84))*

Stationsstammdaten (Name, Brand, Adresse, Geo, Öffnungszeiten) lange cachen
(Tage/Wochen, persistiert), Preise weiter live aus `list.php`. `detail.php`
nutzt den Stammdaten-Cache als Backing-Store.

| Aspekt | Bewertung |
| --- | --- |
| Tankerkönig-Konformität | **konform** — Stammdaten ändern sich kaum, kein periodisches Refresh nötig |
| Komplexität | gering–mittel (saubere Trennung Stammdaten/Preise im Datenfluss) |
| Effekt | spürbar weniger `detail.php`-Aufrufe, schneller Detail-Sheet, robustere Offline-UX |
| Risiko | niedrig |

### D — Geplanter Backend-Mirror mit Cron *(verworfen)*

Server-seitiger Cron, der Tankerkönig regelmäßig (z. B. stündlich) pollt
und Preise/Stammdaten in eine eigene DB schreibt; App liest aus DB statt
aus Tankerkönig.

**Verworfen.** Begründung:

1. **Verstößt frontal gegen die Free-Tier-Bedingungen.** Tankerkönig sagt
   wörtlich: *„Versuche, das durchzuführen werden geblockt (und API-Keys
   deaktiviert)."*
2. **Stale Prices.** Spritpreise ändern sich am Tag mehrfach. Eine
   stündliche Sicht macht das Kernversprechen „günstigste Tankstelle in
   der Nähe" unzuverlässig.
3. **Doppelte Compliance-Verantwortung.** Sobald wir Daten persistieren
   und ausliefern, sind wir selbst datenverarbeitende Stelle (CC BY 4.0,
   MTS-K „keine Filterung", Storage-Pflichten).

D ist **kein eigenes Linear-Ticket**, weil es bewusst nicht gemacht wird —
diese ADR ist die Begründung, falls die Frage in einem späteren Ticket
wieder hochkommt.

### E — Kommerzieller Tankerkönig-Vertrag *(später, kein Ticket jetzt)*

Tankerkönig bietet im Bereich „Kommerzieller Service" einen dedizierten
Server bzw. einen regelmäßigen Daten-Dump in JSON/XML/CSV gegen monatliche
Gebühr an. Das ist der **einzige legale Weg** für serverseitiges Mirroring.

E wird **nicht jetzt** angegangen, weil:

1. FuelNow Plus generiert noch keinen Umsatz, mit dem sich monatliche
   Datengebühren rechnen.
2. Vor Vertragsverhandlung sollten die Spikes in B Daten liefern, ob ein
   Edge-Cache mit Free Tier ausreicht.

E wird re-evaluiert, sobald die Subscription-Erlöse stabil sind oder das
B-Spike eindeutig zeigt, dass Free Tier nicht trägt. Re-Evaluation gehört
in ein dann neu zu erstellendes Business-Ticket unter
[TAN-41](https://linear.app/tankradar-app/issue/TAN-41).

## Entscheidung

1. **D ist verworfen** und bleibt verworfen, solange diese ADR gilt.
2. **Default-Architektur bleibt On-Demand** (`TankerkoenigClient` direkt
   aus dem Client). Diese ADR macht keine Code-Änderung an
   `TankerkoenigClient` oder `StationStore` — nur einen Doc-Header-Hinweis.
3. **A** wird als nächstes umgesetzt ([TAN-83](https://linear.app/tankradar-app/issue/TAN-83)).
4. **C** folgt ([TAN-84](https://linear.app/tankradar-app/issue/TAN-84)).
5. **B** bleibt als Spike im Backlog ([TAN-85](https://linear.app/tankradar-app/issue/TAN-85)),
   abhängig von [TAN-66](https://linear.app/tankradar-app/issue/TAN-66).
6. **E** wird re-evaluiert, wenn FuelNow-Plus-Umsatz das rechtfertigt.

## Konsequenzen

- **Codebasis:** keine Architektur-Änderung in diesem Ticket. `StationStore`
  und `TankerkoenigClient` bleiben wie sie sind, bekommen aber einen
  Doc-Header-Verweis auf diese ADR, damit spätere PRs den Mirror-Pfad nicht
  versehentlich öffnen.
- **Operations:** Solange kein Vertrag mit Tankerkönig existiert, läuft
  jede Anfrage über den User-Schlüssel des aktuellen Devices. Limits aus
  dem Free Tier (1/min, 25 km, 10 IDs) bleiben harte Constraints für die
  Folge-Tickets.
- **Compliance:** CC-BY-Attribution muss in der App und im App-Store-Text
  sichtbar bleiben — siehe [`docs/PRODUCT_SPEC.md`](PRODUCT_SPEC.md). MTS-K-„keine
  Filterung"-Regel bleibt eine Einschränkung für jede zukünftige Such- oder
  Sort-UI.
- **Datenschutz:** Solange wir nicht serverseitig persistieren, fließen
  keine User-Standorte über FuelNow-Server. Pfad B würde das ändern und
  braucht eine ergänzte Privacy-Policy-Beschreibung.

## Re-Evaluation / Triggers

Diese ADR sollte überprüft werden, wenn einer dieser Punkte eintritt:

- Tankerkönig ändert die Free-Tier-Bedingungen (z. B. höheres Quota oder
  Mirror-Erlaubnis).
- FuelNow Plus erreicht eine Erlösschwelle, die Pfad E rechtfertigt.
- TAN-85 (Spike B) liefert einen klaren positiven Befund von Tankerkönig
  („Pattern ist OK") oder einen klaren negativen.
- Die App stößt regelmäßig an die 1/min-Grenze, sodass A + C nicht reichen.

In allen Fällen: neues Linear-Ticket unter
[TAN-41](https://linear.app/tankradar-app/issue/TAN-41), das diese ADR
revidiert oder durch eine neue ersetzt.
