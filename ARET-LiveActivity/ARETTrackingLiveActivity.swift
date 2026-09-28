import SwiftUI
import WidgetKit
import ActivityKit

struct ARETTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(
            for: ARETTrackingAttributes.self
        ) { context in
            lockScreenView(context)
                .activityBackgroundTint(
                    Color.black.opacity(0.92)
                )
                .activitySystemActionForegroundColor(
                    .white
                )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(
                    .leading
                ) {
                    HStack(spacing: 5) {
                        ARETMark(size: 22)
                        Text("ARET")
                            .font(.headline)
                    }
                }

                DynamicIslandExpandedRegion(
                    .trailing
                ) {
                    Text(
                        context.state.distanceMeters / 1000,
                        format:
                            .number.precision(
                                .fractionLength(2)
                            )
                    )
                    .font(.headline.monospacedDigit())
                    +
                    Text(" km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(
                    .center
                ) {
                    Text(
                        timerInterval:
                            context.attributes.startedAt...
                                Date.distantFuture,
                        countsDown: false
                    )
                    .font(
                        .title3
                        .weight(.semibold)
                        .monospacedDigit()
                    )
                }

                DynamicIslandExpandedRegion(
                    .bottom
                ) {
                    HStack(spacing: 18) {
                        liveMetric(
                            title: "D+",
                            value:
                                "\(Int(context.state.ascentMeters.rounded())) m"
                        )

                        liveMetric(
                            title: "Quota",
                            value:
                                context.state.altitudeMeters.map {
                                    "\(Int($0.rounded())) m"
                                } ?? "—"
                        )

                        liveMetric(
                            title: "Stato",
                            value:
                                context.state.isTracking
                                ? "REC"
                                : "Fine"
                        )
                    }
                }
            } compactLeading: {
                ARETMark(size: 19)
            } compactTrailing: {
                Text(
                    context.state.distanceMeters / 1000,
                    format:
                        .number.precision(
                            .fractionLength(1)
                        )
                )
                .font(.caption.monospacedDigit())
            } minimal: {
                ARETMark(size: 18)
            }
            .keylineTint(.aretOrange)
        }
    }

    private func lockScreenView(
        _ context:
            ActivityViewContext<
                ARETTrackingAttributes
            >
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack {
                HStack(spacing: 7) {
                    ARETMark(size: 24)

                    Text("ARET")
                        .font(.headline.bold())
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(
                            context.state.isTracking
                            ? Color.orange
                            : Color.secondary
                        )
                        .frame(width: 7, height: 7)

                    Text(
                        context.state.isTracking
                        ? "REGISTRAZIONE"
                        : "TERMINATA"
                    )
                    .font(
                        .caption2
                        .weight(.bold)
                    )
                }
            }

            Text(context.attributes.activityName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            HStack(
                alignment: .firstTextBaseline,
                spacing: 18
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(
                        timerInterval:
                            context.attributes.startedAt...
                                Date.distantFuture,
                        countsDown: false
                    )
                    .font(
                        .title2
                        .weight(.semibold)
                        .monospacedDigit()
                    )

                    Text("Durata")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                liveMetric(
                    title: "Distanza",
                    value: String(
                        format: "%.2f km",
                        context.state.distanceMeters / 1000
                    )
                )

                liveMetric(
                    title: "D+",
                    value:
                        "\(Int(context.state.ascentMeters.rounded())) m"
                )

                liveMetric(
                    title: "Quota",
                    value:
                        context.state.altitudeMeters.map {
                            "\(Int($0.rounded())) m"
                        } ?? "—"
                )
            }
        }
        .padding(16)
        .foregroundStyle(.white)
    }

    private func liveMetric(
        title: String,
        value: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            Text(value)
                .font(
                    .subheadline
                    .weight(.semibold)
                )
                .monospacedDigit()

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

@main
struct ARETLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        ARETTrackingLiveActivity()
    }
}
