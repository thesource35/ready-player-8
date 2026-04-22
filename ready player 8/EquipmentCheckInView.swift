import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

// MARK: - Equipment Check-In View (Phase 21, D-05/D-09)

struct EquipmentCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var equipmentList: [SupabaseEquipment] = []
    @State private var selectedEquipment: SupabaseEquipment?
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var isLoadingEquipment = true
    @State private var submitError: String?
    @StateObject private var locationManager = CheckInLocationManager()

    var onCheckInComplete: ((String) -> Void)?  // callback with equipment name

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Equipment picker
                Section {
                    if isLoadingEquipment {
                        ProgressView("Loading equipment...")
                    } else if equipmentList.isEmpty {
                        Text("No equipment found. Create equipment in the fleet manager.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.muted)
                    } else {
                        Picker("Equipment", selection: $selectedEquipment) {
                            Text("Select equipment").tag(nil as SupabaseEquipment?)
                            ForEach(equipmentList) { eq in
                                HStack {
                                    Image(systemName: eq.sfSymbolName)
                                        .foregroundColor(eq.statusColor)
                                    Text(eq.name)
                                }
                                .tag(eq as SupabaseEquipment?)
                            }
                        }
                    }
                } header: {
                    Text("EQUIPMENT")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                }

                // MARK: GPS location
                Section {
                    if let location = locationManager.location {
                        HStack {
                            Text("Latitude")
                                .foregroundColor(Theme.muted)
                            Spacer()
                            Text(String(format: "%.6f", location.latitude))
                                .font(.system(size: 12, weight: .bold))
                        }
                        HStack {
                            Text("Longitude")
                                .foregroundColor(Theme.muted)
                            Spacer()
                            Text(String(format: "%.6f", location.longitude))
                                .font(.system(size: 12, weight: .bold))
                        }
                        HStack {
                            Text("Accuracy")
                                .foregroundColor(Theme.muted)
                            Spacer()
                            Text(String(format: "%.0f m", locationManager.accuracy))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(
                                    locationManager.accuracy < 10
                                        ? Theme.green
                                        : locationManager.accuracy < 30
                                            ? Theme.gold
                                            : Theme.red
                                )
                        }
                    } else if let error = locationManager.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.red)
                            Button("Retry") {
                                locationManager.requestLocation()
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.cyan)
                        }
                    } else {
                        HStack {
                            ProgressView()
                            Text("Acquiring GPS signal...")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.muted)
                        }
                    }
                } header: {
                    Text("LOCATION")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                }

                // MARK: Notes
                Section {
                    TextField("Optional notes", text: $notes)
                        .font(.system(size: 12))
                } header: {
                    Text("NOTES")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                }

                // MARK: Submit error
                if let submitError {
                    Section {
                        Text(submitError)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.red)
                    }
                }
            }
            .navigationTitle("Check In Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Location") {
                        Task { await submitCheckIn() }
                    }
                    .disabled(selectedEquipment == nil || locationManager.location == nil || isSubmitting)
                    .font(.system(size: 14, weight: .bold))
                }
            }
            .task {
                await loadEquipment()
                locationManager.requestLocation()
            }
        }
    }

    private func loadEquipment() async {
        isLoadingEquipment = true
        do {
            equipmentList = try await SupabaseService.shared.fetchEquipment()
        } catch {
            CrashReporter.shared.reportError("Equipment list load failed: \(error.localizedDescription)")
            equipmentList = mockEquipment
        }
        isLoadingEquipment = false
    }

    private func submitCheckIn() async {
        guard let equipment = selectedEquipment,
              let location = locationManager.location else { return }

        isSubmitting = true
        submitError = nil

        let request = EquipmentCheckInRequest(
            equipmentId: equipment.id,
            lat: location.latitude,
            lng: location.longitude,
            accuracyM: locationManager.accuracy > 0 ? locationManager.accuracy : nil,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await SupabaseService.shared.checkInEquipmentLocation(request)
            onCheckInComplete?(equipment.name)
            dismiss()
        } catch let appError as AppError {
            // Surface AppError.errorDescription so the user sees a project-convention-styled message
            submitError = appError.errorDescription ?? "Check-in failed. Please try again."
            CrashReporter.shared.reportError("Equipment check-in failed: \(appError.errorDescription ?? "")")
        } catch {
            // Wrap into AppError.unknown so the UI message is user-facing, not a raw SDK string
            let wrapped = AppError.unknown(error.localizedDescription)
            submitError = wrapped.errorDescription ?? "Check-in failed. Please try again."
            CrashReporter.shared.reportError("Equipment check-in failed: \(error.localizedDescription)")
        }

        isSubmitting = false
    }
}

// MARK: - Location Manager for Check-In

final class CheckInLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var accuracy: CLLocationAccuracy = 0
    @Published var errorMessage: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        errorMessage = nil
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "GPS signal unavailable. Move to an open area and try again."
        default:
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied {
            errorMessage = "GPS signal unavailable. Move to an open area and try again."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            location = loc.coordinate
            accuracy = loc.horizontalAccuracy
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "GPS signal unavailable. Move to an open area and try again."
        CrashReporter.shared.reportError("CLLocationManager failed: \(error.localizedDescription)")
    }
}
