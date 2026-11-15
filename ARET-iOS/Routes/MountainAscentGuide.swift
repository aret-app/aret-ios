import Foundation

/// A source-backed ascent description, not a navigable GPS trace.
/// Options without verified geometry MUST NOT be drawn as routes or exported.
struct MountainAscentGuide: Identifiable, Hashable {
    enum Discipline: String {
        case hiking = "Escursionismo"
        case ferrata = "Via ferrata"
        case mountaineering = "Itinerario alpinistico"

        var symbol: String {
            switch self {
            case .hiking: return "figure.hiking"
            case .ferrata: return "figure.climbing"
            case .mountaineering: return "mountain.2.fill"
            }
        }
    }

    let id: String
    let region: ARETPilotRegion
    let summit: String
    let title: String
    let discipline: Discipline
    let documentedDifficulty: String
    let itinerary: String
    let caution: String
    let sourceName: String
    let sourceURL: URL
    let searchTerms: [String]

    var navigationNote: String {
        "Scheda informativa con fonte. Traccia GPS completa non ancora verificata: non usarla per navigare."
    }
}

enum MountainAscentLibrary {
    // Sources: CAI archive, Parco Apuane, Pro Loco Seravezza,
    // AlpiApuane.eu. These records do not include invented coordinates.
    static let guides: [MountainAscentGuide] = [
        MountainAscentGuide(
            id: "procinto-bruni",
            region: .apuane,
            summit: "Monte Procinto",
            title: "Ferrata Aristide Bruni (via d'accesso alla vetta)",
            discipline: .ferrata,
            documentedDifficulty: "Ferrata • CAI: Facile (ma verticale ed esposta)",
            itinerary: "Da Stazzema, sentiero CAI 5, Rifugio Forte dei Marmi, Cintura del Procinto e ferrata fino alla sommità. È l'accesso più agevole documentato alla cima, non un sentiero escursionistico.",
            caution: "Ferrata tecnica ed esposta: servono attrezzatura omologata, competenze adeguate e verifica di condizioni e percorribilità. La discesa può comportare il ripercorrere la ferrata.",
            sourceName: "Archivio Club Alpino Italiano — Ferrata del Procinto",
            sourceURL: URL(string: "https://archivio.cai.it/wp-content/uploads/2024/03/2024_04_07-Ferrata-Procinto.pdf")!,
            searchTerms: ["procinto", "aristide bruni", "ferrata bruni", "ferrata del procinto"]
        ),
        MountainAscentGuide(
            id: "pisanino-normale",
            region: .apuane,
            summit: "Monte Pisanino",
            title: "Via normale — Foce di Cardeto e Canale delle Rose",
            discipline: .hiking,
            documentedDifficulty: "EE • escursionisti esperti",
            itinerary: "Da Val Serenaia/Orto di Donna, sentiero CAI 178 per Foce di Cardeto; poi traccia di vetta verso Foce dell'Altare e Canale delle Rose. Tratti esposti e passaggi impegnativi.",
            caution: "Non è una passeggiata: percorso lungo, ripido, con tratti esposti e orientamento non banale. La difficoltà aumenta molto con pioggia, neve o ghiaccio.",
            sourceName: "Pro Loco Seravezza — Monte Pisanino",
            sourceURL: URL(string: "https://www.prolocoseravezza.it/escursione-it.php?nome=Monte+Pisanino")!,
            searchTerms: ["pisanino", "via normale pisanino", "foce di cardeto", "canale delle rose"]
        ),
        MountainAscentGuide(
            id: "pisanino-bagola",
            region: .apuane,
            summit: "Monte Pisanino",
            title: "Bagola Bianca — cresta nord-ovest",
            discipline: .mountaineering,
            documentedDifficulty: "Passaggi di I grado • esposizione",
            itinerary: "Dal settore Val Serenaia/Rifugio Donegani si raggiunge la costola della Bagola Bianca e si prosegue sulla cresta nord-ovest verso la vetta.",
            caution: "Più tecnica ed esposta della normale; non indicata come discesa improvvisata. Serve capacità di muoversi su terreno alpinistico e valutare le condizioni.",
            sourceName: "AlpiApuane.eu — Accessi al Monte Pisanino",
            sourceURL: URL(string: "https://www.alpiapuane.eu/index.php/apuane-settentrionali/monte-pisanino")!,
            searchTerms: ["pisanino", "bagola bianca", "cresta nord ovest"]
        ),
        MountainAscentGuide(
            id: "cusna-roncopianigi",
            region: .appennino,
            summit: "Monte Cusna",
            title: "Anello escursionistico da Roncopianigi",
            discipline: .hiking,
            documentedDifficulty: "E · classificazione Ente Parco · circa 5 h 30 min · +1100 m",
            itinerary: "Itinerario pubblicato dall'Ente Parco con partenza e rientro a Roncopianigi, passaggio da Peschiera Zamboni, salita al Cusna e rientro per Passo Cisa. Segnavia indicati dal Parco: 609, 623A, 623, 625 e 619.",
            caution: "D+ elevato e ambiente montano; il grado E è quello attribuito dal Parco all'itinerario estivo, non una promessa di percorribilità con neve, ghiaccio o maltempo. Controllare la segnaletica e il tracciato aggiornato.",
            sourceName: "Parco Nazionale Appennino tosco-emiliano — Monte Cusna",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=76")!,
            searchTerms: ["monte cusna", "cusna", "roncopianigi", "peschiera zamboni"]
        ),
        MountainAscentGuide(
            id: "cusna-rif-battisti",
            region: .appennino,
            summit: "Monte Cusna",
            title: "Traversata Rifugio Battisti – Monte Cusna – Casalino",
            discipline: .hiking,
            documentedDifficulty: "E+ · classificazione Ente Parco · circa 6 h",
            itinerary: "Tappa di traversata dal Rifugio Battisti con salita al Monte Cusna e prosecuzione verso Casalino. L'Ente Parco riporta segnavia 615, 607, 625, 635, 633 e 609.",
            caution: "Non è un anello: partenza e arrivo differenti. L'Ente Parco riporta circa 500 m di salita e 1350 m di discesa. Pianificare il recupero e verificare le condizioni del crinale.",
            sourceName: "Parco Nazionale — Rif. Battisti / Cusna / Casalino",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=118&id_zona=8")!,
            searchTerms: ["monte cusna", "cusna", "rifugio battisti", "casalino", "traversata cusna"]
        ),
        MountainAscentGuide(
            id: "succiso-anello",
            region: .appennino,
            summit: "Alpe di Succiso",
            title: "Anello da Succiso Nuovo",
            discipline: .hiking,
            documentedDifficulty: "E+ · classificazione Ente Parco · circa 6 h 30 min · +1080 m",
            itinerary: "L'anello descritto dall'Ente Parco parte da Succiso Nuovo, raggiunge I Ghiaccioni e Pietratagliata, sale all'Alpe di Succiso e rientra nella valle del Rio Pascolo.",
            caution: "Giornata lunga, dislivello importante e ambiente aperto d'alta quota. La descrizione del Parco si riferisce al periodo estivo (indicativamente giugno-ottobre); controllare neve, vento e possibili tratti non percorribili.",
            sourceName: "Parco Nazionale — Alpe di Succiso",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=91")!,
            searchTerms: ["alpe di succiso", "succiso", "pietratagliata", "rio pascolo"]
        ),
        MountainAscentGuide(
            id: "orsaro-lagdei",
            region: .appennino,
            summit: "Monte Orsaro",
            title: "Anello Lagdei – Lago Santo – Monte Orsaro",
            discipline: .hiking,
            documentedDifficulty: "E · classificazione Ente Parco · circa 4 h 30 min",
            itinerary: "Partenza e rientro da Lagdei, con salita verso il Lago Santo, Bocchetta dell'Orsaro, vetta del Monte Orsaro e rientro per il crinale. L'Ente Parco riporta i segnavia 729, 00 e 725.",
            caution: "I tratti di crinale possono risultare ripidi o esposti al vento. Verificare sul sito dell'Ente Parco tempi, deviazioni e sentieri; non usare questa scheda testuale come navigazione.",
            sourceName: "Parco Nazionale — Monte Orsaro",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=95")!,
            searchTerms: ["monte orsaro", "orsaro", "lagdei", "lago santo", "bocchetta dell'orsaro"]
        ),
        MountainAscentGuide(
            id: "sillara-pratospilla",
            region: .appennino,
            summit: "Monte Sillara",
            title: "Anello da Prato Spilla e Laghi Sillara",
            discipline: .hiking,
            documentedDifficulty: "E · classificazione Ente Parco · circa 6 h 30 min · +750 m",
            itinerary: "Il percorso dell'Ente Parco attraversa Lago Verde, laghi di Compione e laghi Sillara, tocca il Monte Sillara e rientra per Passo di Compione e Lago Martini. Segnavia 707, 00, 705.",
            caution: "L'Ente Parco segnala anche tratti non marcati: serve capacità di orientamento. Crinale esposto al vento; attenzione in condizioni di nebbia, neve e ghiaccio.",
            sourceName: "Parco Nazionale — Monte Sillara",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=96")!,
            searchTerms: ["monte sillara", "sillara", "prato spilla", "laghi sillara", "laghi di compione"]
        ),
        MountainAscentGuide(
            id: "bismantova-anello",
            region: .appennino,
            summit: "Pietra di Bismantova",
            title: "Anello escursionistico da Piazzale Dante",
            discipline: .hiking,
            documentedDifficulty: "T+ · classificazione Ente Parco · circa 2 h 30 min · +280 m",
            itinerary: "L'anello segnalato dall'Ente Parco parte da Piazzale Dante, attraversa il settore di Campo Pianelli e raggiunge il pianoro della Pietra, con rientro per i sentieri indicati 697 e SSP e brevi tratti non marcati.",
            caution: "Il pianoro è bordato da pareti verticali: mantenersi lontani dai bordi. Il percorso escursionistico NON coincide con le vie di arrampicata né con eventuali ferrate.",
            sourceName: "Parco Nazionale — Pietra di Bismantova",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=105")!,
            searchTerms: ["pietra di bismantova", "bismantova", "piazzale dante", "campo pianelli"]
        ),
        MountainAscentGuide(
            id: "acuto-lagastrello",
            region: .appennino,
            summit: "Monte Acuto",
            title: "Anello dal Passo del Lagastrello",
            discipline: .hiking,
            documentedDifficulty: "T · classificazione Ente Parco · circa 5 h · +650 m",
            itinerary: "Anello con partenza e rientro al Passo del Lagastrello, nel settore di Monte Acuto e del Rifugio Sarzana, come descritto dall'Ente Parco. Il Parco riporta i segnavia 659B, 659A, 653, 657 e 00.",
            caution: "La classificazione T è quella attribuita dal Parco alla propria proposta, ma cinque ore e 650 m di D+ richiedono comunque preparazione. Non presumere che ogni deviazione raggiunga la sommità.",
            sourceName: "Parco Nazionale — Monte Acuto",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=89")!,
            searchTerms: ["monte acuto", "acuto", "lagastrello", "rifugio sarzana"]
        )
    ]

    static func results(for query: String) -> [MountainAscentGuide] {
        let normalized = normalize(query)

        guard !normalized.isEmpty else { return [] }

        return guides.filter { guide in
            guide.searchTerms.contains { term in
                let normalizedTerm = normalize(term)
                return normalized.contains(normalizedTerm) ||
                    (normalized.count >= 5 &&
                     normalizedTerm.contains(normalized))
            }
        }
    }

    static func preferredSearchCenter(for query: String) -> String? {
        let normalized = normalize(query)
        if normalized.contains("procinto") ||
            normalized.contains("bruni") {
            return "Monte Procinto, Stazzema, Toscana, Italia"
        }
        if normalized.contains("pisanino") ||
            normalized.contains("bagola bianca") ||
            normalized.contains("canale delle rose") {
            return "Monte Pisanino, Minucciano, Toscana, Italia"
        }
        if let matchingGuide = results(for: query).first {
            let regionLabel = matchingGuide.region == .apuane
                ? "Alpi Apuane, Toscana, Italia"
                : "Appennino tosco-emiliano, Italia"
            return "\(matchingGuide.summit), \(regionLabel)"
        }

        return nil
    }

    private static func normalize(_ text: String) -> String {
        text.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "it_IT")
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
