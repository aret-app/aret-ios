import SwiftUI
import CoreLocation
import UIKit

struct PrivacyView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    @State private var showEraseConfirmation = false
    @State private var showEraseCompleted = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    privacyRow(
                        icon: "iphone.gen3",
                        title: "GPS e attività",
                        detail: "Restano nel sandbox privato di ARET su questo iPhone."
                    )

                    privacyRow(
                        icon: "lock.shield.fill",
                        title: "Protezione file",
                        detail: "GPX, attività e percorsi personali usano la protezione completa dei file iOS."
                    )

                    privacyRow(
                        icon: "icloud.slash.fill",
                        title: "Backup",
                        detail: "I dati GPS ARET sono esclusi dai backup cloud/dispositivo per impostazione predefinita."
                    )
                } header: {
                    Text("Sul dispositivo")
                } footer: {
                    Text(
                        "Developer Mode non disattiva il sandbox di ARET né i permessi iOS."
                    )
                }

                Section {
                    privacyRow(
                        icon: "cloud.sun.fill",
                        title: "Meteo",
                        detail: "ARET invia a Open-Meteo via HTTPS solo il punto necessario alla previsione. Non invia la traccia GPX completa. Open-Meteo dichiara che i log tecnici possono includere coordinate e vengono eliminati entro 90 giorni."
                    )

                    privacyRow(
                        icon: "map.fill",
                        title: "Mappe e ricerca località",
                        detail: "La cartografia e la ricerca delle località usano MapKit e i servizi Apple Maps."
                    )

                    privacyRow(
                        icon: "figure.hiking",
                        title: "Percorsi online",
                        detail: "Quando avvii esplicitamente una ricerca online, ARET interroga OpenStreetMap/Overpass per i percorsi hiking aperti nella zona cercata. Non invia la tua cronologia attività."
                    )

                    privacyRow(
                        icon: "mountain.2.fill",
                        title: "Profilo altimetrico DEM",
                        detail: "Quando apri un percorso online OSM, ARET invia a Open-Meteo un campionamento delle coordinate pubbliche di quel percorso per ottenere le quote Copernicus DEM. Le tue attività registrate e i GPX personali non vengono inviati automaticamente al servizio DEM."
                    )

                    privacyRow(
                        icon: "heart.fill",
                        title: "Apple Health",
                        detail: "Workout, battito e distanza del Watch passano tramite HealthKit. ARET non li carica su un proprio server."
                    )
                } header: {
                    Text("Servizi esterni")
                }

                Section {
                    HStack {
                        Label(
                            "Posizione",
                            systemImage: "location.fill"
                        )

                        Spacer()

                        Text(locationPermissionText)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        openSystemSettings()
                    } label: {
                        Label(
                            "Apri impostazioni ARET",
                            systemImage: "gear"
                        )
                    }
                } header: {
                    Text("Permessi")
                }

                Section {
                    privacyRow(
                        icon: "server.rack",
                        title: "Backend ARET",
                        detail: "Questa beta non ha account né un backend ARET che riceva le tue attività."
                    )

                    privacyRow(
                        icon: "square.and.arrow.up",
                        title: "Condivisione GPX",
                        detail: "Un GPX esce dall'app solo quando scegli esplicitamente di condividerlo."
                    )
                } header: {
                    Text("Trasparenza")
                }

                Section {
                    Button(role: .destructive) {
                        showEraseConfirmation = true
                    } label: {
                        Label(
                            "Elimina tutti i dati locali ARET",
                            systemImage: "trash.fill"
                        )
                    }
                } footer: {
                    Text(
                        "Cancella attività, GPX e percorsi personali dal container ARET. Eventuali workout già salvati in Apple Health restano in Health e vanno gestiti separatamente."
                    )
                }
            }
            .navigationTitle("Profilo")
        }
        .confirmationDialog(
            "Eliminare tutti i dati locali ARET?",
            isPresented: $showEraseConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Elimina definitivamente",
                role: .destructive
            ) {
                activityStore.deleteAll()
                routeLibrary.deleteAllPersonalRoutes()
                showEraseCompleted = true
            }

            Button("Annulla", role: .cancel) {}
        } message: {
            Text(
                "Questa operazione cancella attività, GPX e percorsi personali salvati da ARET su questo iPhone."
            )
        }
        .alert(
            "Dati ARET eliminati",
            isPresented: $showEraseCompleted
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Le copie locali di attività, GPX e percorsi personali sono state eliminate."
            )
        }
    }

    private var locationPermissionText: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            return "Sempre"
        case .authorizedWhenInUse:
            return "Durante l'uso"
        case .denied:
            return "Negata"
        case .restricted:
            return "Limitata"
        case .notDetermined:
            return "Non richiesta"
        @unknown default:
            return "Sconosciuta"
        }
    }

    private func privacyRow(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func openSystemSettings() {
        guard
            let url = URL(
                string: UIApplication.openSettingsURLString
            )
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}
