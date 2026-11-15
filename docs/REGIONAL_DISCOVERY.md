# Regional mountain and ascent discovery — pilot

**Status:** implemented as a beta data pipeline; Xcode/device and public
API coverage tests are still required.

This is a **regional pilot**, not a promise that all mountain routes are
already catalogued or verified.

## Target ranges

| Region | South | West | North | East |
| --- | ---: | ---: | ---: | ---: |
| Alpi Apuane | 43.84 | 9.92 | 44.37 | 10.58 |
| Appennino tosco-emiliano | 43.90 | 9.34 | 44.75 | 11.33 |

Source: `ARET-iOS/Routes/ARETDiscoveryRegion.swift`.

These **bounding boxes are broad pilot discovery windows**, not legal
protected-area boundaries nor a precise geological definition. They
include some marginal/adjacent territory, and might omit fringe routes.
Refine the polygons with appropriately licensed authoritative geography
before production. The user can choose *Entrambe*, *Apuane* or
*Appennino*. All dynamic OSM results are filtered to a selected window.

## Immediate no-network shortcuts

The repository includes lists of named *summit search shortcuts*.
Examples (no coordinate/GPX/difficulty fabricated):

**Apuane:** Pisanino, Pizzo d'Uccello, Grondilice, Sagro, Roccandagia,
Tambura, Sella, Cavallo, Contrario, Sumbra, Altissimo, Corchia, Pania
della Croce, Pania Secca, Pizzo delle Saette, Monte Forato, Procinto,
Matanna, Gabberi, Nona, Borla, Fiocca, Freddone.

**Appennino:** Cusna, Prado, Alpe di Succiso, Marmagna, Orsaro,
Ventasso, la Nuda, Giovo, Rondinaio, Cimone, Corno alle Scale, Libro
Aperto, Spigolino, Gennaio, Sillano, Romecchio, Acuto, Pania di
Corfino, Pietra di Bismantova.

The names are **shortcuts**, not a promise that every summit has a mapped
trail. Neither these names nor their order proves a difficulty rating.

## Dynamic summit directory

`ARETPeakDiscoveryService.swift` queries the public Overpass endpoint
using OSM `node["natural"="peak"]["name"]` inside each bounding box.
It decodes OSM node ID, latitude, longitude, `name:it` or `name`, plus
optional `ele`. Results are cached in memory **six hours per region**
for the current app process and can be browsed/search-filtered by name.
Peaks from overlapping regions are deduplicated by OSM node ID.

Known limitations:
- OSM `natural=peak` does not include every named mountain or ridge.
- Peaks with no name are intentionally absent.
- `ele` is community data and optional; it is **not** DEM validation.
- The live provider may fail/time out/rate-limit. The local shortcut
  names remain accessible; the UI warns about incomplete OSM indexing.
- The region picker controls queries. Search is not worldwide.

A user choosing a result sends its *exact OSM coordinates* to the
route-discovery service, which avoids geocoding similarly named places.
Typed names are matched to the cached peak directory first, then
MapKit local search with geographic bounds validation; if place
geocoding fails, the service tries an OSM **name-based** route search
inside the chosen pilot region(s).

## What counts as a "route"?

The app currently queries:
- OSM `relation[type=route][route=hiking|foot|via_ferrata]` around
  identified summits.
- OSM `way[highway=via_ferrata]` or `way[via_ferrata_scale]` nearby.
- OSM `way[highway=path|footway]` within about **2.2 km** of a
  resolved summit (or named segments when name-search fallback is used).
- When no summit can be located, **name-matching route/ferrata** data
  from the pilot area boxes.

OSM relations are accepted only when their way geometry is available
and endpoints can be joined within a **3 metre tolerance**; gaps
larger than that are rejected. This is still an algorithmic quality
filter, not a human validation. Relations with missing way members
are discarded. Names/difficulty come only from OSM tags when present.

The regional search also lists standalone **OSM path sections** with
`sac_scale` or `cai_scale` when present in way tags. The app shows
these in expandable map cards, **never** as full summit itineraries.
At most 40 path sections are returned for UI prioritization; the
first 18 appear in the list. No guarantee of total network coverage.

A relation shown as **"Traccia OSM vicino alla località"** is not
necessarily a complete ascent to the summit. A via ferrata segment
is shown on its own preview and is **not exported as a complete ascent**.
This avoids implying that a nearby hiking trail leads all the way to
the top of Monte Procinto.

## Difficulty — do not conflate scales

- **CAI T / E / EE / EEA** are Italian hiking classification schemes,
  not interchangeable with climbing grades or via-ferrata scales.
- OSM `sac_scale` is its own Swiss Alpine Club scheme. ARET may
  show the exact tag and a **clearly indicative** translation.
- OSM `via_ferrata_scale` is not the same as a CAI climbing grade.
- Absence of a grade **means unknown**, not automatically easy.
- A hiking route relation may lack the way-level `sac_scale` tags.
  Do not classify it as T/E/EE without evidence.
- A route may be difficult because of exposure, snow, route-finding,
  lack of protection or rapidly changing conditions independent of
  its length, altitude and vertical gain.

**TODO before production:** enrich all route members with provenance,
validate the maximum difficult segment, detect routes which only
*pass near* a summit, distinguish approach/summit/return variants, and
confirm licensing of any external topo/guide content.

## Source-backed textual ascents

`MountainAscentGuide.swift` plus `ARETAdditionalAscentGuides.swift` now
contain **21 short source-linked textual descriptions** across the two
areas (not all entries reach their named summit).
The original 10 cards covered Procinto/Pisanino (Apuane) and Cusna,
Succiso, Orsaro, Sillara, Bismantova and Acuto (Appennino).
The additional 11 cover Panie, Monte Forato (hiking and ferrata),
Campocatino/San Viano (NOT Roccandagia summit), Monte Tondo,
Pania di Corfino, Cisa/Prampa, Monte Vecchio, Vallestrina/Passone,
Marmagna/Logarghena and a multi-stage Prado→Orsaro crossing.

Some entries deliberately describe an outing **near** a mountain,
rather than a confirmed summit ascent. Do not advertise them as
complete peak routes.
The Appennino pages link to official National Park itinerary pages;
the stated T/T+/E/E+ labels are **the Park's classification of those
specific proposals**, not an independent ARET difficulty certification.
They are region-filtered and **none contains a verified full GPX**.
Always check the original source for current closure, route changes
or seasonal conditions. Human field verification remains outstanding.

### Primary regional data registers

As of the November 2026 research check, the Appennino National Park's
[online trail network](https://www.parcoappennino.it/rete_sentieristica.php)
lists **183 numbered trail records** with difficulty and status; its
separate [walking itineraries index](https://www.parcoappennino.it/percorsi.piedi.php)
lists **37 described excursions**. These lists are NOT the same thing
and may change. ARET currently links to them but has not ingested
and validated all their data.

For the Apuane, the
[CAI Toscana 2025 trail registry](https://organizzazione.cai.it/gr-toscana/wp-content/uploads/sites/66/2025/10/Sentieri-CAI-ufficiale-21-10-2025.pdf)
includes many numbered path sections plus ferratas such as
**Bruni 115A (EEA)** and **Renato Salvatori 110A (EEA/tratti EE)**.
The [Parco Apuane](https://parcapuane.toscana.it/turismo/apuan_alps_cets_strategy_action_plan_2023_3.pdf)
publishes classic itineraries and broader trail-network context.
Some documents are historical and must not be treated as current
walkability status; confirm modern route IDs and closures.

**Data-rights requirement:** referencing official source links is not
permission to bulk-copy third-party trail GPX, topo maps, long prose
descriptions or databases. Obtain a permitted data feed or legal review
before automated replication.

### Coverage gap inventory

[CATALOG_COVERAGE.csv](CATALOG_COVERAGE.csv) tracks the
**48 quick-search names**, 21 linked guide entries associated with
**19 of those names**, and **29 names without local curated source
records**. It does not represent all geographic peaks or all routes.
All `full_gpx_verified` values currently remain `no`.
OSM discovery can still return nearby geometry, but a track
appearing in results is not automatically a verified summit route.

Expand carefully with an approved content workflow:
1. Obtain explicit source and usage rights for description/photographs/
   GPX if material is being republished.
2. Compare at least one official/authoritative route or qualified local
   contributor; mark verification date and curator.
3. Record complete start/access, summit, descent, seasonality,
   exposure/gear and classification with a stable provenance trail.
4. Validate GPS track and direction **before** enabling track download
   and in-field navigation.
5. Mark temporary closures and uncertainty; source time-sensitive
   safety information separately.
6. Never invent missing coordinates, difficulty or technical equipment.

## Test search coverage

- Apuane: Pisanino; Procinto; Pania della Croce; Pizzo d'Uccello;
  Sagro; Tambura; Corchia; Forato.
- Appennino: Cusna; Prado; Alpe di Succiso; Marmagna; Orsaro;
  Cimone; Giovo; Rondinaio; Corno alle Scale.
- Named route: "Ferrata Aristide Bruni" (curated guide), route name
  present in OSM, malformed/ambiguous "Via normale".
- Duplicate summit names: choose from the OSM summit directory so
  the exact point is passed to the service.
- Out-of-scope mountain: no valid regional route should be
  presented under the pilot filter.
- No network/429/500/timeout: explain the failure; don't claim
  "the mountain has no trails".
- Missing `sac_scale`, disconnected relation, one ferrata segment:
  show uncertainty / partial technical nature / reject invalid geometry.
