# TankRadar

**Tankerkönig-API-Key:** Beantragung und Eintragung über Linear [**TAN-72**](https://linear.app/tankradar-app/issue/TAN-72).

### Checkliste TAN-72 (betrieblich)

1. Key unter [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) beantragen (Formular, E-Mail bestätigen).
2. Key **nicht** ins Repo: nur lokal — siehe `TankRadar/Support/APIKeys.example.swift` und unten „Simulator“.
3. Team-Secret-Store (z. B. 1Password): Eintrag „TankRadar Tankerkönig API Key“ mit UUID und Hinweis auf Lizenz/CC BY.
4. Repo-Check: `./scripts/verify-api-keys-not-committed.sh` (stellt sicher, dass `APIKeys.swift` nicht getrackt ist). Optional: gezielt `git log -p -S '<kurzes Token aus dem Key>'` — sollte **keine** Treffer liefern.
5. Smoke: App im Simulator oder auf dem Gerät mit gültigem Key starten — Karte lädt echte Stationen (Screenshot oder Logzeile „ok“ im Ticket TAN-72 kommentieren).

**Lokal im Simulator testen (ohne dass der Key bei Git verloren geht):** Auf dem Mac eine Datei **`~/.tankradar/tankerkoenig-api-key`** mit einer Zeile (UUID) anlegen — die App liest sie im Simulator automatisch (`SIMULATOR_HOST_HOME`). Alternativ Xcode-Scheme: Umgebungsvariable **`TANKERKOENIG_API_KEY`** oder **`TANKERKOENIG_API_KEY_FILE`** mit absolutem Pfad (siehe Kommentar in `APIKeys.example.swift`).

**Datenlizenz:** Tankerkönig / MTS-K — Metadaten in API-Antworten unter **CC BY 4.0**; Details und Attribution: [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/?page=info).

## Simulator-UI: [AXe CLI](https://www.axe-cli.com/)

Lokale UI-Automation (Taps, Screenshots, Batches) über die Accessibility-API — nützlich für schnelle Smokes und Agent-Workflows.

- **Install:** `brew tap cameroncooke/axe && brew install axe`
- **Build, App starten, Smoke-Batch:** `./scripts/build-run-and-axe.sh`  
  Optional: `SIMULATOR_NAME`, `AXE_LAUNCH_WAIT_SECONDS` (Standard 4), `AXE_STEPS_FILE`, `AXE_VERBOSE=1`
- **Nur Batch** (Simulator muss laufen, App idealerweise im Vordergrund): `./scripts/run-axe-batch.sh` oder `./scripts/run-axe-batch.sh pfad/zu.flow.steps`
- **Schritte:** `scripts/axe/tankradar-smoke.steps` anpassen — `axe batch` unterstützt **keine** `screenshot`-Zeilen (nur Interaktion + `sleep`). Nach erfolgreichem Batch schreibt `run-axe-batch.sh` standardmäßig **`scripts/axe/output/tankradar-launch.png`** (`axe screenshot`). Ohne PNG: `AXE_SKIP_POST_SCREENSHOT=1`; anderer Pfad: `AXE_SCREENSHOT_PATH`.
