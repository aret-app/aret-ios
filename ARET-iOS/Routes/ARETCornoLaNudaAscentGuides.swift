import Foundation

/// Independent Bologna-side La Nuda summit itinerary. Text only, no verified GPX.
/// Do not conflate this peak with La Nuda near Cerreto / Lago Pranda.
enum ARETCornoLaNudaAscentGuides {
    static let entries: [MountainAscentGuide] = [
        MountainAscentGuide(
            id: "appennino-corno-la-nuda-pianaccio",
            region: .appennino,
            summit: "Monte La Nuda (Corno alle Scale)",
            title: "Pianaccio – Balzi del Fabuino – La Nuda – Segavecchia – Pianaccio",
            discipline: .hiking,
            documentedDifficulty: "E · classificazione Ente Parchi Emilia Orientale · 5 h 30 min · 12,3 km",
            itinerary: "L'anello ufficiale parte da Pianaccio, risale verso Sboccata dei Bagnadori e Balzi del Fabuino, raggiunge esplicitamente la vetta del Monte La Nuda del gruppo del Corno alle Scale, poi scende verso il Rifugio Segavecchia e rientra a Pianaccio lungo la pista forestale.",
            caution: "Attenzione: questa La Nuda NON è la cima omonima presso il Lago Pranda/Passo del Cerreto. L'Ente segnala tratti alti impegnativi con fondo scivoloso. La fonte offre un GPX, ma ARET non lo ha importato né verificato e non fornisce navigazione su questa scheda. Controllare condizioni e accessibilità con l'Ente prima di partire.",
            sourceName: "Ente Parchi Emilia Orientale — Il Monte La Nuda (Corno alle Scale)",
            sourceURL: URL(string: "https://www.enteparchi.bo.it/parco.corno.scale/itinerari-dettaglio.php?id_iti=1061")!,
            searchTerms: ["monte la nuda corno alle scale", "la nuda corno alle scale", "pianaccio", "balzi del fabuino", "rifugio segavecchia"]
        )
    ]
}
