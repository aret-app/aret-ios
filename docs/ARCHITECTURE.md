# ARET — architecture and code map

**Canonical build manifest:** `project.yml` (XcodeGen).  
**Swift version:** 6.0. **Targets:** `ARET` (iOS 18+), `ARETWatch`
(watchOS 11+), `ARETLiveActivity` (iOS widget extension).

There is no backend infrastructure in this repository at present.
iPhone and Watch perform direct provider requests and device-side work.

## Main execution flow

```text
iOS ARETApp
 ├─ MainTabView
 │   ├─ ExploreView               MapKit / ARETTopoMapView (MapLibre)
 │   │   ├─ LocationManager       GPS, recording, background location
 │   │   └─ LiveActivityController → ARETLiveActivity
 │   ├─ RoutesView
 │   │   ├─ RouteLibraryStore     catalog and persisted personal routes
 │   │   └─ RoutePlannerSearchView
 │   │       ├─ ARETDiscoveryRegion     two pilot region windows
 │   │       ├─ ARETPeakDiscoveryService   OSM summit index
 │   │       ├─ OnlineRouteSearchService   OSM route/technical ways
 │   │       ├─ MountainAscentLibrary      curated sourced guides
 │   │       └─ RoutePlanningView
 │   │           ├─ HikingRoutePreview    route map and elevation chart
 │   │           ├─ FieldWeatherService   weather provider
 │   │           ├─ WeatherWindowEngine   hourly candidate windows
 │   │           ├─ MountainWeatherDashboard
 │   │           └─ TerrainElevationService
 │   ├─ ActivitiesView ← ActivityStore ← GPX/RecordedActivity
 │   ├─ WeatherView ← FieldWeatherService
 │   └─ PrivacyView
 │
 ├─ WatchRouteSyncManager ── WCSession applicationContext ──┐
 └─ WorkoutMirrorManager ← HKWorkoutSession mirroring        │
                                                             │
watchOS ARETWatchApp                                         │
 ├─ WatchWorkoutView ← WatchWorkoutManager ← HealthKit/GPS  │
 ├─ WatchRouteSyncManager ←──────────────────────────────────┘
 └─ WatchRouteMiniMap / alerts / emergency call
```

## Source ownership

### Shared modules

- `ARET-Core/Models/Route.swift`: `ARETCoordinate`, route kind,
  features and route model. Used by both iOS and Watch.
- `ARET-Core/Models/RecordedActivity.swift`: recorded activity and stats.
- `ARET-Core/GPX/GPXParser.swift`: GPX parsing.
- `ARET-Core/Navigation/RouteDistanceCalculator.swift`: off-route
  proximity calculation; don't break metrics without tests.
- `ARET-SharedUI/ARETBrand.swift`: color tokens, logo, glass cards.
- `ARET-Shared/ARETTrackingAttributes.swift`: ActivityKit shared state.

### iPhone — maps and routes

- `ARET-iOS/Explore/ExploreView.swift`: map UX, controls, overlays, REC.
- `ARET-iOS/Explore/ARETTopoMapView.swift`: SwiftUI wrapper around
  MapLibre `MLNMapView`, current **online Liberty** style from OpenFreeMap,
  route/recording overlays, coordinator and camera.
- `ARET-iOS/Routes/ARETDiscoveryRegion.swift`: scope, region rectangles,
  names and featured summit shortcuts.
- `ARET-iOS/Routes/ARETPeakDiscoveryService.swift`: Overpass OSM
  `natural=peak` index, cached per region for six hours.
- `ARET-iOS/Routes/OnlineRouteSearchService.swift`: summit geocoding,
  OSM relation/way query, geometry validation and route mapping.
- `ARET-iOS/Routes/MountainAscentGuide.swift`: curated source-backed
  Apuane/Appennino textual ascents (not verified GPX).
- `ARET-iOS/Routes/MountainAscentGuideCard.swift` and
  `TechnicalSegmentPreview.swift`: UX for documented ascents and
  individual OSM ferrata segments.
- `ARET-iOS/Routes/RoutePlanningView.swift`: route detail, date selection,
  search UI, meteo integration; avoid bloating further — prefer subviews.
- `ARET-iOS/Routes/RouteLibraryStore.swift`: selected route and
  local saved JSON state.
- `ARET-iOS/Routes/HikingRoutePreview.swift`: line map and
  Swift Charts elevation when altitude exists.
- `ARET-iOS/Routes/RouteGPXExporter.swift`: user-initiated file export.

### iPhone — weather and tracking

- `FieldWeatherService.swift`: Open-Meteo current/daily/hourly decode,
  freezing level, visibility, daylight, atmospheric pressure-level wind;
  multi-location forecast merging.
- `WeatherWindowEngine.swift`: hourly weather scoring, daylight windows.
- `HikingWeatherAdviceCard.swift`: conservative explainable advice model.
- `MountainWeatherDashboard.swift`: branded verdict, wind/freezing,
  hourly timeline, risk context.
- `MountainWeatherWeekPicker.swift`: seven-day date selector.
- `WeatherView.swift`: main weather tab / location choice.
- `TerrainElevationService.swift`: GPX/OSM route elevations sampled
  via Open-Meteo elevation and Copernicus GLO-90; no raw DEM raster.
- `LocationManager.swift`: CoreLocation; lower power when browsing,
  navigation-grade updates when recording; GPX save at stop.
- `ActivityStore.swift`: JSON/GPX local persistence; no remote sync.
- `PrivateStorage.swift`: file protection, local file management.
- `WorkoutMirrorManager.swift`: iOS receive path for Watch mirroring.
- `WatchRouteSyncManager.swift`: send selected route to Watch.
- `TrackingLiveActivityController.swift` and widget: dynamic island.

### Watch

- `WatchWorkoutManager.swift`: HealthKit workout and CoreLocation
  metrics/altitude/off-route calculations.
- `WatchWorkoutView.swift`: activity picker, metrics, navigation, SOS.
- `WatchRouteSyncManager.swift`: receive most recent WCSession context.
- `WatchRouteMiniMap.swift`: minimal route shape using Canvas.

## Crucial design rules

1. **Summit != ascent != GPX != offline map.** Keep data types distinct.
2. **Provenance is necessary** for technical grade and route description.
   A missing OSM `sac_scale` is unknown, never silently classify easy.
3. **No synthetic route geometry** to summit: reject broken OSM relations
   rather than connecting unrelated segments across cliffs.
4. **Weather forecasts are model estimates**, not official safety guidance.
5. **Keep GPS/activity data local** unless explicit future opt-in.
6. **Do not assume WCSession / HealthKit mirroring works when iPhone is
   terminated**; test lifecycle behavior on real devices.
7. Never modify `project.yml` casually: XcodeGen regenerates the whole
   project, so changes affect iOS + Watch + Live Activity.
8. Any new map data layer must include licensing/attribution and clearly
   handle offline/caching policy.

## Architectural debt / hazards

- The main search and weather screens are still fairly large SwiftUI files:
  extract new subviews or services rather than adding conditional layers.
- Overpass is a public best-effort API. For testers, add server-side
  caching/provider failover before claiming reliable regional coverage.
- The pilot rectangles are coarse; improve coverage via authoritative
  geometry or curated regional index and flag overlaps.
- OSM route *relations* do not guarantee a summit ascent or include
  approach/exit. Quality control is an explicit roadmap item.
- `FileProtectionType.complete` on local stores may be incompatible with
  GPS save triggered while the phone remains locked: test and make a
  deliberate protection/lifecycle decision.
- Watch mirroring needs real-device tests when iPhone is locked,
  backgrounded, suspended or terminated.
- Swift 6 concurrency and MapLibre SDK signatures require actual Xcode
  compilation on macOS; static code review is not sufficient.

## Data flow: hiking search

```text
UI search "Monte Cusna" + [Appennino]
   ↓
ARETPeakDiscoveryService cached OSM peak? → exact coordinate
   ↓ (else)
MKLocalSearch region biased + bounding area validation
   ↓ (else)
named OSM relations / technical ways in chosen region
   ↓
OnlineRouteSearchService, Overpass POST
   ↓
continuous relation geometry / standalone ferrata ways
   ↓
RoutePlanningView → profile/weather/share GPX/selection
```

Curated textual guides are an independent layer; never present them
as having GPS geometry unless one has been checked and licensed.

## Data flow: recorded workout

Watch `HKWorkoutSession.startMirroringToCompanionDevice` →
iPhone `WorkoutMirrorManager` → `MainTabView` →
`LocationManager.startTracking` → CoreLocation + Live Activity →
`stopTracking` → GPX and `ActivityStore`.

Watch route selection (not workout control) is transferred via
`WCSession.updateApplicationContext`, with a **140-point** sampled route
representation. It is not a full-fidelity offline map.

No Supabase, R2, hosted database, push notification or CI-tested build is
guaranteed by the current code.
