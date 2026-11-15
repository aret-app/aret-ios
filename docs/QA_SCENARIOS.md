# ARET — manual acceptance plan (regional Hiking beta)

Use **real iPhone/Watch** for GPS, battery, mirroring and HealthKit.
The expected results below are product requirements, NOT already passed
test results. Record Xcode version, device, OS, network, timestamp,
screenshots, and any failure in the PR/issue.

## Build and navigation

- [ ] `xcodegen generate` completes.
- [ ] All targets build: ARET, ARETWatch, ARETLiveActivity.
- [ ] Resolve MapLibre package and run on a real device.
- [ ] Five main tabs open without crashes.
- [ ] Light/dark accessibility, Dynamic Type, button touch targets.
- [ ] Switch MapKit Topo / Ibrida / Satellite / ARET Sentieri (beta).
- [ ] Selected route and active recording are preserved across switches.
- [ ] © OSM attribution is visible, readable and tappable on vector map.
- [ ] MapLibre provider down / offline: app handles it and MapKit can
      still be chosen (MapKit also requires cached/online map tiles).

## Regional summit discovery

| Search / action | Expected behavior |
| --- | --- |
| Scope **Entrambe** | Apuane + Appennino featured peaks, OSM index request |
| Scope **Apuane** | Only pilot-window Apuane OSM peaks and nearby tracks |
| Scope **Appennino** | Only pilot-window Appennino OSM peaks and tracks |
| `Monte Procinto` | Curated Ferrata Aristide Bruni guide; source and technical warning; OSM results only if present |
| `Monte Pisanino` | Curated normale/Bagola Bianca with distinctions |
| `Pania della Croce` | Exact peak if OSM indexed or MapKit resolves; nearby routes only when mapped |
| `Monte Corchia` | Peak identification, region filter, mapped nearby paths |
| `Monte Tambura` | Peak and OSM routes if available |
| `Pizzo d'Uccello` | Correct summit rather than random POI |
| `Monte Cusna` | Appennino, not Apuane |
| `Monte Prado` | Appennino search and metadata if OSM supplies |
| `Alpe di Succiso` | Appennino search |
| `Monte Marmagna` | Appennino search |
| `Monte Giovo` | Appennino search, review ambiguous place names |
| `Monte Rondinaio` | Appennino search |
| `Monte Cimone` | Appennino search |
| `Corno alle Scale` | Appennino search |
| Enter full **via name** instead of peak name | Regional named OSM relation/way fallback; no fake summit geometry |
| Choose a named OSM peak | Exact returned node coordinate used for nearby search |
| 429, 500 or API timeout | Explicit error, cached indexed peaks/local shortcuts still accessible |
| Missing difficulty tag | "Non specificata/da verificare"; never "facile" by default |
| OSM relation with missing way geometry | Rejected from navigable list |
| Ferrata mapped as a way only | Partial technical segment preview, not a full summit route |
| Search an out-of-region mountain | Do not show another country's unrelated tracks |
| Change scope during in-flight search | No stale result from old region leaks into new region |

### How to judge coverage

Log for each test mountain:
- Exact searched text and selected scope.
- Whether the OSM summit node was found, with node ID if available.
- Number of OSM route relations and standalone ferrata ways.
- Which of those **actually reach the summit** after manual review.
- Difficulty source: `sac_scale`, `via_ferrata_scale`, official guide,
  or "unknown"; absence is a data gap.
- Complete GPX start/approach/technical section/exit/descent: yes/no.
- Source/copyright permissions for any curated narrative/GPX.
- Location and time of latest verification by human reviewer.

Do not label a mountain "supported" because a generic nearby path
exists. This checklist is how to build **credible local coverage**.

## Hiking planning and weather

- [ ] Select a route with coordinates and a valid DEM, compare GPX
      distance/altitudes against a known track.
- [ ] Seven-day date selector changes current **day's** hourly view
      without unnecessary new forecast requests.
- [ ] For a GPX with distant start/middle/high point, inspect actual
      `samplingPointCount`; it must not claim 3 when only 1 succeeded.
- [ ] Zero termico and visibility render as unknown when missing.
- [ ] Pressure-level wind is never mislabeled as crest gusts.
- [ ] Hourly timezone/daylight and sunset handling match Italian local
      time (including DST transition).
- [ ] Two isolated favorable hours separated by thunderstorm: not one
      continuous "safe" window.
- [ ] Thunderstorms / strong wind / poor visibility: caution or consider
      postponement, with reasons.
- [ ] Low freezing level near route altitude: warning, not claims of
      observed snow/ice.
- [ ] Technical ascent / GPX without return: not a green clearance.
- [ ] Forecast provider timeout and no internet: honest unavailable/stale
      state and no fabricated safety recommendation.
- [ ] Visual hierarchy is readable in bright sunlight and Dynamic Type.
- [ ] Compare ARET to official mountain forecast and bulletins; log
      disagreements. Source data are models, not ground truth.

## GPS and offline

- [ ] Import valid GPX and export it back with unchanged route geometry.
- [ ] Cancel file sharing: no data uploaded automatically.
- [ ] Use background location for >90 minutes with the screen locked.
- [ ] Confirm end-of-track GPX is written even if Watch ends workout
      while iPhone is locked. **Current complete file protection may
      block writing — potential release blocker.**
- [ ] Put in airplane mode: recorded track remains, OSM searches
      clearly unavailable, previously saved GPX still accessible.
- [ ] Off-route warning compared against a reference track, with GPS
      drift checks; never equate proximity to route safety.
- [ ] High-density 5,000–20,000 point GPX does not freeze UI.

## Watch ↔ iPhone

- [ ] Start hiking workout from Watch while iPhone is open.
- [ ] Start from Watch while iPhone is locked/backgrounded.
- [ ] Start while iPhone app terminated — document real behavior,
      **do not promise** background auto-start without proof.
- [ ] Stop from Watch and verify no duplicate activities, GPX saved,
      Health/Fitness workout visible, Live Activity ended.
- [ ] Route selected on phone shows on Watch (140-point sample).
- [ ] Change active route and verify Watch receives latest context.
- [ ] Phone/Watch out of range and reconnect; no invented data.
- [ ] Emergency call requires explicit OS/UI user action.
- [ ] Battery use on a representative 3–5 hour field test.

## Known blockers to close before inviting broader users

1. Real Xcode compiler + signing + device tests.
2. Route association to actual summit, not merely regional proximity.
3. Explicit provenance and reliable difficulty (including OSM way tags).
4. Correct GPX writes while locked and robust Watch lifecycle.
5. Provider budgets/caching and offline map supply.
6. Safety language, attribution and rights review.
