# ARET

**Every line. One map.**

ARET is an Apple-first mountain companion for hiking, climbing and alpinism.

## Field Test 0.1

The first field build is intentionally narrow:

- 3D terrain map and live user location
- local route / GPX-ready route model
- activity tracking with distance, elevation and elapsed time
- Apple Watch workout session scaffold
- HealthKit heart-rate support on Watch
- off-route distance model
- emergency screen with current coordinates, altitude and GPS accuracy
- architecture ready for WeatherKit, offline maps and Strava sync

## Repository layout

```
Aret/
├── ARET-Core/
│   └── Models/
├── ARET-iOS/
│   ├── App/
│   ├── Explore/
│   ├── Navigation/
│   └── Safety/
└── ARET-Watch/
    ├── App/
    └── Workout/
```

## Current development branch

`feature/field-test-0.1`

## Product principles

1. The map is the home.
2. A reference route is guidance, never a guarantee of safety.
3. Every important mountain datum should eventually carry source, date and confidence.
4. Offline operation is a core requirement.
5. Apple Watch is a first-class interface, not an accessory.

## Next technical steps

1. Create the Xcode workspace with iOS + watchOS companion targets.
2. Add HealthKit, Location and Background Location capabilities.
3. Add a GPX importer and one real test route.
4. Add WeatherKit.
5. Add an offline terrain provider.
6. Add Strava OAuth/upload after the field core is stable.
