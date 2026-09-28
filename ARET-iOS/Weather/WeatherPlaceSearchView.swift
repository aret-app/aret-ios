import SwiftUI
import MapKit

struct WeatherPlaceSelection {
    let name: String
    let latitude: Double
    let longitude: Double
}

struct WeatherPlaceSearchView: View {
    @Environment(\.dismiss) private var dismiss

    let onSelect: (WeatherPlaceSelection) -> Void

    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField(
                            "Es. Pania della Croce, Courmayeur…",
                            text: $query
                        )
                        .textInputAutocapitalization(.words)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await search()
                            }
                        }

                        if isLoading {
                            ProgressView()
                        }
                    }

                    Button {
                        Task {
                            await search()
                        }
                    } label: {
                        Label(
                            "Cerca località",
                            systemImage: "magnifyingglass"
                        )
                    }
                    .disabled(
                        query.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || isLoading
                    )
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                    }
                }

                if !results.isEmpty {
                    Section("Risultati") {
                        ForEach(
                            Array(results.enumerated()),
                            id: \.offset
                        ) { _, item in
                            Button {
                                let coordinate =
                                    item.placemark.coordinate

                                onSelect(
                                    WeatherPlaceSelection(
                                        name:
                                            item.name ??
                                            item.placemark.title ??
                                            query,
                                        latitude:
                                            coordinate.latitude,
                                        longitude:
                                            coordinate.longitude
                                    )
                                )
                                dismiss()
                            } label: {
                                VStack(
                                    alignment: .leading,
                                    spacing: 3
                                ) {
                                    Text(
                                        item.name ??
                                        item.placemark.title ??
                                        "Località"
                                    )
                                    .foregroundStyle(.primary)

                                    if let title =
                                        item.placemark.title,
                                       title != item.name {
                                        Text(title)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .aretScreenBackground()
            .navigationTitle("Località meteo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .principal
                ) {
                    ARETMark(size: 24)
                }

                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }

    @MainActor
    private func search() async {
        let trimmed = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            request.resultTypes = [
                .address,
                .pointOfInterest
            ]

            let response = try await MKLocalSearch(
                request: request
            ).start()

            results = Array(
                response.mapItems.prefix(12)
            )

            if results.isEmpty {
                errorMessage =
                    "Nessuna località trovata."
            }
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
