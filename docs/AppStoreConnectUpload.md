# App Store Connect — IPA & TestFlight

Das Repo nutzt **`./scripts/asc.sh`** → **Fastlane** mit einem **App Store Connect API Key** (JWT). Das ist der projektinterne „ASC“-Wrapper (nicht das externe CLI von [asccli.sh](https://asccli.sh)).

## Voraussetzungen

1. App-Eintrag in App Store Connect für **`com.vibecoding.FuelNow`** (einmalig in der Web-UI).
2. API Key unter *Users and Access → Integrations → App Store Connect API* mit ausreichender Rolle für Builds.
3. **Signing:** Xcode *Release* mit Automatic Signing auf dem Mac, der archiviert.

## Konfiguration

Vorbild: `fastlane/asc-env.template`. Datei **`.env.asc.local`** im Repo-Root anlegen (gitignored).

```bash
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ASC_KEY_PATH="$HOME/AuthKey_XXXXXXXXXX.p8"
```

Prüfen:

```bash
./scripts/asc.sh ios asc_verify
```

## Build & Upload

Ein Befehl (Release-Archive, Export, Upload zu TestFlight):

```bash
./scripts/asc.sh ios asc_ship_testflight
```

Nur IPA bauen:

```bash
./scripts/asc.sh ios asc_build_appstore_ipa
# → build/FuelNow.ipa
```

Nur Upload:

```bash
IPA_PATH="$PWD/build/FuelNow.ipa" ./scripts/asc.sh ios asc_upload_ipa
```

Vor dem ersten Lauf: `bundle install` im Repo-Root.

## Optional

| Variable | Bedeutung |
| --- | --- |
| `ASC_SKIP_WAIT=1` | Nicht auf Processing in ASC warten |
| `ASC_WHATS_NEW` | „What to Test“ für TestFlight |
