import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI
import UIKit  // Phase 21-10 Task 2: UIApplication.openSettingsURLString (Test 12)

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
                    } else if locationManager.permissionDenied {
                        // Phase 21-10 Task 2: permission denial branch (Test 12).
                        // Retry is a dead end on denial (iOS will not re-prompt) — route users
                        // to the app's Settings pane so they can flip the permission themselves.
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enable location in Settings to check in equipment.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.red)
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.cyan)
                        }
                    } else if let error = locationManager.runtimeError {
                        // Phase 21-10 Task 2: runtime-failure branch keeps Retry (Test 12).
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error.errorDescription ?? "GPS signal unavailable. Move to an open area and try again.")
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
            // 999.5 (d) Tier 2: only substitute mocks when Supabase is unconfigured
            // (dev/demo experience). Configured + fetch failure should NOT show fake
            // equipment as if it were real — leave list empty so the picker is empty
            // and the user knows something is off.
            if SupabaseService.shared.isConfigured {
                equipmentList = []
            } else {
                equipmentList = mockEquipment
            }
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
    // Phase 21-10 Task 2: split error state into two distinct signals (Test 12).
    // Before: single errorMessage conflated denial (.denied/.restricted) with runtime
    // failure (didFailWithError) behind identical "GPS signal unavailable" copy + a Retry
    // button that was a dead end on denial. After: the view branches on permissionDenied
    // to render the Settings deep-link CTA; runtimeError keeps the Retry flow.
    @Published var permissionDenied: Bool = false
    @Published var runtimeError: AppError?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        permissionDenied = false
        runtimeError = nil
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            permissionDenied = true
            // Log via CrashReporter with FieldLocationCapture-style AppError for analytics parity.
            CrashReporter.shared.reportError(
                AppError.permissionDenied(feature: "Location").errorDescription ?? "Location permission denied"
            )
        default:
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionDenied = false
            manager.requestLocation()
        case .denied, .restricted:
            permissionDenied = true
            CrashReporter.shared.reportError(
                AppError.permissionDenied(feature: "Location").errorDescription ?? "Location permission denied"
            )
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            location = loc.coordinate
            accuracy = loc.horizontalAccuracy
            runtimeError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Runtime failure (signal loss, hardware) — distinct from permission denial.
        runtimeError = AppError.unknown("GPS signal unavailable. Move to an open area and try again.")
        CrashReporter.shared.reportError("CLLocationManager failed: \(error.localizedDescription)")
    }
}
