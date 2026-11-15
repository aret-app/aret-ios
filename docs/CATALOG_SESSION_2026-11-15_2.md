# ARET Hiking — session 2 handoff (15 November 2026)

## Delivered on this isolated branch
- One new Swift text-only guide: `appennino-spigolino-baita-sole`, a **confirmed Monte Spigolino summit loop** described by [Ente Parchi Emilia Orientale](https://enteparchi.bo.it/parco.corno.scale/itinerari-dettaglio.php?id_iti=6015).
- The Park's published route: Baita del Sole → Monti della Riva → Spigolino summit → Passo dello Strofinatoio / Lago Scaffaiolo → Rifugio Sasseto → Baita del Sole. Park classification **E**, duration **6 h 30 min**, length **9.5 km**. This is the **source's grade for that itinerary**, not a general mountain grade.
- Registered in `MountainAscentLibrary`; one CSV row changed. No new geometry, navigation, GPS, GPX import, proprietary photos or long copied prose.
- Official page offers downloadable GPX/KML, but ARET has **not downloaded, validated, licensed or embedded** them. `full_gpx_verified=no`.

## Coverage / parallel PR reconciliation
- Integration base `feature/field-test-0.1`: 21 cards; 19/48 shortcut names source-linked; 29 without.
- This PR alone: 22 cards; 20/48 shortcut names source-linked; 28 without.
- PR #3 (Ventasso, Sillano, Corchia approach, Sagro-area loop): +4 cards, +4 shortcut names. PR #5 (La Nuda from Lago Pranda): +1 card, +1 shortcut name. **If PR #3, #5 and this PR all merge cleanly**: 27 cards, **25/48 shortcut names source-linked, 23 without**. Corchia and Sagro are NOT proven summit ascents; several legacy cards likewise need summit-specific audit. These are *proposals*, not merged-base facts.
- PR #4 adds Cusna/Prado source research only, 0 app cards.
- Distinguish `Monte la Nuda` near Cerreto Laghi from the distinct `Monte La Nuda` at Corno alle Scale / Pianaccio; do not silently merge or mislabel their routes.

## Source triage
- [Ente Parchi — Monte La Nuda at Corno alle Scale](https://www.enteparchi.bo.it/parco.corno.scale/itinerari-dettaglio.php?id_iti=1061) is a **different summit** from PR #5's La Nuda near Cerreto Laghi; not integrated to avoid ambiguous shortcut attribution.
- [Parco Appennino — Alta Val d'Ozola](https://parcoappennino.it/percorso.php?id=83&id_zona=3) passes Passo Romecchio but does not establish a Monte Romecchio summit ascent; not integrated.
- [Parco Appennino — Monte Acuto](https://www.parcoappennino.it/percorso.php?id=89) has an existing card; not duplicated.
- Search for official full summit routes for missing Giovo, Rondinaio, Cimone, Corno alle Scale, Libro Aperto, Gennaio, and Apuane technical summits.

## Checks and limitations
- GitHub static pre-write checks: source array insertion point exists, 48 CSV rows, new ID linked, no `full_gpx_verified=yes`. Perform GitHub readback after commit.
- No Xcode build, Swift compile, simulator, device, field, GPX-geometry, seasonal access or legal data-reuse test was run. The Park's published route description is not a current safety clearance.
- Review PR conflicts with #3 and #5 on `MountainAscentGuide.swift` and `CATALOG_COVERAGE.csv` before merge; cherry-pick/rebase as necessary. No changes to `aret-app` organization repositories.
