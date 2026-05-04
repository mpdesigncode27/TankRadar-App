# TankRadar

**Tankerkönig-API-Key:** Beantragung und Eintragung über Linear [**TAN-72**](https://linear.app/tankradar-app/issue/TAN-72).

**Lokal im Simulator testen (ohne dass der Key bei Git verloren geht):** Auf dem Mac eine Datei **`~/.tankradar/tankerkoenig-api-key`** mit einer Zeile (UUID) anlegen — die App liest sie im Simulator automatisch (`SIMULATOR_HOST_HOME`). Alternativ Xcode-Scheme: Umgebungsvariable **`TANKERKOENIG_API_KEY`** oder **`TANKERKOENIG_API_KEY_FILE`** mit absolutem Pfad (siehe Kommentar in `APIKeys.example.swift`).

**Datenlizenz:** Tankerkönig / MTS-K — Metadaten in API-Antworten unter **CC BY 4.0**; Details und Attribution: [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/?page=info).
