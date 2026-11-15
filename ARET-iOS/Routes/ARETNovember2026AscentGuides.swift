import Foundation

/// Short, source-linked route descriptions. No geometry is provided.
/// The official source may be a planning document rather than a live
/// trail-condition bulletin. Check closures and conditions separately.
enum ARETNovember2026AscentGuides {
    static let entries: [MountainAscentGuide] = [
        MountainAscentGuide(
            id: "appennino-ventasso-pratizzano",
            region: .appennino,
            summit: "Monte Ventasso",
            title: "Monte Ventasso dal Rifugio Pratizzano",
            discipline: .hiking,
            documentedDifficulty: "E · 4 h · 650 m di dislivello (Ente Parco)",
            itinerary: "Anello pubblicato dall'Ente Parco: Pratizzano, Lago Calamone, Santa Maria Maddalena, vetta del Monte Ventasso e ritorno a Pratizzano. Segnavia 667A, 663, 661 e 667.",
            caution: "Periodo indicato dalla fonte: giugno-ottobre. La descrizione non certifica condizioni, accessibilità o segnaletica attuali e non include una traccia GPS.",
            sourceName: "Parco Nazionale Appennino Tosco-Emiliano — Monte Ventasso",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=107")!,
            searchTerms: ["ventasso", "monte ventasso", "pratizzano", "lago calamone"]
        ),
        MountainAscentGuide(
            id: "appennino-sillano-rio-re",
            region: .appennino,
            summit: "Monte Sillano",
            title: "Monte Sillano da Ligonchio e Rio Re",
            discipline: .hiking,
            documentedDifficulty: "T+ secondo l'Ente Parco · 5 h · 1020 m di dislivello",
            itinerary: "Anello del Parco da Ligonchio di Sopra via Rio Re e sentieri 637, 641 e 633, con deviazione esplicita per la vetta del Monte Sillano. La fonte descrive il ritorno dal settore Il Piano.",
            caution: "La fonte segnala un guado del Rio Re e un tratto ripido, con traccia poco battuta verso la cima. La sigla T+ è quella della fonte, non una valutazione autonoma ARET; i 1020 m di dislivello richiedono allenamento. Periodo indicato: giugno-ottobre. Nessun GPX verificato.",
            sourceName: "Parco Nazionale Appennino Tosco-Emiliano — Rio Re e Monte Sillano",
            sourceURL: URL(string: "https://www.parcoappennino.it/percorso.php?id=79")!,
            searchTerms: ["sillano", "monte sillano", "rio re", "ligonchio"]
        ),
        MountainAscentGuide(
            id: "apuane-corchia-mosceta-approach",
            region: .apuane,
            summit: "Monte Corchia",
            title: "Levigliani – Passo dell'Alpino – Foce di Mosceta",
            discipline: .hiking,
            documentedDifficulty: "Grado non indicato nel documento del Parco",
            itinerary: "Il piano di gestione del Parco documenta il sentiero CAI 9 da Levigliani, presso l'Antro del Corchia, attraverso il Passo dell'Alpino fino alla Foce di Mosceta.",
            caution: "È un percorso di avvicinamento nell'area del Corchia, NON una salita documentata alla vetta. Il piano ambientale non fornisce un bollettino di percorribilità aggiornato, né un GPX completo verificato.",
            sourceName: "Parco Alpi Apuane — Piano gestione Monte Corchia–Le Panie, p. 97",
            sourceURL: URL(string: "https://www.parcapuane.toscana.it/DOCUMENTI/TRASPARENZA/pianificazione_governo_territorio/piani_gestione_natura_2000/monte_corchia_panie_IT5120014/Monte_Corchia_Panie_RELAZIONE.pdf")!,
            searchTerms: ["corchia", "monte corchia", "levigliani", "mosceta", "passo dell'alpino"]
        ),
        MountainAscentGuide(
            id: "apuane-sagro-bore-loop",
            region: .apuane,
            summit: "Monte Sagro",
            title: "Anello Colonna – Bore del Sagro",
            discipline: .hiking,
            documentedDifficulty: "Grado non indicato · circa 10 km e 940 m D+ (Parco)",
            itinerary: "Il piano di gestione del Parco cita un anello da Colonna alle Bore del Sagro, con passaggio da Cima d'Uomo, Foce Luccica e Verghetto e tratti sui sentieri CAI 48 e 38.",
            caution: "Il nome Sagro indica l'area, non una salita certificata alla cima. Il documento di gestione non verifica condizioni attuali né fornisce una geometria GPS pronta per la navigazione.",
            sourceName: "Parco Alpi Apuane — Piano gestione Monte Sagro, p. 89",
            sourceURL: URL(string: "https://www.parcapuane.toscana.it/DOCUMENTI/TRASPARENZA/pianificazione_governo_territorio/piani_gestione_natura_2000/monte_sagro_IT5110006/Monte_Sagro_RELAZIONE_PDG.pdf")!,
            searchTerms: ["sagro", "monte sagro", "bore del sagro", "foce luccica", "verghetto"]
        )
    ]
}
