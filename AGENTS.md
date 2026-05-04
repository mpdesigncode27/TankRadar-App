## Learned User Preferences

- Git ticket branches must branch off **updated `main`** only (never off another feature branch). Prefer branch names **`feature/TAN-XX-short-slug`** — avoid Linear/GitHub-style prefixes such as `mpdesigncode27/` before the ticket slug.
- Before implementing tickets that involve Tankerkönig (API shapes, networking, station/price models), read `.cursor/skills/tankerkoenig-api/SKILL.md`, verify the ticket matches the real API, and update the Linear issue if specs drift.
- When planning SDD-style work, track scope with Linear issues per task and keep those issues updated as implementation progresses.
- Linear issues should include explicit acceptance criteria so completion can be verified objectively.
- Linear issues should include a concise opening statement of the ticket’s goal and intended outcome.
- Expectations include strong Swift and SwiftUI quality, automated tests where appropriate, and alignment with current Apple Human Interface Guidelines alongside Liquid Glass styling.

## Learned Workspace Facts

- TankRadar is a native iOS app that shows nearby fuel stations on a map with opening status and prices; users choose a fuel grade (e.g. Super, Super95, Diesel) in settings.
- Planned capabilities include Siri-driven queries for nearest or cheapest nearby stations, a CarPlay map-centric experience, and a subscription gate where CarPlay is enabled only for subscribers (initial placeholder pricing discussed at €6 per year).
- Planning and architecture references German station data via Tankerkönig and backend/services direction involving Appwrite (Swift SDK).
- Primary Git remote for the project is https://github.com/mpdesigncode27/TankRadar-App.git.
