import Foundation

/// Official-park source-backed descriptions only. No verified GPX is bundled.
enum ARETSpigolinoAscentGuides {
    static let entries: [MountainAscentGuide] = [
        MountainAscentGuide(
            id: "appennino-spigolino-baita-sole",
            region: .appennino,
            summit: "Monte Spigolino",
            title: "In volo con l'aquila — anello della vetta dello Spigolino",
            discipline: .hiking,
            documentedDifficulty: "E · classificazione Ente Parchi Emilia Orientale · 6 h 30 min · 9,5 km",
            itinerary: "L'itinerario ufficiale parte dalla Baita del Sole e sale lungo il settore dei Monti della Riva fino alla vetta del Monte Spigolino. Prosegue in quota verso Passo dello Strofinatoio, tocca il Lago Scaffaiolo e il rifugio omonimo, poi scende verso il Rifugio Sasseto e torna alla Baita del Sole lungo una pista forestale.",
            caution: "È un itinerario di vetta con ritorno descritto dall'Ente Parco, ma la scheda ARET non contiene una geometria validata. La pagina ufficiale offre un GPX scaricabile: NON è stato acquisito, controllato né autorizzato per redistribuzione in ARET. Verificare aggiornamenti, condizioni del crinale e percorribilità presso l'Ente Parco prima dell'uscita.",
            sourceName: "Ente Parchi Emilia Orientale — Parco Corno alle Scale, In volo con l'aquila",
            sourceURL: URL(string: "https://enteparchi.bo.it/parco.corno.scale/itinerari-dettaglio.php?id_iti=6015")!,
            searchTerms: ["monte spigolino", "spigolino", "baita del sole", "in volo con l'aquila", "lago scaffaiolo"]
        )
    ]
}
