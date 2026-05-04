# App Store Connect — IPA bauen & TestFlight-Upload

Das Repo nutzt **Fastlane** mit einem **App Store Connect API Key** (JWT), nicht Apple-ID-Passwort.

## Voraussetzungen

1. **App-Eintrag** in [App Store Connect](https://appstoreconnect.apple.com/) für `com.vibecoding.TankRadar` (einmalig in der Web-UI anlegen; die API erstellt keine neue App).
2. **API Key** unter *Users and Access → Integrations → App Store Connect API*: Rolle mindestens **App Manager** oder **Admin** + Zugriff auf **Developer** für Uploads.
3. **Signing**: Xcode *Release* mit **Automatic Signing** und gültigem Team (lokal oder CI-Mac mit Zertifikaten).

## Konfiguration

Vorbild für Variablen: `fastlane/asc-env.template`. Im Repo-Root eine Datei **`.env.asc.local`** anlegen (gitignored); `./scripts/asc.sh` sourced sie automatisch.

Beispiel `.env.asc.local`:

```bash
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ASC_KEY_PATH="$HOME/AuthKey_XXXXXXXXXX.p8"
```

Verbindung testen:

```bash
./scripts/asc.sh ios asc_verify
```

## IPA erzeugen

```bash
./scripts/asc.sh ios asc_build_appstore_ipa
```

Ausgabe: `build/TankRadar.ipa` (Ordner `build/` ist gitignored).

## Nur Upload (bestehende IPA)

```bash
export IPA_PATH="$PWD/build/TankRadar.ipa"
./scripts/asc.sh ios asc_upload_ipa
```

Oder mit Parameter:

```bash
./scripts/asc.sh ios asc_upload_ipa ipa:/pfad/zur/App.ipa
```

## Build + Upload

```bash
./scripts/asc.sh ios asc_ship_testflight
```

Nur Upload, Build war schon da:

```bash
./scripts/asc.sh ios asc_ship_testflight skip_build:true ipa:build/TankRadar.ipa
```

## Optional

| Variable | Bedeutung |
| --- | --- |
| `ASC_SKIP_WAIT=1` | Kein Warten auf App Store Connect Processing |
| `ASC_WHATS_NEW` | Kurztext für TestFlight „What to Test“ |

## Hinweise

- Erster Upload kann **Compliance-/Export**-Fragen in App Store Connect erfordern — im Web abschließen.
- Abo-Produkt und Metadaten: siehe [README](../README.md) Abschnitt App Store Connect / [TAN-42](https://linear.app/tankradar-app/issue/TAN-42).
