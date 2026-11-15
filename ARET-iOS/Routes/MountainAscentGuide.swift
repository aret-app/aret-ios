import Foundation

/// A source-backed ascent description, not a navigable GPS trace.
/// Options without verified geometry MUST NOT be drawn as routes or exported.
struct MountainAscentGuide: Identifiable, Hashable {
    enum Discipline: String {
        case hiking = "Escursionismo esperto"
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
            summit: "Monte Pisanino",
            title: "Bagola Bianca — cresta nord-ovest",
            discipline: .mountaineering,
            documentedDifficulty: "Passaggi di I grado • esposizione",
            itinerary: "Dal settore Val Serenaia/Rifugio Donegani si raggiunge la costola della Bagola Bianca e si prosegue sulla cresta nord-ovest verso la vetta.",
            caution: "Più tecnica ed esposta della normale; non indicata come discesa improvvisata. Serve capacità di muoversi su terreno alpinistico e valutare le condizioni.",
            sourceName: "AlpiApuane.eu — Accessi al Monte Pisanino",
            sourceURL: URL(string: "https://www.alpiapuane.eu/index.php/apuane-settentrionali/monte-pisanino")!,
            searchTerms: ["pisanino", "bagola bianca", "cresta nord ovest"]
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
        return nil
    }

    private static func normalize(_ text: String) -> String {
        text.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "it_IT")
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
