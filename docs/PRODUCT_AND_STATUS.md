# ARET — visione del prodotto e stato reale

**Aggiornato: 15 novembre 2026**  
**Progetto:** iOS 18+ / watchOS 11+ — SwiftUI / Swift 6  
**Motto:** *Every line. One map.*

## La visione

ARET deve essere utile prima di tutto all'escursionista della domenica:
cercare una montagna, capire quali escursioni sono documentate, controllare
meteo, quota, difficoltà, scaricare il GPX quando disponibile, seguire la
traccia e registrare l'uscita. Il nucleo Hiking deve restare **gratuito e
semplice**. Nel tempo lo stesso prodotto crescerà per ferrate, arrampicata,
alpinismo, ghiaccio e attività tecniche, con livelli informativi distinti.

**Non stiamo copiando soltanto Komoot o Wikiloc:** la differenza cercata
è l'integrazione di ricerca delle vie, pianificazione e meteo di montagna.

## Area pilota 2026–2027

Alpi Apuane e Appennino tosco-emiliano, e non tutta Italia, Europa o mondo.
È una **delimitazione funzionale**, non una dichiarazione che abbiamo già
tutti gli itinerari. Dati e geometrie arriveranno via OSM quando presenti;
le schede narrative corredate di fonte vengono aggiunte separatamente; la verifica sul campo resta necessaria.

### Ricerca in concreto

1. L'utente sceglie *Entrambe*, *Apuane* o *Appennino*.
2. Può sfogliare scorciatoie di vette oppure l'indice di cime OSM.
3. Cerca una cima o una via. Se la cima è identificata, ARET cerca
   relazioni escursionistiche/di ferrata nelle vicinanze.
4. Se l'utente cerca il nome di una via non geocodificabile, ARET prova a
   recuperare le relazioni OSM che riportano quel nome nelle aree pilota.
5. Sono separati: (a) nome/posizione della cima, (b) scheda di salita
   documentata, (c) relazione GPS, (d) singolo tratto tecnico.
6. Non si costruiscono **tracce fittizie** per congiungere itinerari
   mancanti e non si assume che una via vicina raggiunga la vetta.

## Le cinque sezioni principali

| Sezione | Esperienza nel codice |
| --- | --- |
| Esplora | Mappa a tutto schermo, posizione, stile MapKit o ARET Sentieri online (MapLibre), linea percorso, REC GPS, SOS e meteo sintetico |
| Itinerari | Percorsi demo/personali, import GPX, ricerca montagna/via, catalogo di vette OSM, singoli segmenti sentieristici con scala OSM disponibile, schede con fonti esterne, anteprima altimetrica, export GPX |
| Attività | Cronologia, statistiche, dettaglio registrazione, GPX, possibilità di riutilizzare la traccia |
| Meteo | Open-Meteo, finestre meteo, raffiche, vento atmosferico, zero termico, visibilità, analisi fino a tre punti, previsioni prossimi giorni |
| Profilo | Privacy, gestione dati e impostazioni come Live Activity |

**Watch:** workout HealthKit, tempo, distanza, HR, calorie, quota e D+,
indicatore fuori traccia, mini-mappa, emergenza e mirroring verso iPhone.
Questi flussi necessitano test sul dispositivo.

## Distinzione fondamentale tra «nel codice» e «pronto»

| Componente | Implementazione nel branch | Verifica sul campo |
| --- | --- | --- |
| Mappa Apple + percorso GPS | Presente | Da ripetere dopo gli ultimi cambi |
| Mappa OSM MapLibre / OpenFreeMap | Presente come modalità beta online | Xcode + rendering/provider ancora da verificare |
| Ricerca vette Apuane/Appennino | Indice OSM dinamico + scorciatoie | Completezza/tempi di caricamento da verificare |
| Vie documentate | 10 schede con fonti esterne in 8 cime, tra Apuane e Appennino | Aggiornamento fonti da verificare |
| Ricerca vie/tracce regionali | Query Overpass, filtro regione, controllo geometria | Copertura e qualità OSM non garantite |
| Classificazione T/E/EE/tecnica | Solo quando disponibile da fonte/tag | Validazione campo per campo necessaria |
| Import/export GPX | Presente | Test con file reali lunghi e incompleti |
| Profilo DEM | Servizio elevazione Open-Meteo/Copernicus; grafico | Accuratezza su terreno ripido da verificare |
| Meteo decisionale | Motore euristico e UI ARET | Valore/affidabilità da testare con bollettini |
| Watch ↔ iPhone | Workout mirroring + WatchConnectivity | Test reale con schermo bloccato |
| Mappe topo offline per area | **Non implementate** | Non applicabile |
| Account, Supabase, community, cloud GPX | **Non implementati** | Non applicabile |
| Certificazione di sicurezza in montagna | **Non prevista** | Non applicabile |

## Limitazioni note (non nascondere agli utenti)

- I rettangoli geografici sono aree pilota approssimative, **non** il
  perimetro ufficiale di un parco o di una catena montuosa.
- L'indice delle vette OSM si basa su `natural=peak`: può omettere
  rilievi, includere punti marginali e duplicare nomi.
- Avere una vetta nell'indice non significa avere una o più vie complete.
- Il dataset OSM non equivale a una guida alpina: difficoltà possono
  mancare o essere sbagliate; varianti, avvicinamento e discesa spesso
  non sono modellati come unica relazione.
- Un **tratto di ferrata** non può essere presentato come sentiero E/T o
  come itinerario completo.
- La finestra meteo non equivale a «si può salire»: valutare neve,
  ghiaccio, valanghe, esposizione, rientro e osservazioni in loco.
- API pubbliche OSM e Open-Meteo non costituiscono un backend di
  produzione con disponibilità garantita.

## Direzione del prossimo lavoro

**P0 — affidabilità:** build Xcode, ricerca Apuane/Appennino, fonti,
nessun tracciato inventato, test GPS/Watch, Meteo chiaro.

**P1 — copertura:** catalogo geografico servito da backend/cache nostri,
join delle vie verificate, normalizzazione delle difficoltà CAI/SAC,
percorsi ufficiali con licenze valide, più schede di salite curatissime.

**P2 — topo offline:** stile MapLibre personalizzato, curve di livello,
DEM/hillshade, download zone e navigazione offline verificata.

**P3 — funzionalità tecniche:** arrampicata, ghiacciaio, alpinismo e
community soltanto dopo una base Hiking solida.

Vedi [HIKING_PLAN.md](HIKING_PLAN.md) per i controlli approfonditi.
