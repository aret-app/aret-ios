# ARET — developer onboarding and collaboration

This guide is for two human developers and any AI coding assistants
(including Claude Code). **Code and project.yml are the source of truth**;
README/docs describe intent and constraints.

## 1. One-time environment setup (Mac)

Requirements:
- macOS + recent Xcode, command line tools and Swift 6 support.
- [Homebrew](https://brew.sh/) and XcodeGen.
- iPhone iOS 18+; optional Watch watchOS 11+ paired for live tests.
- Correct provisioning/personal Apple Team for iOS/Watch/widget.

```bash
git clone https://github.com/lorenzopieri99/Aret.git
cd Aret
git fetch origin
git switch feature/field-test-0.1
brew install xcodegen
xcodegen generate
open ARET.xcodeproj
```

Targets in Xcode: **ARET, ARETWatch, ARETLiveActivity**. Each must be
configured for signing on a physical device. SPM resolves MapLibre
from the package declared in `project.yml`. First build can take time.

After any `project.yml` change:
```bash
xcodegen generate
```
If Xcode reports stale generated metadata: clean `Shift+Cmd+K`,
resolve packages, build `Cmd+B`. Do not commit random generated
`ARET.xcodeproj` changes in place of the XcodeGen manifest.

### Useful build commands

```bash
xcodebuild -list -project ARET.xcodeproj
xcodebuild -project ARET.xcodeproj -scheme ARET \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

The **full Watch mirroring and GPS recording require physical hardware**.
A successful simulator compile is necessary but not sufficient.

## 2. Git and parallel work

Current feature integration branch:
`feature/field-test-0.1`. There may be unmerged commits not in `main`.

Recommended workflow:
```bash
git fetch origin
git switch feature/field-test-0.1
git pull --ff-only origin feature/field-test-0.1
git switch -c feat/<name-of-change>
# edit, compile, run tests
git add <paths>
git commit -m "feat(scope): description"
git push -u origin feat/<name-of-change>
# open a Pull Request to feature/field-test-0.1 (or agreed integration branch)
```

Do not force-push/overwrite another developer's changes.
If someone else has edited a file, fetch and review the diff; resolve
conflicts deliberately. **Avoid two agents editing the same files at once**.

Suggested division:
- Developer A: regional OSM discovery, route geometry/quality, MapLibre.
- Developer B: mountain weather, Watch/iPhone integration, field testing.

This is a *suggestion*, not a branch ownership rule; coordinate on
GitHub Issues/PRs. Common files requiring review before edits:
`project.yml`, `MainTabView.swift`, `RoutePlanningView.swift`,
`OnlineRouteSearchService.swift`, `FieldWeatherService.swift`,
`RouteLibraryStore.swift`, `ARETBrand.swift`.

Every PR should include:
- Objective and changed files.
- Feature screenshots/video for UI work (real build, not render).
- Build and device test results, with Xcode/iOS/watchOS versions.
- Impact on offline use, battery, privacy, cost and licences.
- Evidence for technical ascent grades and provenance links.
- Migration plan for any persisted JSON/GPX changes.
- Explicit known limitations / error states.

## 3. Preferred code patterns

- Swift 6, SwiftUI, existing `@MainActor` observable managers.
- Reuse `ARETBrand.swift` and app palette. Minimal, legible hiking UX.
- Add narrowly scoped services, views and tests rather than growing
  the existing large route-planning/weather view files.
- Keep OSM nodes, route relations and ferrata ways as distinct data types.
- Route geometry must come from data, never from AI interpolation.
- A partial route must NOT be promoted to full summit route.
- Prefer `nil` / "non disponibile" when difficulty, elevation, weather
  or completion state is missing, never `0` presented as verified.
- UI must handle no connectivity, rate-limits and incomplete metadata.
- Store user data locally by default; external services must respect
  provider terms and location privacy.
- Do not commit API secrets, location traces of identifiable users or
  third-party copyrighted topo images.

## 4. Workflow for an AI assistant

1. Read root `CLAUDE.md`, `AGENTS.md`, this document, relevant actual
   Swift files and `project.yml`.
2. Inspect Git branch, unstaged changes and open PRs before editing.
3. State the scope of the task. If needed, split into small PRs.
4. Prefer source-backed data and explicit "unknown" over invented
   route difficulty/geometry/weather. Never assert production safety.
5. Change code, run the build where Xcode is available, and test paths
   that were affected. Report if tests weren't run.
6. Update docs and QA cases for changes in behaviour or provider scope.
7. Share PR link + commit SHA and what still needs a human test.

If the AI can inspect GitHub but cannot run Xcode, **say so**. A code
commit is not evidence of a compiled, signed, device-tested feature.

## 5. Developer priorities

1. Get clean Xcode build including MapLibre and Watch targets.
2. Search **Procinto, Pisanino, Corchia, Tambura, Cusna, Prado,
   Alpe di Succiso, Cimone** with correct regional filter behaviour.
3. Assess duplicate names and incomplete Overpass member geometry.
4. Validate forecast time zones, day selector and multi-point coverage.
5. Test GPS save and Watch mirroring when phone is locked.
6. Validate map copyright/attribution and provider ToS.
7. Only then implement full topo/contours/offline map downloads.

See [QA_SCENARIOS.md](QA_SCENARIOS.md) for the hands-on checklist.
