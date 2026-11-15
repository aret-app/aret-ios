# Data sources, rights, privacy and safety

The prototype uses external data providers. **Free public data is not
equivalent to unlimited production API usage.** Check current terms
with every provider prior to a commercial release or bulk/offline use.

## Data inventory

| Data / feature | Current source | Status / caveat |
| --- | --- | --- |
| Summit names, positions, optional OSM elevation | OpenStreetMap via Overpass API | Beta: public API with rate limits, coverage not exhaustive |
| Hiking route relations and mapped ferrata sections | OpenStreetMap via Overpass | Beta: geometries and tags require QA |
| Geocoding of mountain/place name | Apple MapKit / `MKLocalSearch` | Region-biased and validated to pilot area; requires online access |
| MapKit standard/imagery/hybrid | Apple Maps / MapKit | Available in fallback |
| MapLibre ARET Sentieri vector basemap | OpenFreeMap Liberty + OSM contributors | Online beta, **not full topographic offline** |
| GPX track coordinates | User import, recorded workout or OSM relation | Stored/used locally |
| Elevation profile for OSM routes | Open-Meteo elevation (Copernicus DEM GLO-90) | Sampled model; not precise on cliffs/technical ground |
| Temperature, precipitation, wind, visibility, freezing level, daylight | Open-Meteo forecast | Model estimates, not on-site measurements |
| Watch heart rate/workouts | Apple HealthKit | Subject to permission / device conditions |
| Watch route handoff | Apple WatchConnectivity | Route geometry subsampled (max 140 points), not an offline topo |
| Personal activities/history | Local protected JSON + GPX | No backend sync implemented |

## Real provider URLs in the code

- `https://overpass-api.de/api/interpreter` — OSM query endpoint.
- `https://tiles.openfreemap.org/styles/liberty` — MapLibre style.
- `https://api.open-meteo.com/v1/forecast` — hourly/daily forecast.
- `https://api.open-meteo.com/v1/elevation` — DEM elevation.
- Apple MapKit and HealthKit native SDKs.

Nothing in this list guarantees provider uptime, rate-limit policy or
commercial authorization. Review:
- OpenStreetMap licence and attribution: https://www.openstreetmap.org/copyright
- OSM `sac_scale`: https://wiki.openstreetmap.org/wiki/Key:sac_scale
- Overpass API: https://wiki.openstreetmap.org/wiki/Overpass_API
- OpenFreeMap terms: https://openfreemap.org/terms
- Open-Meteo pricing/terms: https://open-meteo.com/en/pricing
- MapLibre Native iOS: https://maplibre.org/maplibre-native/ios/latest/
- Apple HealthKit: https://developer.apple.com/documentation/healthkit

## Weather semantics and safety

`FieldWeatherService.swift` requests weather, wind at 10 m and gusts,
visibility, freezing-level height and wind at pressure levels 850/700 hPa
with geopotential heights. For a selected route, it queries **up to
three distinct positions** (high point, start, midpoint) and merges
hourly parameters conservatively **when the provider calls succeed**.
`samplingPointCount` indicates actual successful samples.
The `daily` array still comes from the primary sample — do not
claim that the daily forecast has been combined over the whole route.

The dashboard:
- Shows a candidate time window during daylight.
- Gives conservative **model-based** reasons for caution/risk.
- Differentiates **10 m gusts** from atmospheric wind at approximate
  pressure-level height (not local gusts over a ridge).
- Shows estimated freezing-level elevation but does **not** infer a
  measured snowline or stability of snowpack.
- Compares a rough movement-time estimate with the forecast window:
  descent and approach may not be covered in a supplied GPS segment.
- Shows forecast retrieval timestamp.

Do **not** advertise this as a certified "safe to climb" yes/no engine.
Beware especially:
- Rapid local weather development and unreliable longer forecasts.
- Thunderstorms, wind acceleration in passes/crests, reduced visibility.
- Snow, ice, avalanche bulletins, rockfall, closures and trail damage
  not predicted by the current numeric weather engine.
- Differences between a GPX track and actual intended route.
- The chosen departure time might not leave time to **return**.
- OSM `ele` and DEM can be inaccurate on vertical terrain.

**Required for production:** official severe-weather/avalanche sources,
forecast model disagreement, proper duration/turnaround rules, and a
documented expert review of danger thresholds. Use restrained copy:
"Condizioni relativamente favorevoli" rather than "Salita sicura".

## OSM copyright and representation

OSM-derived cartography requires visible `© OpenStreetMap contributors`
attribution and ODbL compliance for derived datasets. MapLibre itself
is a rendering SDK, not a data source. Copyright of hiking guides and
GPX from websites/blogs is not automatically open: never scrape and
re-publish third-party route descriptions or topos without rights.

Avoid mass downloading tiles from an external free provider. For
offline packs and wide usage prefer own licensed PMTiles/DEM datasets
in affordable object storage, following data-provider licences.

## Privacy and security

- Personal activities, imported GPX and recorded GPX live on device.
- The user must opt into any future Supabase/R2 upload. Cloud accounts
  are **not implemented** in this code.
- Provider requests for map tiles, summit lookup, geocoding and weather
  necessarily disclose technical request information such as IP and
  location/search area; this is **not the same** as syncing personal
  activity tracks to an ARET server.
- HealthKit requires explicit health permissions; not a backend API.
- iOS file protection currently uses `complete` on certain GPX/JSON
  files. **Verify background save on a locked phone**, because locked
  file protection can prevent writes. Preserve privacy while fixing
  any lifecycle issue.
- SOS opens phone 112 through the system; ARET is not a rescue device.

## Production economics

Prototyping can avoid a paid backend, but public Overpass endpoints
are not designed to absorb large-scale app traffic. Before launching
to a broader audience, cache OSM/DEM geographically on own
infrastructure and verify Open-Meteo commercial licensing (the
free non-commercial service is not an unconditional commercial tier).
A future Supabase PostGIS + Cloudflare R2/Workers architecture is
**a proposal, not implemented code**.
