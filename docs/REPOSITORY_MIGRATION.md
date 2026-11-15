# Trasferimento del prototipo — 15 novembre 2026

Il repository di sviluppo è [aret-app/aret-ios](https://github.com/aret-app/aret-ios).
Il precedente [lorenzopieri99/Aret](https://github.com/lorenzopieri99/Aret)
conserva il contesto storico; nuove modifiche e review vanno nel repository
ARET. Attività: [issue #8](https://github.com/aret-app/aret-ios/issues/8).
Le assegnazioni delle PR sono gestite dal maintainer.

## Corrispondenza delle PR

I numeri nei vecchi documenti CATALOG_SESSION e OFFICIAL_ROUTE_EVIDENCE
si riferiscono al repository precedente. Usare questa tabella per interpretarli.

| Vecchia PR | Nuova PR | Contenuto e stato del trasferimento |
| --- | --- | --- |
| [#1](https://github.com/lorenzopieri99/Aret/pull/1) | [#3](https://github.com/aret-app/aret-ios/pull/3) | Prototipo già importato su main; vecchia PR chiusa, nessuna duplicazione |
| [#3](https://github.com/lorenzopieri99/Aret/pull/3) | [#12](https://github.com/aret-app/aret-ios/pull/12) | Quattro schede testuali: Ventasso, Sillano, avvicinamento Corchia, giro di zona Sagro |
| [#4](https://github.com/lorenzopieri99/Aret/pull/4) | [#13](https://github.com/aret-app/aret-ios/pull/13) | Ricerca documentale Cusna/Prado; zero schede aggiunte all'app |
| [#5](https://github.com/lorenzopieri99/Aret/pull/5) | [#14](https://github.com/aret-app/aret-ios/pull/14) | La Nuda presso Cerreto/Lago Pranda; grado sconosciuto, rientro non verificato |
| [#6](https://github.com/lorenzopieri99/Aret/pull/6) | [#15](https://github.com/aret-app/aret-ios/pull/15) | Anello Spigolino da fonte del Parco; solo testo |
| [#7](https://github.com/lorenzopieri99/Aret/pull/7) | [#16](https://github.com/aret-app/aret-ios/pull/16) | La Nuda al Corno alle Scale; montagna distinta da Cerreto |

Le nuove PR #12–#16 sono bozze verso `feature/field-test-0.1`. Nessuna è
stata unita durante il trasferimento. Le vecchie PR sono chiuse e riportano
il collegamento alla sostituta, conservando la descrizione originale.
Non c'erano commenti o review nelle sei vecchie PR al momento del controllo.

La vecchia #7 non compariva nell'elenco iniziale della issue #8. Il suo branch
è stato copiato ora nel repository ARET, senza alterare commit o contenuti.

## Identità dei branch conservati

| Branch | SHA originale / trasferito |
| --- | --- |
| feature/ascent-sources-2026-11-15 | cc7a58138d88a54ade77b9cad0fc9a28d396669c |
| docs/official-route-evidence-20261115 | bf2c553885340373da395c91188b554c8f77067e |
| feature/catalog-la-nuda-20261115 | dd578e7fef9e8bcef24f2a9177914d4810551d68 |
| feature/catalog-spigolino-20261115 | c8eeabbf51a4e8f152935ca65cee0a0a4393494e |
| feature/catalog-la-nuda-corno-20261115 | 2397eb84df385b21325bc629d8ed37fff0124c24 |

Il contenuto della vecchia PR #1 allo SHA `3987c38` coincide con `main`
ARET allo SHA `7369ba6`, salvo LICENSE e nota relativa nel README. Per questo
non è stata riaperta una PR duplicata per il prototipo. Il branch storico
resta disponibile; non è stata riscritta la sua storia.

## Ordine e vincoli per la review

1. #13 è indipendente e contiene solo ricerca. Le sue fonti non equivalgono
   a GPX verificati, nuove schede integrate o autorizzazione alla copia.
2. Revisionare #12, poi #14–#16. Le quattro PR del catalogo modificano la
   stessa registrazione in MountainAscentGuide.swift e lo stesso CSV.
   Dopo ogni merge occorre riconciliare la registrazione degli array e
   ricalcolare ID unici, schede e conteggi. Non accettare un conflitto
   scegliendo l'intero file di una sola PR.
3. Prima di unire le due La Nuda, distinguere le identità geografiche:
   Cerreto/Lago Pranda e Corno alle Scale/Pianaccio. La riga legacy
   `Monte la Nuda` è ambigua e non dimostra copertura di entrambe le vette.
4. Le descrizioni originali delle PR e i documenti di sessione contengono
   conteggi isolati e riferimenti storici: non sommarli automaticamente.
5. Nessuna scheda trasferita contiene un GPX completo verificato. Corchia
   e Sagro della #12 non sono salite documentate alla vetta.

## Verifiche effettivamente eseguite

- Identità SHA dei cinque branch rispetto alle vecchie PR.
- Diff confrontati con la base d'integrazione `8844206`.
- `git merge-tree --write-tree`: ciascuna PR si integra individualmente
  senza conflitti contro quella base. Questo non verifica i merge cumulativi.
- `git diff --check` passato per tutti i cinque diff.
- Parsing Swift 6.0.3 dei file Swift modificati passato.
- Ogni CSV conserva 48 righe e zero `full_gpx_verified=yes`.
  #12 isolata: 23 nomi con fonte; #14/#15/#16 isolate: 20 ciascuna.

Non eseguiti: build Xcode con SDK Apple, simulatore, iPhone/Watch, prove sul
campo, nuova verifica delle fonti online o autorizzazioni al riuso dei dati.
Il trasferimento non modifica codice, geometrie, permessi o provider.

## Archiviazione e contesto residuo

La checklist operativa e lo stato di archiviazione sono nella issue #8.
Archiviare il vecchio repository solo dopo aver verificato nuove PR e link
nelle vecchie. Conservare il repository privato come archivio leggibile;
non cancellarlo, non cambiare visibilità e non eliminare i vecchi branch.

Nel vecchio repository esiste anche la [issue #2](https://github.com/lorenzopieri99/Aret/issues/2)
sulla creazione di un backend. Resta un riferimento storico, non un nuovo
requisito introdotto dalla migrazione. Il repository
[aret-app/aret-backend](https://github.com/aret-app/aret-backend) esiste già;
le decisioni su linguaggio e granularità sono tracciate in
[aret-docs #2](https://github.com/aret-app/aret-docs/issues/2) e
[aret-docs #4](https://github.com/aret-app/aret-docs/issues/4).
