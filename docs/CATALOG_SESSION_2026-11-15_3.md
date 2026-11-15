# Catalog handoff — evening session, 2026-11-15

## Scope and current PR state
- Base: `feature/field-test-0.1`; organization repositories `aret-app/*` untouched.
- PR #3: four cards, 23/48 shortcut names with source-linked records if merged alone.
- PR #4: research-only, no integrated cards.
- PR #5: Cerreto / Lago Pranda `Monte la Nuda` card (distinct peak from this PR).
- PR #6: Monte Spigolino summit loop.
- This PR: one independently sourced summit-loop card for **Monte La Nuda at Corno alle Scale**; no GPX included.

## Primary-source evidence
- Ente Parchi Emilia Orientale: https://www.enteparchi.bo.it/parco.corno.scale/itinerari-dettaglio.php?id_iti=1061
- Source names summit explicitly, Pianaccio–Sboccata dei Bagnadori–Balzi del Fabuino–La Nuda–Rifugio Segavecchia–Pianaccio.
- Source's grade **E**, length **12.3 km**, time **5 h 30 min** apply only to that loop.
- This is a **summit loop**, not an approach-only card or a ferrata. Source offers downloadable GPX, **not acquired, checked, or licensed for redistribution**.
- The source warns about slippery ground on demanding high sections. Current on-ground access unverified.

## Critical name ambiguity
**Monte La Nuda (Corno alle Scale, Bologna)** is different from **Monte la Nuda (Cerreto / Lago Pranda)** in PR #5. The legacy 48-row matrix has only one ambiguous `Monte la Nuda` shortcut. This PR attaches its new card to that row for name-level coverage, but **DOES NOT prove that the Cerreto peak is covered**. The shortcut dataset should eventually use a stable region+summit identifier and separate both mountains before treating peak coverage as a strict geographic census. Avoid merging this card with the Cerreto guide under one mountain identity.

## Coverage arithmetic (names, not geographic summits)
- Base: 21 cards, 19/48 shortcut names source-linked, 29 without.
- This PR alone: 22 cards, 20/48 names linked, 28 without.
- PR #3 adds four cards / four new names; PR #5 is a La Nuda card **for a different mountain** but shares the same ambiguous shortcut row; PR #6 adds one new Spigolino name.
- Assuming all #3/#5/#6 and this PR merge with correct conflict resolution, **28 source-linked cards and 25/48 shortcut names** linked; **23 names without**. This does NOT mean both La Nuda summits have separate indexed shortcut identities or that all 25 cards are summit ascents.
- All `full_gpx_verified` values remain `no`.

## Collaboration and checks
- Swift file added; one registration in `MountainAscentLibrary.guides`; one CSV row updated.
- Review all PRs before merging: #3/#5/#6 and this PR touch the same library/CSV files; resolve conflicts manually and recheck counts.
- No Xcode, simulator, device, field, GPX validation, permissions audit, or source reuse legal review performed.
- Follow-up: inspect more official summit routes, prioritize 23 still-unlinked shortcut names, explicitly distinguish nearby-route cards from summit routes, and add regression tests for unique summit identities and guide IDs.
