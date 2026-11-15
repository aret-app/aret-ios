import SwiftUI

struct MountainAscentGuideCard: View {
    let guide: MountainAscentGuide

    private var accent: Color {
        switch guide.discipline {
        case .hiking: return .green
        case .ferrata: return .aretOrange
        case .mountaineering: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: guide.discipline.symbol)
                    .font(.headline)
                    .foregroundStyle(accent)
                    .frame(width: 28, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(guide.summit.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(.secondary)

                    Text(guide.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(guide.discipline.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                }

                Spacer(minLength: 2)
            }

            Label(
                guide.documentedDifficulty,
                systemImage: "mountain.2.fill"
            )
            .font(.subheadline.weight(.semibold))

            Text(guide.itinerary)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(accent)
                Text(guide.caution)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            Divider()
                .overlay(.white.opacity(0.08))

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "map.fill")
                    .foregroundStyle(.secondary)

                Text(guide.navigationNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Link(destination: guide.sourceURL) {
                HStack {
                    Label(
                        "Leggi la fonte · \(guide.sourceName)",
                        systemImage: "doc.text"
                    )
                    .lineLimit(2)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.aretOrange)
            }
        }
        .aretGlassCard(cornerRadius: 22, padding: 15)
    }
}
