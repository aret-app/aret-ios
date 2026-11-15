# ARET Hiking — session 1 handoff (15 November 2026)

## Integration performed
- One new **text-only summit proposal**: Monte la Nuda, Lago Pranda → summit, linked to the [National Park trekking page](https://parcoappennino.it/pagina.php?id=68).
- Source states approximately 2 hours from Pranda to summit; **does not state a grade**. The card explicitly labels difficulty unknown and does not infer a full loop or descent.
- Registered as searchable guide and updated the 48-row coverage matrix. No coordinates, third-party GPX, photos, copied guide text or safety clearance.
- This branch starts from `feature/field-test-0.1`, independent of PR #3 (Ventasso, Sillano, Corchia approach, Sagro-area loop) and PR #4 (research-only Cusna/Prado evidence).

## Coverage arithmetic
- Base branch: 21 cards; 19/48 shortcuts with source-linked guides, 29 without.
- This PR alone: 22 cards; 20/48 shortcuts with guides, 28 without.
- If PR #3 and this PR are both integrated without duplication: 26 cards; **24/48 shortcuts with guides, 24 without**. Two PR #3 Apuane guides are *not* confirmed summit ascents.
- All GPX remain unverified. A source-linked shortcut does not imply summit coverage for all its cards.

## Further primary-source leads (not integrated)
- [Parco Apuane — Monte Croce / Monte Matanna management plan](https://www.parcapuane.toscana.it/DOCUMENTI/TRASPARENZA/pianificazione_governo_territorio/piani_gestione_natura_2000/monte_croce_monte_matanna_IT5120012/Monte_Croce_Monte_Matanna_RELAZIONE.pdf): maps CAI trail network and mentions Matanna among visitor locations, **but not enough to assert a complete ascent or difficulty**.
- [Parco Appennino — Alta Val d'Ozola](https://parcoappennino.it/percorso.php?id=83&id_zona=3): E+, 8h30, 990 m ascent, visits Passo Romecchio, **not proven summit of Monte Romecchio**.
- [Parco Appennino — Monte Acuto](https://www.parcoappennino.it/percorso.php?id=89): existing card; avoid duplicate.
- [Parco Appennino — La Nuda / Passo Cerreto protected area](https://www.parcoappennino.it/pagina.php?id=51): geography only, not route evidence.

## Tests actually performed
- GitHub connector read/compare of base documents and PR summaries.
- Checked official National Park trekking page and trail page text via web search.
- After write, perform readback of Swift and CSV and count rows/IDs; no Xcode build, Swift compilation, on-device UI test, route walking, GPX validation or licensing approval.
- Before merging, review compile and iPhone/watchOS behavior, and coordinate any conflicts with other active PRs.

## Next session
Find primary sources that explicitly document *actual summit* approaches for missing shortcuts (Giovo, Rondinaio, Cimone, Corno alle Scale, Libro Aperto, Spigolino, Gennaio; Apuane peaks), not just nearby trails. Integrate only when grade and itinerary claims are backed by a specific source. Keep independent PRs and reconcile matrix before merge.
