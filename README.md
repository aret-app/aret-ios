# ARET

**Every line. One map.**

ARET is an Apple-first mountain companion for hiking, climbing and alpinism.

## Field Test 0.1

The first field build is intentionally narrow:

- 3D terrain map and live user location
- GPX import and reference-route overlay
- off-route distance warning
- activity tracking with distance, elevation and elapsed time
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

1. Select the **ARET** target and choose your Development Team.
2. Select the **ARETWatch** target and choose the same Development Team.
3. Keep **Automatically manage signing** enabled.
4. Connect/unlock the iPhone and Apple Watch.
5. Run the iOS app on the physical iPhone.
6. Accept Location and Health permissions when requested.

The Watch workout and HealthKit behavior must be tested on physical Apple devices.

## Saturday field-test flow

1. Open ARET on iPhone.
2. Import a GPX using **GPX**.
3. Check the white reference route on the 3D terrain.
4. Start the hike from ARET on Apple Watch.
5. Confirm heart rate, elapsed time and distance update on Watch.
6. Start iPhone route tracking if you want ARET’s orange recorded line.
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
