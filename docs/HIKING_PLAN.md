# ARET Hiking — product baseline

**Positioning:** The essential mountain app should be simple and free.
**Promise:** Discover → inspect → plan → navigate → record → revisit.

The Hiking experience is the foundation of ARET, not a secondary mode.
Climbing and alpinism will add detail without burdening the hiking flow.

## Non-negotiable principles

1. **Map first.** A map must open quickly, show the user, and distinguish
   reference route from recorded route.
2. **Useful without an account.** Searching a public route, following a GPX,
   recording an activity and reviewing it must not require a cloud login.
3. **No paywall for basic navigation and safety.** Core tracking, public
   topo maps, basic elevation, and a useful offline area should remain free
   to users, subject to sustainable data-hosting limits.
4. **No invented trail certainty.** OSM search results are not automatically
   verified, hike difficulty cannot be inferred from km and ascent alone,
   and DEM is approximate, especially near cliffs or narrow ridges.
5. **Privacy by default.** Personal GPX tracks stay local unless users
   explicitly opt into a cloud feature. Distinguish provider tile/weather
   requests from upload of personal recordings.
6. **Field quality before feature count.** Battery, recovery, lock-screen,
   route fidelity, poor-signal and Watch behavior are release gates.

## V0.2 — beautiful and usable hiking core

- [x] ARET brand, immersive map and concise floating controls.
- [x] Route library, local GPX import and explicit route selection.
- [x] Record GPS track, background location, saved history and GPX export.
- [x] Watch workouts, preliminary mirrored iPhone tracking and route view.
- [x] Live Activity on Lock Screen and Dynamic Island.
- [x] Location-based weather and route weather-window heuristic.
- [x] Public OSM hiking-route lookup (coverage incomplete).
- [x] On-route DEM lookup for online itineraries.
- [x] **Route detail preview:** real line on map + elevation chart when
  altitude exists.
- [x] **One-tap online discovery** rather than requiring keyboard submit.
- [x] Topographic map by default; first GPS fix recenters the map.

## Priority P0 — ARET Mountain Weather

The route forecast must be useful for a **real departure decision**, rather
than a generic weather icon. Advice is **conservative, explainable and never
a certificate of safety**.

Implemented in the field-test branch:
- [x] Forecast source provides hourly **freezing-level height, visibility,
  daylight metadata, wind speed at 850/700 hPa and geopotential heights**.
- [x] Weather window excludes night using actual daylight data when present.
- [x] Isolated one-hour weather gaps are not recommended as usable windows.
- [x] Route detail and Meteo tab show **explainable assessment**:
  relatively favorable / caution / consider postponing / insufficient data.
- [x] Weather hints explicitly distinguish **wind at atmospheric pressure
  levels from gusts on the crest**.
- [x] Frozen/snowy risk is flagged when the modeled freezing level is near
  or below the highest known route elevation.

Still required for a truly reliable mountain feature:
- [ ] Sample weather at **trailhead, representative midroute point and
  summit/high point** rather than one point alone.
- [ ] Estimate hiking time range conservatively (start, ascent, turnaround,
  descent) and compare with daylight and complete weather window.
- [ ] Add official severe-weather / storm / avalanche bulletin links and
  provider timestamp/model metadata. Never infer avalanche risk from
  freezing level alone.
- [ ] Compare multiple forecast models when their data is available and
  explain major disagreement instead of showing false precision.
- [ ] Integrate elevation uncertainty and exposure where sources are
  verified; do not treat OpenStreetMap geometries as certified routes.
- [ ] On-device cached forecast and clear stale-data warnings for offline
  use; do not mislabel outdated forecasts as current.
- [ ] Add tested thresholds by season, route category and terrain before
  any public safety-sounding recommendation.
- [ ] Respect Open-Meteo's current free non-commercial evaluation terms.
  For a commercial launch, arrange the required commercial/API licence
  or self-host a legally compatible provider.

## Priority P0 — Free hiking maps, paths and downloads

**Separate three things:** the full network of mapped hiking paths on a
base map, individual trail *itineraries* with complete geometry/metadata,
and large offline **map-area packages**.

- [x] Import GPX and save routes locally.
- [x] Export a discovered or selected route as a standard GPX file using
  the iOS share sheet, without uploading it to ARET's server.
- [ ] Build a MapLibre topo prototype beside MapKit, including OSM trail
  line styles, summits, trailheads, refuges, elevation contours and hillshade.
- [ ] Choose licensed elevation/terrain tile hosting (Mapterhorn or open
  DEM datasets) and validate terrain gaps with local mountain samples.
- [ ] Build geospatial **trail and route search** that distinguishes OSM
  path segments from OSM hiking relations; reject broken/disconnected
  relations and do not promise every public route exists.
- [ ] Show route source, licence/attribution, last-known update and
  completeness warnings in the detail view.
- [ ] Offline map pack downloads by area with file size, storage management,
  update strategy, version and offline turn-by-turn/track fallback.
- [ ] Validate provider caching and bulk-download terms. For example,
  OpenFreeMap public offline downloads currently limit each download to
  3,000 tiles or 50 MB and 4 concurrent requests; use own permitted
  PMTiles/tile hosting for larger maps.
- [ ] Test no-service navigation and Watch sync in the Apuane with
  completely disabled cellular service.

**Offline routes are not offline maps.** Saving a GPX saves geometry and
coordinates; the basemap tiles still need a separately licenced offline pack.

## Before promoting V0.2 beyond field test

- [ ] Build and signing verified on a real iPhone and Apple Watch.
- [ ] Record with screen locked for 90 minutes; verify distance, point
  continuity, file protection, battery and Live Activity.
- [ ] Start and end from Watch with iPhone locked; verify no duplicate
  activity, reliable save and HealthKit result.
- [ ] Validate route geometry, start/end markers and elevation against a
  known GPX; reject disconnected/incorrect OSM relations.
- [ ] Validate flows for denied, approximate and missing location access.
- [ ] Test import and recording with airplane mode and low connectivity.
- [ ] Record a hike with no mobile signal; no data loss on foregrounding.
- [ ] Validate off-route warning with GPS drift and safe thresholds.
- [ ] Performance on long GPX tracks; reduce drawing points on screen
  without degrading saved data.
- [ ] Accessibility: Dynamic Type, VoiceOver, minimum touch targets,
  outdoor contrast and battery-friendly map defaults.

## V0.3 — maps we can control

- [ ] Compare **MapLibre Native** with existing MapKit in a prototype,
  keeping the current map working as a fallback.
- [ ] OpenStreetMap vector base map with clear paths, summits, refuges,
  contour lines, attribution and our custom ARET style.
- [ ] Evaluate DEM/raster terrain tile license, availability, quality,
  rate limits and bandwidth cost before enabling for all users.
- [ ] Offline geographical pack download with visible size/storage,
  cache validity and provider-compliant distribution.
- [ ] Route source, last verified date, length, ascent, difficulty label
  when actually known, and transparent warnings for incomplete data.

## Competitive focus

Win the simple hike workflow before adding features:
- Search a location without prior knowledge.
- Explain a route at a glance with a credible map/profile.
- Start and record in one tap.
- Use the Watch and Lock Screen without fragile manual sync.
- Keep the essentials free and respect private GPS recordings.

**This document describes roadmap and acceptance criteria, not a
claim that the release gates have already passed.**
