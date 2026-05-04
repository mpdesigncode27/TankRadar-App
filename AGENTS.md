## Learned User Preferences

- Git ticket branches must branch off **updated `main`** only (never off another feature branch). Prefer branch names **`feature/TAN-XX-short-slug`** — avoid Linear/GitHub-style prefixes such as `mpdesigncode27/` before the ticket slug.
- Before implementing tickets that involve Tankerkönig (API shapes, networking, station/price models), read `.cursor/skills/tankerkoenig-api/SKILL.md`, verify the ticket matches the real API, and update the Linear issue if specs drift.
- When marking a Linear ticket complete, attach at least one screenshot or short screen recording of the implementation to the issue (Simulator or device), unless the work is purely non-visual—in that case attach an alternative proof such as an Xcode test-run screenshot and note it in the closing comment. Store capture files under **`.linear-evidence/`** (gitignored); naming pattern **`TAN-XX-short-description.png`** (or `.mov`/`.mp4`). See `.cursor/rules/ticket-branch-workflow.mdc` § „Visueller Nachweis — konkret“.
- When planning SDD-style work, track scope with Linear issues per task and keep those issues updated as implementation progresses.
- Linear issues should include explicit acceptance criteria so completion can be verified objectively.
- Linear issues should include a concise opening statement of the ticket’s goal and intended outcome.
- Expectations include strong Swift and SwiftUI quality, automated tests where appropriate, and alignment with current Apple Human Interface Guidelines alongside Liquid Glass styling.

## Learned Workspace Facts

- TankRadar is a native iOS app that shows nearby fuel stations on a map with opening status and prices; users choose a fuel grade (e.g. Super, Super95, Diesel) in settings.
- Planned capabilities include Siri-driven queries for nearest or cheapest nearby stations, a CarPlay map-centric experience, and a subscription gate where CarPlay is enabled only for subscribers (initial placeholder pricing discussed at €6 per year).
- Planning and architecture references German station data via Tankerkönig and backend/services direction involving Appwrite (Swift SDK).
- Primary Git remote for the project is https://github.com/mpdesigncode27/TankRadar-App.git.
- **Linear backlog order (TankRadar App):** Prefer completing **remaining Phase 1** (`TAN-5` children) before picking up later phase work: **`TAN-73`** (Bundle-ID / App Store Connect / App Icon) and **`TAN-72`** (Tankerkönig API-Key) are intentionally parallel; then the design-system chain **`TAN-74` → `TAN-75` → `TAN-76`** (split described under **`TAN-71`**). After Phase 1 gaps needed for networking are closed, continue **Phase 2** (`TAN-6`) with **`TAN-14`** → **`TAN-15`** (models `TAN-12` and location `TAN-13` are Done). *Re-assess this pointer whenever Linear statuses change.*
