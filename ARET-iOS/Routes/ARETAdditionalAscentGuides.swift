import Foundation

/// Short, source-linked, NON-navigable hiking proposals.
/// Never convert these text descriptions into route coordinates.
/// Source classifications and durations describe the cited itinerary,
/// not all ways of reaching the mountain.
enum ARETAdditionalAscentGuides {
    static let entries: [MountainAscentGuide] = [
        MountainAscentGuide(
            id: "apuane-anello-panie",
            region: .apuane,
            summit: "Le Panie",
            title: "Anello delle Panie",
            discipline: .hiking,
            documentedDifficulty: "EE · circa 6 h (fonte Parco Apuane)",
            itinerary: "Itinerario escursionistico ad anello nel gruppo delle Panie, censito dal Parco delle Alpi Apuane tra le proposte classiche.",
            caution: "Itinerario classificato EE dalla fonte: richiede esperienza, orientamento e attenzione su terreno apuano ripido. Questa scheda non descrive una traccia completa né certifica il raggiungimento di tutte le vette.",
            sourceName: "Parco Alpi Apuane — Piano turismo sostenibile",
            sourceURL: URL(string: "https://parcapuane.toscana.it/turismo/apuan_alps_cets_strategy_action_plan_2023_3.pdf")!,
            searchTerms: ["pania", "panie", "pania della croce", "anello delle panie"]
        ),
        MountainAscentGuide(
            id: "apuane-forato-anello",
            region: .apuane,
            summit: "Monte Forato",
            title: "Anello escursionistico del Monte Forato",
            discipline: .hiking,
            documentedDifficulty: "E · circa 5 h · ~700 m D+ (fonte Parco Apuane)",
            itinerary: "Anello descritto nella documentazione del Parco con partenza a Fornovolasco, passaggio per Foce di Petrosciana tramite sentiero CAI 6 e rientro sul versante di Foce di Valli mediante i sentieri indicati nella fonte.",
            caution: "È distinto dalla ferrata del Monte Forato. La pagina del Parco presenta varianti di rientro; consultare la fonte originale e la segnaletica prima di partire.",
            sourceName: "Parco Alpi Apuane — Piano gestione Corchia–Panie",
            sourceURL: URL(string: "https://www.parcapuane.toscana.it/DOCUMENTI/TRASPARENZA/pianificazione_governo_territorio/piani_gestione_natura_2000/monte_corchia_panie_IT5120014/Monte_Corchia_Panie_RELAZIONE.pdf")!,
            searchTerms: ["monte forato", "forato", "anello monte forato", "foce petrosciana", "fornovolasco"]
        ),
        MountainAscentGuide(
            id: "apuane-forato-salvatori",
            region: .apuane,
            summit: "Monte Forato",
            title: "Ferrata Renato Salvatori — traversata del Forato",
            discipline: .ferrata,
            documentedDifficulty: "EEA / tratti EE · CAI 110A (ferrata)"
            itinerary: "Via attrezzata sul settore del Monte Forato descritta dal Parco delle Apuane, nel contesto di Foce di Petrosciana e delle due sommità collegate dall'arco naturale.",
            caution: "È una ferrata: casco, imbrago, set omologato e capacità di progressione sono fondamentali. Non usare la qualifica storica di facile come valutazione attuale. Verificare chiusure, stato dei cavi e uscita.",
            sourceName: "CAI Toscana — elenco sentieri 2025, ferrata 110A",
            sourceURL: URL(string: "https://organizzazione.cai.it/gr-toscana/wp-content/uploads/sites/66/2025/10/Sentieri-CAI-ufficiale-21-10-2025.pdf")!,
            searchTerms: ["monte forato", "forato", "renato salvatori", "ferrata salvatori"]
        ),
        MountainAscentGuide(
            id: "apuane-campocatino-san-viano",
            region: .apuane,
            summit: "Campocatino / Roccandagia",
            title: "Sentiero Natura — Eremo di San Viano",
            discipline: .hiking,
            documentedDifficulty: "E · circa 2 h 30 min (fonte Parco Apuane)",
            itinerary: "Percorso escursionistico tra l'altopiano di Campocatino e l'Eremo di San Viano, ai piedi delle balze orientali della Roccandagia.",
            caution: "Non è un'ascesa alla vetta della Roccandagia. L'eremo si trova in ambiente roccioso: seguire esclusivamente il sentiero e verificare accesso e percorribilità.",
            sourceName: "Parco Alpi Apuane — Piano turismo sostenibile",
            sourceURL: URL(string: "https://parcapuane.toscana.it/turismo/apuan_alps_cets_strategy_action_plan_2023_3.pdf")!,
            searchTerms: ["campocatino", "san viano", "eremo san viano", "roccandagia"]
        ),
        MountainAscentGuide(
            id: "appennino-monte-tondo",
            region: .appennino,
            summit: "Monte Tondo",
            title: "Anello da Ponteccio",
            discipline: .hiking,
            documentedDifficulty: "E · 5 h · +750 m (Ente Parco)",
            itinerary: "Proposta pubblicata dall'Ente Parco con partenza e arrivo a Ponteccio, attraversamento di La Corona e salita alla zona del Monte Tondo.",
            caution: "La scheda ufficiale indica segnavia presenti solo in parte, con un tratto non marcato. Necessaria capacità di orientamento, oltre a verifica della percorribilità.",
            sourceName: "Parco Nazionale — Monte Tondo",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=71")!,
            searchTerms: ["monte tondo", "ponteccio", "corona"]
        ),
        MountainAscentGuide(
            id: "appennino-pania-corfino",
            region: .appennino,
            summit: "Pania di Corfino",
            title: "Anello da Corfino",
            discipline: .hiking,
            documentedDifficulty: "E · 5 h 30 min · +790 m (Ente Parco)",
            itinerary: "Dalla località di Corfino la proposta del Parco si sviluppa fra Campaiana, Pania di Corfino e il settore del rifugio Isera, con rientro a Corfino.",
            caution: "Alcuni attraversamenti su pendii detritici e tratti di sottobosco possono essere ostacolati da frane e vegetazione. Evitare il percorso con condizioni incerte e verificare segnavia e aggiornamenti.",
            sourceName: "Parco Nazionale — Pania di Corfino",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=70")!,
            searchTerms: ["pania di corfino", "corfino", "campaiana", "isera"]
        ),
        MountainAscentGuide(
            id: "appennino-cisa-prampa",
            region: .appennino,
            summit: "Monte Cisa / Monte Prampa",
            title: "Anello Monte Cisa e Monte Prampa",
            discipline: .hiking,
            documentedDifficulty: "E+ · 4 h 30 min · +600 m (Ente Parco)",
            itinerary: "Itinerario dal Rifugio Monteorsaro, con passaggio nel settore del Monte Cisa e del Monte Prampa e rientro al punto di partenza.",
            caution: "L'Ente Parco segnala una marcatura solo parziale. Tracce poco battute e pendii ripidi richiedono orientamento e prudenza.",
            sourceName: "Parco Nazionale — Monte Cisa e Monte Prampa",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=77")!,
            searchTerms: ["monte cisa", "monte prampa", "cisa", "prampa", "monteorsaro"]
        ),
        MountainAscentGuide(
            id: "appennino-monte-vecchio",
            region: .appennino,
            summit: "Monte Vecchio",
            title: "Scaloni e Monte Vecchio",
            discipline: .hiking,
            documentedDifficulty: "E+ · 7 h · +850 m (Ente Parco)",
            itinerary: "Traversata escursionistica ad anello proposta dall'Ente Parco nella zona dell'Orecchiella e della Bocca di Scala, fra alpeggi, boschi e rilievi del Monte Vecchio.",
            caution: "Uscita lunga e faticosa. Attenzione alla differenza fra il toponimo del percorso e il raggiungimento della vera vetta; verificare il tracciato integrale nella fonte.",
            sourceName: "Parco Nazionale — Scaloni e Monte Vecchio",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=104")!,
            searchTerms: ["monte vecchio", "scaloni", "bocca di scala", "orecchiella"]
        ),
        MountainAscentGuide(
            id: "appennino-vallestrina-passone",
            region: .appennino,
            summit: "Alpe di Vallestrina / Passone",
            title: "Anello Vallestrina e Passone",
            discipline: .hiking,
            documentedDifficulty: "E · 5 h · +850 m (Ente Parco)",
            itinerary: "Anello proposto dal Parco dalla località Rescadore di Febbio, attraverso i pascoli e il settore dell'Alpe di Vallestrina e Passone, con ritorno al punto di partenza.",
            caution: "Alte quote e versanti esposti al meteo: nebbia e vento possono rendere difficile orientamento e rientro. Non equiparare automaticamente il passaggio vicino alla montagna alla salita alla sua sommità.",
            sourceName: "Parco Nazionale — Vallestrina e Passone",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=75")!,
            searchTerms: ["vallestrina", "alpe di vallestrina", "passone", "febbio", "febbio"]
        ),
        MountainAscentGuide(
            id: "appennino-marmagna-logarghena",
            region: .appennino,
            summit: "Monte Marmagna / Logarghena",
            title: "Logarghena e Marmagna",
            discipline: .hiking,
            documentedDifficulty: "E+ (Ente Parco) · durata non indicata nella scheda",
            itinerary: "Il Parco descrive un anello con partenza a Rocca Sigillina e località di passaggio nella zona di Logarghena, Bocchetta dell'Orsaro, Lago Santo e Passo dell'Aquila.",
            caution: "La scheda pubblicata non garantisce che l'itinerario tocchi la vetta del Marmagna. Non interpretarlo come GPX completo di salita; verificare sul posto il percorso esatto.",
            sourceName: "Parco Nazionale — Logarghena e Marmagna",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=98")!,
            searchTerms: ["marmagna", "logarghena", "rocca sigillina", "passo dell'aquila"]
        ),
        MountainAscentGuide(
            id: "appennino-prado-traversata",
            region: .appennino,
            summit: "Monte Prado",
            title: "Traversata del crinale dal Prado all'Orsaro",
            discipline: .hiking,
            documentedDifficulty: "E+ · itinerario a più tappe (Ente Parco)",
            itinerary: "Il Parco propone una traversata lunga che tocca il settore del Monte Prado e prosegue sul crinale appenninico verso Monte Orsaro, con possibilità di pernottamento in rifugi.",
            caution: "NON è una normale escursione giornaliera: richiede piano delle tappe, logistica, meteo per più giorni e verifica di aperture. Il titolo non sostituisce la descrizione di ogni singola salita.",
            sourceName: "Parco Nazionale — Traversata Appennino Tosco-Emiliano",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=109&id_zona=8")!,
            searchTerms: ["monte prado", "prado", "traversata appennino", "orsaro", "gea"]
        )
    ]
}
