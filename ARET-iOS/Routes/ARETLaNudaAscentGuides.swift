import Foundation

/// Primary-source-linked, text-only itinerary candidates.
enum ARETLaNudaAscentGuides {
    static let entries: [MountainAscentGuide] = [
        MountainAscentGuide(
            id: "appennino-la-nuda-pranda",
            region: .appennino,
            summit: "Monte la Nuda",
            title: "Dal Lago Pranda alla vetta del Monte la Nuda",
            discipline: .hiking,
            documentedDifficulty: "Non indicata dalla fonte · circa 2 h dal Pranda (Parco)",
            itinerary: "Il Parco Nazionale dell'Appennino Tosco-Emiliano menziona un percorso dal lago Pranda fino alla vetta del Monte la Nuda, con tempo indicativo di 2 ore. Il sito cita separatamente un circuito da Cerreto Laghi al lago Pranda: non è verificato qui un collegamento integrale di andata e ritorno.",
            caution: "Il Parco non attribuisce una classe di difficoltà a questa proposta sintetica. Non è documentato qui un percorso completo con discesa, né una traccia GPX. Verificare la descrizione originale, le condizioni e la percorribilità; non usare la scheda per navigare.",
            sourceName: "Parco Nazionale Appennino Tosco-Emiliano — Trekking",
            sourceURL: URL(string: "https://parcoappennino.it/pagina.php?id=68")!,
            searchTerms: ["monte la nuda", "la nuda", "lago pranda", "cerreto laghi"]
        )
    ]
}
