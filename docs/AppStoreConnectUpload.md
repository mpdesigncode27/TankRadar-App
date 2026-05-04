# App Store Connect — IPA & TestFlight

Das Repo nutzt **`./scripts/asc.sh`** → **Fastlane** mit einem **App Store Connect API Key** (JWT). Das ist der projektinterne „ASC“-Wrapper (nicht das externe CLI von [asccli.sh](https://asccli.sh)).

## Voraussetzungen

1. App-Eintrag in App Store Connect für **`com.vibecoding.FuelNow`** (einmalig in der Web-UI).
2. API Key unter *Users and Access → Integrations → App Store Connect API* mit ausreichender Rolle für Builds.
3. **Signing:** Xcode *Release* mit Automatic Signing auf dem Mac, der archiviert. **`fastlane/Appfile`** → `team_id` muss dieselbe **Apple Team ID** sein wie unter *Signing & Capabilities* / `DEVELOPMENT_TEAM` im Xcode-Projekt (Mitgliedschaft: [developer.apple.com/account](https://developer.apple.com/account) → Membership details).

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
| `ASC_EXPORT_TEAM_ID` | Optional: 10-stellige Team-ID, falls `gym` beim Export das Team nicht eindeutig zuordnet |

## Fehler: „No profiles for 'com.vibecoding.FuelNow' were found“ (Export)

Das **Archiv** kann erfolgreich sein, der Schritt **`exportArchive`** scheitert trotzdem: für die Bundle-ID fehlt ein **Distribution-/App-Store-Provisioning-Profil** (oder Xcode hat es noch nicht geladen).

**Checkliste:**

1. **[Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)**  
   - Identifier **`com.vibecoding.FuelNow`** existiert.  
   - Unter *Profiles* gibt es ein **App Store**-Profil für genau diese App-ID — oder du nutzt **Automatic Signing** und lässt Xcode das erzeugen.

2. **Xcode** → Target **FuelNow** → **Signing & Capabilities**  
   - Gleiches **Team** wie im Projekt / `fastlane/Appfile`.  
   - Keine roten Signing-Warnungen; ggf. **„Try Again“** oder Team kurz wechseln und zurück.  
   - **Product → Clean Build Folder**, dann erneut `./scripts/asc.sh ios asc_build_appstore_ipa`.

3. **Xcode → Settings → Accounts** → dein Team → **Download Manual Profiles** (hilft manchmal nach neuem Bundle-ID).

4. Wenn du mehrere Teams hast: in `.env.asc.local` z. B.  
   `export ASC_EXPORT_TEAM_ID="XXXXXXXXXX"`  
   (Team-ID aus der Mitgliedschaftsseite).

Hinweis: Ein Archiv, das mit **„Apple Development“** signiert wurde, reicht für den App-Store-Export nicht — nach korrekter Einrichtung sollte der Export **„Apple Distribution“** / App-Store-Profil verwenden (bei Automatic Signing in der Regel automatisch nach Schritt 2).
