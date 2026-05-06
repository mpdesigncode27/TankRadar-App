# FuelNow — Code-Stil, Lint & Format

Tooling für SwiftLint und SwiftFormat ist im Repo committed
([Linear TAN-63](https://linear.app/tankradar-app/issue/TAN-63/swiftlint-swiftformat-lokal-build-phase)).
Ziel: Reviews konzentrieren sich auf Architektur, nicht auf Whitespace und
Import-Reihenfolge.

## TL;DR

```bash
brew bundle --file=Brewfile      # einmalig, installiert swiftlint + swiftformat
./scripts/format.sh              # rewrites in place
./scripts/lint.sh                # SwiftLint (Standard: Errors blockieren; Warnings je Regel)
./scripts/lint.sh --strict       # SwiftLint: alle Warnings wie Errors
./scripts/lint.sh --ci           # Merge-Gate: SwiftLint strict + SwiftFormat --lint + Xcode build ohne Compiler-Warnings
./scripts/lint.sh --fix          # autofix + Re-Check
./scripts/format.sh --lint       # CI-Check ohne Schreibvorgang
./scripts/verify-ios-build.sh    # nur Xcode „build“ mit SWIFT_TREAT_WARNINGS_AS_ERRORS (App-Target)
```

| Werkzeug | Pin | Konfig | Wofür zuständig |
| --- | --- | --- | --- |
| **SwiftLint** | `0.63.x` (Brew) | `.swiftlint.yml` | Code-Smells, Bug-Vermeidung, Custom Rules |
| **SwiftFormat** | `0.61.x` (Brew) | `.swiftformat` | Whitespace, Imports, Klammern, Wrapping |

Beide Tools werden über Homebrew gepinnt — `Brewfile` aktualisieren, wenn ein
neuer Major/Minor in den Build-Phase- oder CI-Workflow soll.

## Aufgabenteilung

Damit Auto-Fixes der beiden Tools sich nicht gegenseitig „korrigieren", gilt:

- **Imports** sortiert ausschließlich SwiftFormat (`--import-grouping testable-last`).
  In `.swiftlint.yml` ist `sorted_imports` deshalb deaktiviert.
- **Trailing commas / Brace-Layout** macht SwiftFormat. SwiftLints
  `trailing_comma` und `opening_brace` sind deaktiviert.
- **Modifier-Reihenfolge** prüft SwiftLint (Warning), SwiftFormats
  `modifierOrder`-Auto-Rewriter ist abgeschaltet — sonst geriete jede
  `nonisolated private`-Reihenfolge in einen Fixup-Kreislauf.

## Konservative Defaults

`.swiftformat` aktiviert nur **safe rules** (Whitespace, Imports, Indent,
trailing newlines, redundante Klammern). Aggressive Umschreibungen wie
`conditionalAssignment`, `redundantSendable`, `numberFormatting`, `andOperator`,
`wrapPropertyBodies`, `wrapFunctionBodies`, `hoistPatternLet` und
`unusedArguments` sind explizit `--disable`-d. Wer eine davon doch will,
öffnet ein eigenes Ticket, formatiert dort die betroffenen Dateien gezielt
neu und passt anschließend `.swiftformat` an.

`line_length.error` ist mit `500` bewusst großzügig — Test-Fixtures wie
`QueryServiceTests.swift` enthalten lange JSON-Literale. Die `warning`-Schwelle
liegt weiter bei **140**; einzelne Verstöße bleiben sichtbar, blocken aber
nicht den Build.

## Custom Rule: keine Hex-Literale außerhalb `Design/`

`tr_no_inline_hex_outside_design_system` (Warning) erkennt
`Color(hex:)`, `UIColor(hex:)` und nackte `#RRGGBB`-Literale außerhalb von
`FuelNow/Design/`. Tokens leben in `FuelNow/Design/TRColors.swift`; Tests und
`FuelNow/Support/` (Palette-Fixtures) sind ausgenommen, weil dort gegen
Hex-Werte assertiert wird.

> Stößt du auf eine echte Ausnahme (z. B. eingebettete SVG-Strings), ergänze
> entweder den `excluded:`-Pfad in `.swiftlint.yml` oder lege einen
> `// swiftlint:disable:next tr_no_inline_hex_outside_design_system`-Kommentar
> mit Kurzbegründung über die betroffene Zeile.

## Xcode Integration — Build Phase

Die Lint-Phase läuft als **Run Script** _nach_ „Compile Sources" und
verschmutzt den Build nicht mit Errors (warnings only, damit DEBUG-Builds
weiter ohne Eingriff durchlaufen).

1. In Xcode: **FuelNow Target → Build Phases → + → New Run Script Phase**.
2. Die Phase **„Run SwiftLint"** nennen und _hinter_ „Compile Sources" ziehen.
3. Folgendes Script einfügen (Shell `/bin/sh`):

   ```sh
   if [ "${CONFIGURATION}" = "Release" ]; then
     # Release-Builds (Archive, IPA) sollen schnell durchlaufen.
     exit 0
   fi
   if [ -x "${SRCROOT}/scripts/lint.sh" ]; then
     "${SRCROOT}/scripts/lint.sh"
   else
     echo "warning: scripts/lint.sh nicht gefunden — SwiftLint übersprungen."
   fi
   ```

4. **Input Files** leer lassen, **„Based on dependency analysis"** ausschalten —
   sonst springt Xcode die Phase nach dem ersten Lauf nicht mehr an.
5. Optional dieselbe Phase als „Run SwiftFormat (lint)" mit
   `"${SRCROOT}/scripts/format.sh" --lint` anlegen, wenn formatfehler im Build
   auffallen sollen.

> Die Run-Script-Phase ist **nicht** im Repo committed, weil Xcode bei
> Project-File-Änderungen schnell merge-bröselt. Schritt-für-Schritt-Setup
> liegt hier — wer das Projekt frisch klont und das Tooling will, fügt die
> Phase in zwei Minuten lokal hinzu.

## Git-Hook — pre-commit (optional, empfohlen)

Statt jedes Repo-Mitglied einen Hook manuell installieren zu lassen, liegt der
Hook **versioniert im Repo** unter `scripts/git-hooks/pre-commit`. Aktivierung
einmalig pro Klon:

```bash
git config core.hooksPath scripts/git-hooks
```

Danach läuft vor jedem `git commit`:

- `swiftformat --lint` über alle gestagten `.swift`-Dateien
- `swiftlint lint` über die gestagten Dateien

Kommt es zu einem Diff oder Lint-Error, bricht der Commit ab. Aushebeln im
Notfall: `git commit --no-verify` (sparsam einsetzen, im PR begründen).

## CI / Merge-Gate

**Empfohlen vor PR / auf CI:** `./scripts/lint.sh --ci`

Das führt aus:

1. **SwiftLint** mit `--strict` (Projektweit).
2. **SwiftFormat** `--lint` (Projektweit).
3. **`xcodebuild build`** für das Scheme **FuelNow** mit  
   `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` und `GCC_TREAT_WARNINGS_AS_ERRORS=YES`  
   (`scripts/verify-ios-build.sh`). Ziel: **keine** Swift-/Clang-Warnings im App-Target.

**Hinweis:** Kein `build-for-testing` unter diesen Flags — Apples **StoreKitTest**-SDK
liefert in älteren Headern Deprecation-Warnings, die sich nicht im App-Code beheben lassen.
Unit-Tests weiter mit `xcodebuild test` (ohne globale „warnings as errors“ für das gesamte SDK)
oder wie in `AGENTS.md` beschrieben.

Umgebungsvariablen für das Verify-Skript (optional): `VERIFY_IOS_SCHEME`,
`VERIFY_IOS_DESTINATION`, `VERIFY_IOS_DERIVED_DATA`.

Einzelchecks: `./scripts/lint.sh --strict`, `./scripts/format.sh --lint`,
`./scripts/verify-ios-build.sh`.

## SwiftLint strict & Zeilenlänge

Das Merge-Gate `./scripts/lint.sh --ci` nutzt SwiftLint **`--strict`** (Warnings zählen wie Errors).
Lange JSON-Fixtures: bevorzugt **physische Zeilenumbrüche innerhalb des JSON** (Whitespace ist in JSON erlaubt)
oder **`Data("""...""".utf8)`** statt `""".data(using: .utf8)!`. Wo ein **Compile-Zwang** der Testing-Bibliothek
eine einzeilige Suite-Trait-Zeichenkette verlangt (z. B. `@Suite(…, .disabled(…))`), kurz **`// swiftlint:disable line_length`**
umschließen und wieder aktivieren.

Ausnahmen dokumentieren — nicht pauschal Regeln global abschalten.
