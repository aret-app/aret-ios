# ARET — instructions for Claude Code and other AI teammates

**Read this file before making changes.** Also read:
- [README.md](README.md) (product overview, in Italian)
- [docs/PRODUCT_AND_STATUS.md](docs/PRODUCT_AND_STATUS.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/REGIONAL_DISCOVERY.md](docs/REGIONAL_DISCOVERY.md)
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- [docs/DATA_SOURCES_AND_SAFETY.md](docs/DATA_SOURCES_AND_SAFETY.md)
- [docs/QA_SCENARIOS.md](docs/QA_SCENARIOS.md)

## Project facts

ARET = native hiking/outdoor iPhone + Apple Watch app.
Swift 6, SwiftUI, iOS 18+, watchOS 11+, XcodeGen from `project.yml`.
Targets: `ARET`, `ARETWatch`, `ARETLiveActivity`.
MapKit fallback; MapLibre + OpenFreeMap online beta.
OSM summit/route discovery and Open-Meteo mountain weather.
No production server, Supabase or cloud route sync exists yet.

**Current geographic discovery scope: Alpi Apuane and Appennino
tosco-emiliano ONLY.** Two broad pilot bounding boxes (NOT park limits).
Do not add a worldwide search mode without explicit product approval.

## Collaboration contract

1. Inspect repository state, current branch, working tree, relevant
   Swift code and open PRs before editing. Never force-push another
   developer's work or silently overwrite a shared file.
2. Work on a new named feature branch and submit a small PR; prefer
   the agreed integration base `feature/field-test-0.1`.
3. For changes to `project.yml`, `RoutePlanningView.swift`,
   `OnlineRouteSearchService.swift`, `FieldWeatherService.swift`,
   `RouteLibraryStore.swift` or `ARETBrand.swift`, coordinate ownership
   before making simultaneous edits with other agents.
4. Keep PR notes: code changed, features truly implemented, limitations,
   tests actually run, impacts on privacy, provider terms, energy.
5. **Never claim a successful Xcode build or a device test if it was
   not executed.** Linux Swift parsing is not iOS/watchOS compilation.
6. Update docs and QA scenarios when public behavior changes.
7. Never add secrets, real user GPS traces, copyrighted guide content
   without rights, or expensive paid services without approval.

## Safety and data contract (non-negotiable)

- A named peak is NOT a trail. A nearby OSM relation is NOT necessarily
  a summit ascent. A standalone via ferrata way is NOT a complete GPX.
- Never invent/straight-line-connect route coordinates through terrain.
  Fail closed on missing or disconnected route geometry.
- Do not infer technical grade from distance or elevation alone.
  If difficulty data are absent, label unknown.
- A weather model cannot certify "go". Use explainable risk language,
  known limitations, official bulletins and uncertainty.
- Keep essential Hiking features free and local-first.
- Existing UI style: near-black, white, **ARET orange** via
  `ARET-SharedUI/ARETBrand.swift`; don't invent a second design system.
- Do not remove the MapKit fallback while MapLibre/offline is unverified.

## Expected work sequence

(1) Clarify the requested component → (2) inspect code/docs →
(3) plan smallest safe changes → (4) implement →
(5) run build/tests if available → (6) update docs →
(7) PR + report with precise limitations.

If a provider is unreliable, show an error instead of fake results.
If you spot a compile/runtime/safety issue in existing code, report it
clearly even if outside the immediate task.

The developer guide and architecture reference are canonical for setup,
modules, and outstanding beta blockers.
