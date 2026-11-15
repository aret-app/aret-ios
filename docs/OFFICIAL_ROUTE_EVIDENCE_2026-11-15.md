# Official route evidence — 2026-11-15 (research-only)

Scope: Alpi Apuane and Appennino tosco-emiliano. This document records **source claims**, not verified route geometry, current on-ground safety, reproduction permission, or field-tested GPX. Do not mark a summit as newly covered merely because a source is listed here. The base branch coverage matrix remains unchanged pending actual app-card integration.

## Primary source candidates

| Mountain | Official source | What source confirms | Source difficulty | Completeness / status | GPX verified |
| --- | --- | --- | --- | --- | --- |
| Monte Cusna | [Parco: sentiero 627](https://www.parcoappennino.it/sentiero.php?id=2541) | Presa Alta → Monte Cusna; 4.55 km, 920 m ascent, 3 h | E (Parco) | Named trail from trailhead to summit; no verified return route | No |
| Monte Cusna | [Parco: sentiero 619](https://www.parcoappennino.it/sentiero.php?id=2535) | Peschiera Zamboni → Monte Cusna; 4.46 km, 930 m ascent, 3 h | E (Parco) | Named trail to summit; return unverified | No |
| Monte Cusna | [Parco: sentiero 617](https://www.parcoappennino.it/sentiero.php?id=2534) | Peschiera Zamboni → Monte Cusna; 3.65 km, 970 m ascent, 3 h | E (Parco) | Named trail to summit; return unverified | No |
| Monte Cusna | [Parco: sentiero 625](https://www.parcoappennino.it/sentiero.php?id=2539) | Casalino → Monte Cusna; 5.68 km, 1210 m ascent, 3 h 45 min | E (Parco) | Named trail to summit; return unverified | No |
| Monte Prado | [Parco: sentiero 631](https://www.parcoappennino.it/sentiero.php?id=2544) | Case del Dolo → **Sella del Monte Prado**, 6.71 km, 880 m ascent, 3 h 15 min | E (Parco) | **Not a summit ascent**; ends at saddle | No |
| Monte Prado | [CAI Reggio Emilia: Anello del Monte Prado, 11 May 2025](https://www.caireggioemilia.it/doc/calendario/20250511_1.pdf) | Described circuit from Case Civago via 605, 691, 603, 00 to Monte Prado summit; return via Sella del Prado, 631, Lama Lite and 605 | Not established from source extract | **Complete described loop including summit**, but 2025 excursion plan is not proof of present accessibility or executed track | No |

## Interpretation safeguards

- Parco's trail-register status is a published status, not real-time trail clearance. Check closures, conditions and official notices before travel.
- Source labels E/T etc belong to the issuing authority and route, not to a summit in general; do not transfer a grade to other approaches.
- Parco may provide a KMZ download on some trail pages. Presence of a download link does **not** establish downloaded, inspected or verified GPX, nor a right to redistribute it.
- The CAI 2025 event description documents a proposed circuit; it does not establish that it was walked, remains open, or can be navigated using a verified track.
- The summit shortcuts without cards must be resolved from the actual app and coverage matrix, not counted as completed from research notes.
- This evidence adds **zero integrated cards**. No app code, coverage CSV or third-party geometry was changed in this research-only commit.

## Next integration pass

1. Rebase or cherry-pick after reviewing PR #3, which contains Ventasso, Sillano, Sagro-area and Corchia-area cards.
2. Prioritize missing summit shortcuts, and only add a card when a precise primary source describes that mountain's actual route; do not use a nearby trail as a summit route.
3. Add source URL, exact source grade, summit-reached boolean, approach/descent completeness, publication/check date, and verification status to curated records.
4. Update CATALOG_COVERAGE.csv **in the same PR as actual new cards**, then run static counts and Xcode/device tests when available.
5. Check usage rights before copying prose, photos or downloaded tracks.
