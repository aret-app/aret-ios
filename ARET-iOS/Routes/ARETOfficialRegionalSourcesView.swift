import SwiftUI

/// External primary references offered independently of the experimental
/// OpenStreetMap graph. Linking is not a licence to copy third-party GPX.
struct ARETOfficialRegionalSourcesView: View {
    let scope: ARETDiscoveryScope

    private struct Source: Identifiable {
        let id: String
        let region: ARETPilotRegion
        let title: String
        let detail: String
        let link: URL
        let warning: String?
    }

    private let sources: [Source] = [
        Source(
            id: "cai-apuane-sentieri-2025",
            region: .apuane,
            title: "Sentieri CAI Toscana — elenco 2025",
            detail: "Registro CAI con riferimenti ai sentieri numerati e alle ferrate, inclusi Procinto 115A e Monte Forato 110A.",
            link: URL(
                string: "https://organizzazione.cai.it/gr-toscana/wp-content/uploads/sites/66/2025/10/Sentieri-CAI-ufficiale-21-10-2025.pdf"
            )!,
            warning: "Il PDF elenca percorsi e gradi, ma non è una traccia GPS e non sostituisce gli aggiornamenti sulle chiusure."
        ),
        Source(
            id: "parco-appennino-paths",
            region: .appennino,
            title: "Rete sentieristica del Parco",
            detail: "Elenco ufficiale dei sentieri numerati, estremi, difficoltà e aggiornamenti segnalati dall'Ente Parco.",
            link: URL(
                string: "https://www.parcoappennino.it/rete_sentieristica.php"
            )!,
            warning: "Verifica sempre la data dell'ultimo aggiornamento e le chiusure."
        ),
        Source(
            id: "parco-appennino-hikes",
            region: .appennino,
            title: "Escursioni proposte dal Parco",
            detail: "Indice delle escursioni con difficoltà e tempi dichiarati dalla fonte, distinto dalla rete di tutti i sentieri.",
            link: URL(
                string: "https://www.parcoappennino.it/percorsi.piedi.php"
            )!,
            warning: "La proposta di un itinerario non ne certifica la percorribilità attuale."
        ),
        Source(
            id: "apuane-guide",
            region: .apuane,
            title: "Itinerari del Parco delle Apuane",
            detail: "Documento del Parco che descrive la rete e gli itinerari classici delle Alpi Apuane.",
            link: URL(
                string: "https://parcapuane.toscana.it/turismo/apuan_alps_cets_strategy_action_plan_2023_3.pdf"
            )!,
            warning: "Documento di pianificazione, non un bollettino aggiornato della percorribilità."
        ),
        Source(
            id: "apuane-ferrata",
            region: .apuane,
            title: "Ferrate e alpinismo nelle Apuane",
            detail: "Schede storiche divulgative del Parco, utili per identificare nomi delle vie tecniche.",
            link: URL(
                string: "https://parcapuane.toscana.it/turismo/itinerari_sez_ing.asp?id=23"
            )!,
            warning: "Informazioni potenzialmente datate: controlla lo stato attuale dei percorsi attrezzati con CAI/gestori."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.aretOrange)

                Text("FONTI PRIMARIE DEL TERRITORIO")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
            }

            Text(
                "Se ARET non trova un GPX completo, consulta anche gli elenchi dei gestori. Le fonti ufficiali possono contenere più sentieri di quelli già mappati su OSM."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            ForEach(sources.filter {
                scope.regions.contains($0.region)
            }) { source in
                VStack(alignment: .leading, spacing: 5) {
                    Link(destination: source.link) {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundStyle(.aretOrange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.title)
                                    .font(.subheadline.weight(.semibold))

                                Text(source.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.aretOrange)
                        }
                    }
                    .buttonStyle(.plain)

                    if let warning = source.warning {
                        Text(warning)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(12)
                .background(
                    Color.white.opacity(0.045),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
        }
        .aretGlassCard(cornerRadius: 23, padding: 15)
    }
}
