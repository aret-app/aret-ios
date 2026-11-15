# ARET

**Every line. One map.**

ARET is an Apple-first mountain companion for hiking, climbing and alpinism.

## Hiking-first roadmap

**The immediate product is ARET Hiking:** discover a trail, check the
real route map/elevation profile, inspect weather, and start recording
with as few steps as possible. Core hiking features are planned to
remain free and usable without creating an account.

See [Hiking roadmap and field-test criteria](docs/HIKING_PLAN.md).

This beta currently uses **Apple MapKit**. A genuinely custom
OpenStreetMap / MapLibre topographic layer and downloadable offline
maps are planned, **not yet implemented**.

## Hiking weather and trail downloads

ARET now processes hourly daylight, visibility, freezing-level height and
pressure-level wind data in addition to precipitation/ground-level gusts.
The itinerary and Weather screens present a **conservative, explainable**
assessment and forecast windows; this is *not* a mountaineering safety
certification or an authoritative go/no-go order.

Discovered public hiking itineraries with valid geometries can be exported
as GPX locally via the share sheet. Saving/exporting a GPX **does not**
download the underlying terrain/map imagery. Full OpenStreetMap-based
hiking layers and offline map-region downloads are planned for V0.3,
subject to tile-provider permissions and data-quality validation.

See [Hiking roadmap](docs/HIKING_PLAN.md) for the staged plan and field tests.

## Field Test 0.1

The first field build is intentionally narrow:

- 3D terrain map and live user location with a dedicated recenter control
- explicit route selection: no route is shown until the user chooses it
- built-in ARET route catalog plus optional GPX import
- off-route distance warning only during an active recording
- dense navigation-grade GPS recording
- persistent activity history with full statistics
- optional "save as route to repeat" flow after every activity
- Apple Watch hiking workout
- HealthKit heart-rate and distance on Watch
- Watch-to-iPhone workout session mirroring
- lightweight field weather
- emergency screen with coordinates, altitude and GPS accuracy
- architecture ready for offline maps, route features and Strava sync

## Repository layout

```
Aret/
├── ARET-Core/
│   ├── GPX/
│   ├── Models/
│   └── Navigation/
├── ARET-iOS/
│   ├── App/
│   ├── Explore/
│   ├── Navigation/
│   ├── Safety/
│   ├── Weather/
│   └── Workout/
└── ARET-Watch/
    ├── App/
    └── Workout/
```

## Current development branch

`feature/field-test-0.1`

## Quick start on Mac

Requirements:

- recent Xcode
- iPhone running iOS 18+
- Apple Watch running watchOS 11+
- the same Apple Account signed into Xcode / devices

Clone:

```bash
git clone https://github.com/lorenzopieri99/Aret.git
cd Aret
git checkout feature/field-test-0.1
```

Generate the Xcode project with XcodeGen:

```bash
brew install xcodegen
xcodegen generate
open ARET.xcodeproj
```

In Xcode:

1. Open `ARET.xcodeproj`, press **Command–1**, and select the blue **ARET** project icon in the Project navigator.
2. In the project editor sidebar, select **ARETWatch** under **TARGETS** (not under **PROJECT**). If the sidebar is hidden, expand it with the button at the top left of the project editor.
3. Open **Signing & Capabilities**, select **All**, keep **Automatically manage signing** enabled, and choose your Development Team from **Team**.
4. If the team is missing, open **Xcode → Settings → Accounts**, add your Apple Account, then return to the target and select the team.
5. Repeat for the **ARET** target, selecting the same team. The repository deliberately does not hard-code a personal `DEVELOPMENT_TEAM`.
6. Connect/unlock the iPhone and its paired Apple Watch. In the toolbar, choose the **ARET** scheme and your physical iPhone, then use **Product → Build** (**Command–B**) and **Product → Run** (**Command–R**).
7. To run the Watch app directly, choose the **ARETWatch** scheme and your paired physical Apple Watch, then press **Command–R**.
8. Accept Location and Health permissions when requested.

After pulling source updates, regenerate with `xcodegen generate` only if the project definition changed or the project is missing. Regeneration can reset team selections made in Xcode; select the team again on both targets afterward.

The Watch workout and HealthKit behavior must be tested on physical Apple devices.

## Saturday field-test flow

1. Open ARET on iPhone.
2. Open **Percorsi** and choose the field-test route.
3. Return to **Esplora** and check the orange reference route.
4. Start the hike from ARET on Apple Watch.
5. Confirm heart rate, elapsed time and distance update on Watch.
6. Check that starting the Watch workout automatically starts the
   mirrored iPhone recording. If not, report it as a field-test bug.
7. Put the iPhone in your pocket and verify background tracking.
8. Intentionally move a safe distance away from the GPX to test the reference-route warning.
9. Open the SOS panel and verify coordinates/altitude/accuracy.
10. End the Watch workout and confirm it appears in Apple Health/Fitness.

## Important field-test limitations

- This build is not a safety-certified navigation device.
- The GPX line is a reference route, not a guarantee that terrain is safe or passable.
- Weather in 0.1 uses a lightweight field-test provider to avoid making WeatherKit entitlement/signing a blocker. Production weather remains provider-swappable.
- Offline terrain downloads are not in this commit yet.
- Strava upload is not in this commit yet.
- Climbing pitches, bolts, anchors and community editing are represented in the domain model but not exposed in UI yet.

## Product principles

1. The map is the home.
2. A reference route is guidance, never a guarantee of safety.
3. Every important mountain datum should eventually carry source, date and confidence.
4. Offline operation is a core requirement.
5. Apple Watch is a first-class interface, not an accessory.

## Next technical steps

1. Compile and fix any device-specific signing / watch target issues on the actual Mac.
2. Add offline terrain packages.
3. Add route feature UI for pitch, bolt, anchor, crux and rappel.
4. Add WeatherKit production provider.
5. Add Strava OAuth and activity upload.
6. Add Supabase + PostGIS after the field core is validated.
