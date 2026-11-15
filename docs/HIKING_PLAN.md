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
