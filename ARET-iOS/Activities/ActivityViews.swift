import SwiftUI

struct ActivityStatsGrid: View {
    let activity: RecordedActivity

    var body: some View {
        let stats = activity.stats

        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                stat(
                    title: "Distanza",
                    value: String(format: "%.2f km", stats.distanceMeters / 1000)
                )
                stat(
                    title: "Durata",
                    value: formatDuration(stats.durationSeconds)
                )
            }

            GridRow {
                stat(
                    title: "Tempo in movimento",
                    value: formatDuration(stats.movingTimeSeconds)
                )
                stat(
                    title: "Punti GPS",
                    value: "\(stats.pointCount)"
                )
            }

            GridRow {
                stat(
                    title: "D+",
                    value: "\(Int(stats.ascentMeters.rounded())) m"
                )
                stat(
                    title: "D-",
                    value: "\(Int(stats.descentMeters.rounded())) m"
                )
            }

            GridRow {
                stat(
                    title: "Quota min",
                    value: "\(Int(stats.minimumAltitudeMeters.rounded())) m"
                )
                stat(
                    title: "Quota max",
                    value: "\(Int(stats.maximumAltitudeMeters.rounded())) m"
                )
            }

            GridRow {
                stat(
                    title: "Velocità media",
                    value: String(
                        format: "%.1f km/h",
                        stats.averageMovingSpeedMPS * 3.6
                    )
                )
                stat(
                    title: "Velocità max",
                    value: String(
                        format: "%.1f km/h",
                        stats.maximumSpeedMPS * 3.6
                    )
                )
            }
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%d:%02d", minutes, secs)
    }
}

struct ActivitySummaryView: View {
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var routeLibrary: RouteLibraryStore
    @Environment(\.dismiss) private var dismiss

    let activity: RecordedActivity

    @State private var savedAsRoute = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Attività salvata")
                            .font(.title2.bold())
                        Text(activity.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }

                    ActivityStatsGrid(activity: activity)

                    if savedAsRoute {
                        Label(
                            "Salvata anche nei Percorsi",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)
                    }

                    VStack(spacing: 10) {
                        Button {
                            if routeLibrary.saveActivityAsRoute(activity) != nil {
                                savedAsRoute = true
                            }
                        } label: {
                            Label(
                                "Salva come percorso da rifare",
                                systemImage: "repeat"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(savedAsRoute)

                        if let gpxURL = activityStore.gpxURL(for: activity) {
                            ShareLink(item: gpxURL) {
                                Label("Condividi GPX", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        Button("Solo attività · Fine") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Riepilogo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ActivitiesView: View {
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    let onOpenRoute: (RouteLibraryItem) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if activityStore.activities.isEmpty {
                    ContentUnavailableView(
                        "Nessuna attività",
                        systemImage: "figure.hiking",
                        description: Text(
                            "Le attività registrate da ARET rimarranno qui."
                        )
                    )
                } else {
                    List {
                        ForEach(activityStore.activities) { activity in
                            NavigationLink {
                                ActivityDetailView(
                                    activity: activity,
                                    onOpenRoute: onOpenRoute
                                )
                            } label: {
                                ActivityRow(activity: activity)
                            }
                        }
                        .onDelete(perform: activityStore.delete)
                    }
                }
            }
            .navigationTitle("Attività")
        }
    }
}

private struct ActivityRow: View {
    let activity: RecordedActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(activity.name)
                .font(.headline)

            Text(activity.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label(
                    String(format: "%.1f km", activity.stats.distanceMeters / 1000),
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                )
                Label(
                    "+\(Int(activity.stats.ascentMeters.rounded())) m",
                    systemImage: "arrow.up.right"
                )
                Label(
                    shortDuration(activity.stats.durationSeconds),
                    systemImage: "clock"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func shortDuration(_ seconds: Double) -> String {
        let totalMinutes = max(0, Int(seconds / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }
}

private struct ActivityDetailView: View {
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    let activity: RecordedActivity
    let onOpenRoute: (RouteLibraryItem) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.title2.bold())
                    Text(activity.startedAt.formatted(date: .complete, time: .shortened))
                        .foregroundStyle(.secondary)
                }

                ActivityStatsGrid(activity: activity)

                Button {
                    guard let route = routeLibrary.saveActivityAsRoute(activity) else {
                        return
                    }
                    routeLibrary.select(route)
                    onOpenRoute(route)
                } label: {
                    Label("Usa come percorso", systemImage: "repeat")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                if let gpxURL = activityStore.gpxURL(for: activity) {
                    ShareLink(item: gpxURL) {
                        Label("Condividi GPX", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Dettaglio attività")
        .navigationBarTitleDisplayMode(.inline)
    }
}
