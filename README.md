# ARET — guida al progetto

**Every line. One map.** 🏔️

ARET è un'app nativa per iPhone e Apple Watch dedicata alla montagna. La
visione è accompagnare l'utente dalla prima escursione fino ad arrampicata
e alpinismo, mantenendo l'esperienza semplice. **La fase attuale è ARET
Hiking**, con una beta geografica concentrata su **Alpi Apuane e Appennino
tosco-emiliano**.

Questa è una **beta in sviluppo**, non un prodotto pubblico collaudato:
la presenza di codice nel repository **non equivale a una build Xcode
verificata sul dispositivo**.

## Da dove cominciare (anche per Claude / altri assistenti AI)

| Documento | A cosa serve |
| --- | --- |
| [Panoramica del prodotto e stato](docs/PRODUCT_AND_STATUS.md) | Che cos'è ARET, cosa funziona nel codice, cosa manca |
| [Architettura e mappa dei file](docs/ARCHITECTURE.md) | Target, servizi, flussi dati, componenti iOS/Watch |
| [Scoperta vette e vie nelle aree pilota](docs/REGIONAL_DISCOVERY.md) | Geografia, query OSM, metadati e limiti dei percorsi |
| [Meteo, dati, licenze e sicurezza](docs/DATA_SOURCES_AND_SAFETY.md) | Open-Meteo, Overpass, OpenFreeMap, DEM, responsabilità |
| [Setup e collaborazione](docs/DEVELOPMENT.md) | Come compilare e lavorare in due con branch/PR |
| [Piano di test](docs/QA_SCENARIOS.md) | Scenario Procinto, Pisanino, Cusna e test sul campo |
| [Roadmap tecnica](docs/HIKING_PLAN.md) | Prossimi obiettivi e criteri prima di un rilascio |
| [CLAUDE.md](CLAUDE.md) | Regole contestuali per Claude Code / altri agenti |
| [AGENTS.md](AGENTS.md) | Regole condivise tra assistenti di coding |

## Esperienza utente

**Esplora** → mappa, posizione, selezione percorso, registrazione GPS, SOS.
Due motori alternativi: **MapKit** e **MapLibre / OpenFreeMap Liberty**
nella modalità *ARET Sentieri (beta)*.

**Itinerari** → scorciatoie di vette, filtro geografico (entrambe/Apuane/
Appennino), catalogo di cime `natural=peak` da OpenStreetMap, ricerca
delle route relations e dei segmenti di ferrata effettivamente mappati.
Schede di salita curate e corredate di fonte per **Procinto e Pisanino**.
Importazione ed esportazione **GPX**, libreria percorsi personali.

**Attività** → cronologia GPS, statistiche e riutilizzo delle attività
come itinerario.

**Meteo** → Open-Meteo, previsioni orarie/giornaliere, finestra di salita,
indicazioni prudenti e spiegabili, zero termico, visibilità, vento su
livelli atmosferici e raffiche; lettura fino a tre posizioni del percorso,
quando disponibili.

**Profilo** → privacy e preferenze di tracciamento.

**Apple Watch** → workout HealthKit, metriche, mini-traccia selezionata,
alert fuori percorso, SOS e tentativo di avvio automatico registrazione
iPhone tramite workout mirroring. **Test end-to-end su hardware necessari**.

## Copertura geografica della beta

- **Alpi Apuane:** dal settore Pisanino/Pizzo d'Uccello alle Panie,
  Corchia, Procinto e Matanna.
- **Appennino tosco-emiliano:** crinale e massicci di riferimento come
  Cusna, Prado, Alpe di Succiso, Marmagna, Orsaro, Giovo, Rondinaio,
  Cimone e Corno alle Scale.

**Attenzione:** il catalogo *nomi delle cime* non è un database di vie
complete. Le query live restituiscono soltanto ciò che è mappato su OSM;
molte cime possono non avere alcuna traccia verificabile. Un segmento
di ferrata NON è una via completa e non va usato per navigare. Le due
aree sono delimitate nel codice da rettangoli geografici di prototipo,
non dai confini amministrativi dei parchi.

## Installazione rapida

Requisiti: macOS con Xcode recente, [XcodeGen](https://github.com/yonaskolb/XcodeGen),
iPhone iOS 18+, Watch watchOS 11+ per test reali. Il progetto è generato
da **`project.yml`**, non modificare manualmente un `.xcodeproj` generato.

```bash
git clone https://github.com/lorenzopieri99/Aret.git
cd Aret
git fetch origin
git switch feature/field-test-0.1
brew install xcodegen
xcodegen generate
open ARET.xcodeproj
```

In Xcode:
1. Assegna il tuo **Development Team** nei target ARET, ARETWatch e
   ARETLiveActivity (Signing & Capabilities).
2. Attendi la risoluzione del package Swift **MapLibre**.
3. Scegli lo scheme `ARET` e il dispositivo iPhone, poi `⌘B` e `⌘R`.
4. Per Watch, scegli `ARETWatch` e il dispositivo abbinato.
5. Accetta i permessi Posizione/Health quando richiesti.

Non sono inclusi database cloud, credenziali Supabase, account utente o
sincronizzazione cloud dei GPX. Le attività restano locali (i servizi
mappe/meteo inviano comunque normali richieste HTTPS ai provider).

## Lavorare in due

Leggete per prima cosa [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
Per nuove funzioni usate un **branch dedicato + Pull Request**.
Non fate modificare allo stesso tempo a due AI il medesimo file senza
coordinamento: in particolare `RoutePlanningView.swift`,
`OnlineRouteSearchService.swift`, `FieldWeatherService.swift` e
`project.yml` hanno effetti trasversali. Il ramo storico
`feature/field-test-0.1` contiene gli aggiornamenti di prototipazione
e non deve essere considerato automaticamente equivalente a `main`.

## Limiti importanti

- **Niente carte topografiche offline complete ancora.** Esiste una base
  MapLibre vettoriale online; curve di livello, hillshade e pacchetti
  offline regionali restano da sviluppare.
- **Ricerca OSM best effort.** Nessuna promessa di tutte le vie/cime,
  difficoltà certa o tracce necessariamente dirette alla vetta.
- **Meteo non certifica la sicurezza.** Le condizioni reali di neve,
  ghiaccio, valanghe, caduta sassi e percorribilità richiedono fonti
  e competenze ulteriori.
- **La build non è certificata finché non passa Xcode e i test sul campo.**
- **Provider pubblici:** Overpass, Open-Meteo e OpenFreeMap hanno limiti
  di utilizzo; una distribuzione commerciale richiede una verifica
  contrattuale e spesso un'infrastruttura cache dedicata.

Consulta la documentazione collegata prima di ampliare l'app.
