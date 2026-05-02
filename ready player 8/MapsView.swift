import Foundation
import MapKit
import SwiftUI

// MARK: - ========== MapsView.swift ==========

// MARK: - Map Photo Annotation (D-17, MAP-04)

struct MapPhotoAnnotation: Identifiable {
    let id: String
    let filename: String
    let coordinate: CLLocationCoordinate2D
    let createdAt: String
}

// MARK: - Mock Photo Annotations (Phase 21-09 Task 3, D-14 fallback symmetric with mockEquipmentPositions)
// Cluster near MapSite.mapCenter (40.7580, -73.9855, NYC-Midtown). Used by MapsView.loadMapData()
// when cs_documents returns empty AND Supabase is unconfigured — configured-and-empty cases fall
// through to the "0 PHOTOS WITH GPS" empty-state chip instead.
//
// 999.5 (d) Tier 3: bundle-gated. Release ships empty array.
#if DEBUG
let mockPhotoAnnotations: [MapPhotoAnnotation] = [
    MapPhotoAnnotation(
        id: "photo-mock-001",
        filename: "IMG_0421.HEIC",
        coordinate: CLLocationCoordinate2D(latitude: 40.7583, longitude: -73.9858),
        createdAt: "2026-04-20T14:30:00Z"
    ),
    MapPhotoAnnotation(
        id: "photo-mock-002",
        filename: "site_overview.jpg",
        coordinate: CLLocationCoordinate2D(latitude: 40.7595, longitude: -73.9843),
        createdAt: "2026-04-19T11:00:00Z"
    ),
    MapPhotoAnnotation(
        id: "photo-mock-003",
        filename: "crew_lunch_break.jpg",
        coordinate: CLLocationCoordinate2D(latitude: 40.7570, longitude: -73.9868),
        createdAt: "2026-04-18T12:45:00Z"
    ),
]
#else
let mockPhotoAnnotations: [MapPhotoAnnotation] = []
#endif

// MARK: - GPS Document DTO (for photo annotation fetch)

private struct SupabaseGpsDocument: Codable {
    let id: String
    let filename: String
    let gpsLat: Double
    let gpsLng: Double
    let createdAt: String
}

// MARK: - Maps View

struct MapsView: View {
    private let mapSites = previewMapSites
    private let mapRoutes = previewMapRoutes

    private let satellitePasses: [SatellitePass] = [
        SatellitePass(name: "SAT-A1", eta: "04 min", coverage: "North yard", confidence: 97, color: Theme.cyan),
        SatellitePass(name: "SAT-C4", eta: "19 min", coverage: "Concrete deck", confidence: 91, color: Theme.gold),
        SatellitePass(name: "THERM-2", eta: "42 min", coverage: "Roof membrane", confidence: 88, color: Theme.green)
    ]

    @State private var selectedSiteID: UUID?
    @State private var satelliteMode = true
    @State private var thermalOverlay = true
    @State private var crewOverlay = true
    @State private var weatherOverlay = false
    @State private var autoTrack = true
    @State private var trafficOverlay = false
    @State private var photosOverlay = false
    @State private var equipmentPositions: [SupabaseEquipmentLatestPosition] = []
    @State private var photoAnnotations: [MapPhotoAnnotation] = []
    @State private var equipmentFilter: String = "All"
    @State private var isLoadingData = true
    @State private var feedLatencyMS = 780
    @State private var activeSweep = 1
    @State private var cameraPreset: MapCameraPreset = .selected
    // D-05/D-09: Check-in sheet state
    @State private var showCheckInSheet = false
    @State private var checkInSuccessMessage: String?
    // Phase 21-09: visible error surfacing from loadMapData() (Test 11 — no silent throw-swallow)
    @State private var loadError: AppError?
    // D-16: Delivery route road-following state
    @State private var computedRoutes: [UUID: MKRoute] = [:]
    @State private var computingRoute: UUID?
    @State private var routeError: UUID?

    // D-11: Overlay persistence
    @AppStorage("ConstructOS.Maps.OverlaySatellite") private var savedSatellite = true
    @AppStorage("ConstructOS.Maps.OverlayTraffic") private var savedTraffic = false
    @AppStorage("ConstructOS.Maps.OverlayThermal") private var savedThermal = true
    @AppStorage("ConstructOS.Maps.OverlayCrew") private var savedCrew = true
    @AppStorage("ConstructOS.Maps.OverlayWeather") private var savedWeather = false
    @AppStorage("ConstructOS.Maps.OverlayPhotos") private var savedPhotos = false
    // Phase 21-10 Task 1: AUTO TRACK persistence (Test 10 defect 1 — was @State-only, lost on relaunch)
    @AppStorage("ConstructOS.Maps.OverlayAutoTrack") private var savedAutoTrack = true

    private var selectedSite: MapSite {
        mapSites.first { $0.id == selectedSiteID } ?? mapSites[1]
    }

    private var filteredEquipment: [SupabaseEquipmentLatestPosition] {
        switch equipmentFilter {
        case "Equipment": return equipmentPositions.filter { $0.type == "equipment" }
        case "Vehicles": return equipmentPositions.filter { $0.type == "vehicle" }
        case "Materials": return equipmentPositions.filter { $0.type == "material" }
        default: return equipmentPositions
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LIVE MAPS")
                            .font(.system(size: 12, weight: .black))
                            .tracking(2)
                            .foregroundColor(Theme.cyan)
                        Text("Satellite-backed site awareness with live overlays and rapid field routing.")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(satelliteMode ? "SAT LINKED" : "GRID MODE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(satelliteMode ? Theme.gold : Theme.surface)
                        .cornerRadius(6)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Toggle("SATELLITE", isOn: $satelliteMode)
                            .toggleStyle(.button)
                        Toggle("TRAFFIC", isOn: $trafficOverlay)
                            .toggleStyle(.button)
                        Toggle("PHOTOS", isOn: $photosOverlay)
                            .toggleStyle(.button)
                        Toggle("CREWS", isOn: $crewOverlay)
                            .toggleStyle(.button)
                        Toggle("THERMAL", isOn: $thermalOverlay)
                            .toggleStyle(.button)
                        Toggle("WEATHER", isOn: $weatherOverlay)
                            .toggleStyle(.button)
                        Toggle("AUTO TRACK", isOn: $autoTrack)
                            .toggleStyle(.button)
                    }
                    .padding(.horizontal, 2)
                }
                .font(.system(size: 9, weight: .bold))

                HStack(spacing: 8) {
                    ForEach(MapCameraPreset.allCases) { preset in
                        Button(preset.rawValue) {
                            cameraPreset = preset
                        }
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(cameraPreset == preset ? .black : Theme.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(cameraPreset == preset ? Theme.gold : Theme.surface)
                        .cornerRadius(6)
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    mapMetricCard(title: "ACTIVE SITES", value: "\(mapSites.count)", detail: "4 live overlays", color: Theme.cyan)
                    mapMetricCard(title: "EQUIPMENT", value: "\(equipmentPositions.count)", detail: "\(equipmentPositions.filter { $0.status == "active" }.count) active", color: Theme.green)
                    mapMetricCard(title: "NEXT PASS", value: satellitePasses[0].eta, detail: satellitePasses[0].name, color: Theme.gold)
                    mapMetricCard(title: "SELECTED", value: selectedSite.name, detail: selectedSite.type, color: Theme.accent)
                }

                // Phase 21-09 Task 3: empty-state chip when PHOTOS overlay on + array empty (Test 9)
                if photosOverlay && photoAnnotations.isEmpty && !isLoadingData {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(Theme.muted)
                        Text("0 PHOTOS WITH GPS")
                            .font(.system(size: 9, weight: .black))
                            .tracking(1)
                            .foregroundColor(Theme.muted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.surface.opacity(0.85))
                    .cornerRadius(6)
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        LiveMapView(
                            sites: mapSites,
                            routes: mapRoutes,
                            selectedSiteID: $selectedSiteID,
                            satelliteMode: satelliteMode,
                            trafficOverlay: trafficOverlay,
                            thermalOverlay: thermalOverlay,
                            crewOverlay: crewOverlay,
                            weatherOverlay: weatherOverlay,
                            photosOverlay: photosOverlay,
                            equipmentPositions: filteredEquipment,
                            photoAnnotations: photosOverlay ? photoAnnotations : [],
                            computedRoutes: computedRoutes,
                            activeSweep: activeSweep,
                            cameraPreset: cameraPreset
                        )
                        .frame(minHeight: 340)

                        HStack(spacing: 8) {
                            Button("PING SAT SWEEP") { activeSweep += 1; feedLatencyMS = max(420, feedLatencyMS - 35) }
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Theme.gold)
                                .cornerRadius(6)

                            Button("CHECK IN EQUIPMENT") {
                                showCheckInSheet = true
                            }
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Theme.accent)
                            .cornerRadius(6)

                            Button("CENTER \(selectedSite.name.uppercased())") { selectedSiteID = selectedSite.id }
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.cyan)

                            Spacer()

                            Text("Sweep #\(activeSweep) · \(autoTrack ? "auto-tracking" : "manual pan")")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(Theme.muted)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SITE LOCK")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1)
                                .foregroundColor(Theme.gold)

                            Text(selectedSite.name)
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(Theme.text)
                            Text("\(selectedSite.type) · \(selectedSite.status)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Theme.muted)

                            VStack(alignment: .leading, spacing: 6) {
                                statusRow(label: "Visibility", value: satelliteMode ? "Satellite locked" : "Grid-only", color: satelliteMode ? Theme.green : Theme.muted)
                                statusRow(label: "Crew overlay", value: crewOverlay ? "Hot" : "Muted", color: crewOverlay ? Theme.cyan : Theme.muted)
                                statusRow(label: "Thermal", value: thermalOverlay ? "Heat signatures active" : "Offline", color: thermalOverlay ? Theme.red : Theme.muted)
                                statusRow(label: "Weather", value: weatherOverlay ? "Wind alerts live" : "Standby", color: weatherOverlay ? Theme.purple : Theme.muted)
                                statusRow(label: "Coordinates", value: selectedSite.coordinateLabel, color: Theme.text)
                                statusRow(label: "Feed latency", value: "\(selectedSite.latencyMS) ms", color: Theme.green)
                                statusRow(label: "Crew ETA", value: selectedSite.crewETA, color: Theme.cyan)
                                statusRow(label: "Alert level", value: selectedSite.alertLevel, color: selectedSite.alertLevel == "WATCH" ? Theme.red : Theme.gold)
                            }
                        }
                        .padding(12)
                        .background(Theme.surface.opacity(0.78))
                        .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("SAT PASSES")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1)
                                .foregroundColor(Theme.cyan)

                            ForEach(satellitePasses) { pass in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(pass.color)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(pass.name) · ETA \(pass.eta)")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(pass.color)
                                        Text("\(pass.coverage) · \(pass.confidence)% confidence")
                                            .font(.system(size: 8, weight: .semibold))
                                            .foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(8)
                                .background(Theme.surface.opacity(0.72))
                                .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        .background(Theme.surface.opacity(0.78))
                        .cornerRadius(10)

                        // MARK: Equipment Sidebar (D-08, MAP-03)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EQUIPMENT")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1)
                                .foregroundColor(Theme.green)

                            HStack(spacing: 6) {
                                ForEach(["All", "Equipment", "Vehicles", "Materials"], id: \.self) { filter in
                                    Button(filter.uppercased()) { equipmentFilter = filter }
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundColor(equipmentFilter == filter ? .black : Theme.muted)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(equipmentFilter == filter ? Theme.accent : Theme.surface)
                                    .cornerRadius(4)
                                    .buttonStyle(.plain)
                                }
                            }

                            if filteredEquipment.isEmpty && !isLoadingData {
                                VStack(spacing: 6) {
                                    Text("No Equipment Tracked")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Theme.text)
                                    Text("Check in your first piece of equipment to see it on the map. Tap Check In Equipment to get started.")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(Theme.muted)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(12)
                            } else {
                                ForEach(filteredEquipment) { eq in
                                    HStack(spacing: 8) {
                                        Image(systemName: eq.sfSymbolName)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                            .background(eq.statusColor)
                                            .clipShape(Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(eq.name)
                                                .font(.system(size: 9, weight: .black))
                                                .foregroundColor(Theme.text)
                                            Text("\(eq.type.capitalized) \u{00B7} \(eq.status.replacingOccurrences(of: "_", with: " ").capitalized)")
                                                .font(.system(size: 7, weight: .semibold))
                                                .foregroundColor(Theme.muted)
                                        }
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(Theme.surface.opacity(0.72))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(12)
                        .background(Theme.surface.opacity(0.78))
                        .cornerRadius(10)

                        // MARK: Delivery Routes Sidebar (D-16, MAP)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DELIVERY ROUTES")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1)
                                .foregroundColor(Theme.gold)

                            ForEach(mapRoutes) { route in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(route.color)
                                            .frame(width: 8, height: 8)
                                        Text(route.label)
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(Theme.text)
                                        Spacer()
                                    }
                                    Text("\(route.fromSiteName) \u{2192} \(route.toSiteName)")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(Theme.muted)

                                    if let computed = computedRoutes[route.id] {
                                        HStack(spacing: 6) {
                                            Text(String(format: "%.1f mi", computed.distance / 1609.34))
                                                .font(.system(size: 7, weight: .bold))
                                                .foregroundColor(Theme.green)
                                            Text("\u{00B7} ETA \(Int((computed.expectedTravelTime / 60).rounded())) min")
                                                .font(.system(size: 7, weight: .bold))
                                                .foregroundColor(Theme.cyan)
                                        }
                                    } else if computingRoute == route.id {
                                        Text("Computing route...")
                                            .font(.system(size: 7, weight: .semibold))
                                            .foregroundColor(Theme.gold)
                                    } else if routeError == route.id {
                                        Text("Route unavailable. Showing straight-line connection.")
                                            .font(.system(size: 7, weight: .semibold))
                                            .foregroundColor(Theme.red)
                                    } else {
                                        Button("GET DIRECTIONS") {
                                            Task { await calculateRoute(for: route) }
                                        }
                                        .font(.system(size: 7, weight: .black))
                                        .foregroundColor(Theme.cyan)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Theme.surface)
                                        .cornerRadius(4)
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(8)
                                .background(Theme.surface.opacity(0.72))
                                .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        .background(Theme.surface.opacity(0.78))
                        .cornerRadius(10)
                    }
                    .frame(width: 250)
                }
            }
            .padding(14)
        }
        .background(Theme.bg)
        .sheet(isPresented: $showCheckInSheet) {
            EquipmentCheckInView(onCheckInComplete: { name in
                checkInSuccessMessage = "Location updated for \(name)"
                Task { await loadMapData() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    checkInSuccessMessage = nil
                }
            })
        }
        // Phase 21-09 Task 1: surface loadMapData errors to UI (Test 11 — no silent throw-swallow)
        .alert(
            "Map data load failed",
            isPresented: Binding(
                get: { loadError != nil },
                set: { if !$0 { loadError = nil } }
            ),
            presenting: loadError
        ) { _ in
            Button("Dismiss", role: .cancel) { loadError = nil }
            Button("Retry") { Task { await loadMapData() } }
        } message: { error in
            Text(error.errorDescription ?? "Unknown error. Map is showing offline data.")
        }
        .overlay(alignment: .top) {
            if let msg = checkInSuccessMessage {
                Text(msg)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.green)
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: checkInSuccessMessage)
                    .padding(.top, 8)
            }
        }
        .onChange(of: satelliteMode) { _, new in savedSatellite = new }
        .onChange(of: trafficOverlay) { _, new in savedTraffic = new }
        .onChange(of: thermalOverlay) { _, new in savedThermal = new }
        .onChange(of: crewOverlay) { _, new in savedCrew = new }
        .onChange(of: weatherOverlay) { _, new in savedWeather = new }
        .onChange(of: photosOverlay) { _, new in savedPhotos = new }
        // Phase 21-10 Task 1: persist AUTO TRACK (Test 10 defect 1)
        .onChange(of: autoTrack) { _, new in savedAutoTrack = new }
        .onAppear {
            satelliteMode = savedSatellite
            trafficOverlay = savedTraffic
            thermalOverlay = savedThermal
            crewOverlay = savedCrew
            weatherOverlay = savedWeather
            photosOverlay = savedPhotos
            // Phase 21-10 Task 1: restore AUTO TRACK (Test 10 defect 1)
            autoTrack = savedAutoTrack
        }
        .task {
            await loadMapData()
        }
    }

    private func loadMapData() async {
        isLoadingData = true
        // MARK: Equipment fetch (Phase 21-09 Task 2: empty-success fallback; Task 1: visible errors)
        do {
            let fetched = try await SupabaseService.shared.fetchEquipmentPositions()
            // Empty-successful response: use mocks only when Supabase is unconfigured — a configured
            // empty result is a legitimate empty state that must stay empty (otherwise UI lies).
            if fetched.isEmpty && !SupabaseService.shared.isConfigured {
                equipmentPositions = mockEquipmentPositions
            } else {
                equipmentPositions = fetched
            }
        } catch {
            let wrapped = (error as? AppError) ?? AppError.unknown(error.localizedDescription)
            // Only surface to UI when Supabase IS configured — unconfigured paths are expected to
            // fall back to mocks silently (that's the intended dev/demo experience).
            if SupabaseService.shared.isConfigured {
                loadError = wrapped
            }
            CrashReporter.shared.reportError("Maps equipment load failed: \(error.localizedDescription)")
            equipmentPositions = mockEquipmentPositions
        }
        // MARK: Photo fetch (Phase 21-09 Task 3: mock fallback + visible errors symmetric with equipment)
        do {
            let docs: [SupabaseGpsDocument] = try await SupabaseService.shared.fetch(
                "cs_documents",
                query: ["select": "id,filename,gps_lat,gps_lng,created_at", "gps_lat": "not.is.null", "gps_lng": "not.is.null"]
            )
            let mapped = docs.map { doc in
                MapPhotoAnnotation(
                    id: doc.id,
                    filename: doc.filename,
                    coordinate: CLLocationCoordinate2D(latitude: doc.gpsLat, longitude: doc.gpsLng),
                    createdAt: doc.createdAt
                )
            }
            if mapped.isEmpty && !SupabaseService.shared.isConfigured {
                photoAnnotations = mockPhotoAnnotations
            } else {
                photoAnnotations = mapped
            }
        } catch {
            let wrapped = (error as? AppError) ?? AppError.unknown(error.localizedDescription)
            if SupabaseService.shared.isConfigured {
                loadError = wrapped
            }
            CrashReporter.shared.reportError("Maps photo load failed: \(error.localizedDescription)")
            photoAnnotations = mockPhotoAnnotations
        }
        isLoadingData = false
    }

    // MARK: - Delivery Route Calculation (D-16)

    private func calculateRoute(for route: MapRoute) async {
        guard
            let fromSite = mapSites.first(where: { $0.name == route.fromSiteName }),
            let toSite = mapSites.first(where: { $0.name == route.toSiteName })
        else { return }

        computingRoute = route.id
        routeError = nil

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromSite.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toSite.coordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            if let first = response.routes.first {
                computedRoutes[route.id] = first
            } else {
                routeError = route.id
            }
        } catch {
            CrashReporter.shared.reportError("MKDirections failed: \(error.localizedDescription)")
            routeError = route.id
        }
        computingRoute = nil
    }

    private func mapMetricCard(title: String, value: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 15, weight: .black))
                .foregroundColor(Theme.text)
            Text(detail)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.surface.opacity(0.78))
        .cornerRadius(10)
    }

    private func statusRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(color)
        }
    }
}

// MARK: - Live Map View

// MARK: - Saved Camera (D-12)

private struct SavedCamera: Codable {
    let lat: Double
    let lng: Double
    let spanLat: Double
    let spanLng: Double
}

struct LiveMapView: View {
    let sites: [MapSite]
    let routes: [MapRoute]
    @Binding var selectedSiteID: UUID?
    let satelliteMode: Bool
    let trafficOverlay: Bool
    let thermalOverlay: Bool
    let crewOverlay: Bool
    let weatherOverlay: Bool
    let photosOverlay: Bool
    let equipmentPositions: [SupabaseEquipmentLatestPosition]
    let photoAnnotations: [MapPhotoAnnotation]
    let computedRoutes: [UUID: MKRoute]
    let activeSweep: Int
    let cameraPreset: MapCameraPreset
    @State private var cameraPosition: MapCameraPosition = .region(MapSite.defaultRegion)
    @State private var selectedEquipmentID: String?
    @State private var selectedPhotoID: String?
    // Phase 21-10 Task 1: first-restore guard (Test 10 defect 4) — suppresses
    // the two updateCamera() onChange handlers during the tick we restore from
    // savedCameraJSON so cameraPreset=.selected @State default can't clobber it.
    @State private var cameraRestored = false
    // Phase 21-10 Task 1: ScenePhase-driven save backstop for force-quit (Test 10 defect 3)
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("ConstructOS.Maps.Camera.default") private var savedCameraJSON = ""

    private var selectedSite: MapSite? {
        sites.first { $0.id == selectedSiteID }
    }

    private var resolvedRoutes: [(route: MapRoute, coordinates: [CLLocationCoordinate2D])] {
        routes.compactMap { route in
            guard
                let fromSite = sites.first(where: { $0.name == route.fromSiteName }),
                let toSite = sites.first(where: { $0.name == route.toSiteName })
            else {
                return nil
            }

            return (route, [fromSite.coordinate, toSite.coordinate])
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                mapLayer
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size)

                    for offset in stride(from: 20.0, through: size.width, by: 38.0) {
                        var path = Path()
                        path.move(to: CGPoint(x: offset, y: 0))
                        path.addLine(to: CGPoint(x: offset - 28, y: size.height))
                        context.stroke(path, with: .color(Theme.border.opacity(0.18)), lineWidth: 1)
                    }

                    for offset in stride(from: 35.0, through: size.height, by: 52.0) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: offset))
                        path.addLine(to: CGPoint(x: size.width, y: offset - 18))
                        context.stroke(path, with: .color(Theme.border.opacity(0.14)), lineWidth: 1)
                    }

                    if satelliteMode {
                        context.fill(
                            Path(ellipseIn: CGRect(x: rect.maxX * 0.55, y: rect.maxY * 0.08, width: rect.width * 0.24, height: rect.height * 0.16)),
                            with: .radialGradient(
                                Gradient(colors: [Theme.gold.opacity(0.30), .clear]),
                                center: CGPoint(x: rect.maxX * 0.67, y: rect.maxY * 0.16),
                                startRadius: 4,
                                endRadius: 120
                            )
                        )
                    }

                    if thermalOverlay {
                        context.fill(
                            Path(ellipseIn: CGRect(x: rect.maxX * 0.18, y: rect.maxY * 0.44, width: rect.width * 0.34, height: rect.height * 0.22)),
                            with: .radialGradient(
                                Gradient(colors: [Theme.red.opacity(0.34), Theme.gold.opacity(0.16), .clear]),
                                center: CGPoint(x: rect.maxX * 0.32, y: rect.maxY * 0.54),
                                startRadius: 8,
                                endRadius: 120
                            )
                        )
                    }

                    if weatherOverlay {
                        context.fill(
                            Path(CGRect(x: rect.maxX * 0.62, y: rect.maxY * 0.04, width: rect.width * 0.28, height: rect.height * 0.24)),
                            with: .linearGradient(
                                Gradient(colors: [Theme.purple.opacity(0.18), .clear]),
                                startPoint: CGPoint(x: rect.maxX * 0.62, y: rect.maxY * 0.04),
                                endPoint: CGPoint(x: rect.maxX * 0.90, y: rect.maxY * 0.28)
                            )
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("LIVE SITE MAP")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                            .foregroundColor(Theme.cyan)
                        Spacer()
                        Text(satelliteMode ? "SATELLITE" : "GRID")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(satelliteMode ? Theme.gold : Theme.surface)
                            .cornerRadius(4)
                    }

                    Spacer()

                    ZStack {
                        ForEach(sites) { site in
                            Button {
                                selectedSiteID = site.id
                            } label: {
                                VStack(spacing: 3) {
                                    Circle()
                                        .fill(selectedSiteID == site.id ? Theme.gold : Theme.cyan)
                                        .frame(width: selectedSiteID == site.id ? 18 : 14, height: selectedSiteID == site.id ? 18 : 14)
                                        .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
                                    Text(site.name.uppercased())
                                        .font(.system(size: 7, weight: .black))
                                        .foregroundColor(Theme.text)
                                }
                            }
                            .buttonStyle(.plain)
                            .position(x: proxy.size.width * site.x, y: proxy.size.height * site.y)
                        }
                    }

                    HStack(spacing: 8) {
                        if crewOverlay {
                            overlayTag("Crew routes", color: Theme.cyan)
                        }
                        if thermalOverlay {
                            overlayTag("Thermal", color: Theme.red)
                        }
                        if weatherOverlay {
                            overlayTag("Wind", color: Theme.purple)
                        }
                        if trafficOverlay {
                            overlayTag("Traffic", color: Theme.gold)
                        }
                        if photosOverlay {
                            overlayTag("Photos", color: Theme.cyan)
                        }
                        Spacer()
                        Text("Sweep #\(activeSweep)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(Theme.muted)
                    }

                    if let selectedSite {
                        Text("\(selectedSite.name) · \(selectedSite.status)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.surface.opacity(0.85))
                            .cornerRadius(8)
                    }
                }
                .padding(14)
            }
        }
        // Phase 21-10 Task 1: restore camera from savedCameraJSON on launch, then
        // flip cameraRestored so the two updateCamera() onChange handlers below stop no-opping.
        // Test 10 defect 4 — cameraPreset @State defaults to .selected every launch and
        // the old .onChange would immediately clobber the restored camera.
        .onAppear {
            if !savedCameraJSON.isEmpty,
               let data = savedCameraJSON.data(using: .utf8),
               let cam = try? JSONDecoder().decode(SavedCamera.self, from: data) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: cam.lat, longitude: cam.lng),
                    span: MKCoordinateSpan(latitudeDelta: cam.spanLat, longitudeDelta: cam.spanLng)
                ))
                cameraRestored = true
            } else {
                updateCamera()
                cameraRestored = true
            }
        }
        // Phase 21-10 Task 1: live camera save via .onMapCameraChange (Test 10 defects 2 + 3).
        // Old code saved region(for: cameraPreset) on .onDisappear — wrong source (preset, not
        // live pan/zoom) AND unreliable trigger (doesn't fire on force-quit).
        .onMapCameraChange(frequency: .continuous) { ctx in
            let cam = SavedCamera(
                lat: ctx.region.center.latitude,
                lng: ctx.region.center.longitude,
                spanLat: ctx.region.span.latitudeDelta,
                spanLng: ctx.region.span.longitudeDelta
            )
            if let data = try? JSONEncoder().encode(cam), let str = String(data: data, encoding: .utf8) {
                savedCameraJSON = str
            }
        }
        // Phase 21-10 Task 1: ScenePhase backstop (Test 10 defect 3 belt-and-suspenders).
        // .onMapCameraChange(.continuous) is the authoritative save path; this extra trigger
        // captures any pending in-flight state before the app is backgrounded or force-quit.
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background || newPhase == .inactive else { return }
            // Re-encode whatever savedCameraJSON currently holds so the .continuous write is
            // flushed to disk. No-op if savedCameraJSON is already up-to-date.
            if !savedCameraJSON.isEmpty {
                // touching the @AppStorage binding forces a UserDefaults sync on background
                let current = savedCameraJSON
                savedCameraJSON = current
            }
        }
        // Phase 21-10 Task 1: gate updateCamera() on cameraRestored so the first-tick
        // default values of selectedSiteID / cameraPreset can't clobber the restored camera.
        .onChange(of: selectedSiteID) { _, _ in
            guard cameraRestored else { return }
            updateCamera()
        }
        .onChange(of: cameraPreset) { _, _ in
            guard cameraRestored else { return }
            updateCamera()
        }
    }

    private func overlayTag(_ label: String, color: Color) -> some View {
        Text(label.uppercased())
            .font(.system(size: 7, weight: .black))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(5)
    }

    @ViewBuilder
    private var mapLayer: some View {
        if satelliteMode {
            liveMapBase
                .mapStyle(.hybrid(elevation: .realistic, showsTraffic: trafficOverlay))
        } else {
            liveMapBase
                .mapStyle(.standard(showsTraffic: trafficOverlay))
        }
    }

    private var liveMapBase: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            ForEach(resolvedRoutes, id: \.route.id) { item in
                // Straight-line connector (hidden when a computed road route exists)
                if computedRoutes[item.route.id] == nil {
                    MapPolyline(coordinates: item.coordinates)
                        .stroke(item.route.color.opacity(crewOverlay ? 0.92 : 0.25), lineWidth: crewOverlay ? 4 : 2)
                }
            }

            // MARK: Computed Road Routes (D-16)
            ForEach(Array(computedRoutes.keys), id: \.self) { key in
                if let route = computedRoutes[key] {
                    MapPolyline(route.polyline)
                        .stroke(Theme.gold, lineWidth: 4)
                }
            }

            ForEach(sites) { site in
                Annotation(site.name, coordinate: site.coordinate, anchor: .center) {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(selectedSiteID == site.id ? Theme.gold : Theme.cyan)
                            .frame(width: selectedSiteID == site.id ? 16 : 12, height: selectedSiteID == site.id ? 16 : 12)
                            .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
                        Text(site.name)
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(Theme.text)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Theme.surface.opacity(0.82))
                            .cornerRadius(4)
                    }
                    .onTapGesture {
                        selectedSiteID = site.id
                    }
                }
            }

            // MARK: Equipment Annotations (D-08, MAP-03)
            ForEach(equipmentPositions) { item in
                Annotation(item.name, coordinate: item.coordinate, anchor: .bottom) {
                    VStack(spacing: 2) {
                        Image(systemName: item.sfSymbolName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(item.statusColor)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))

                        if selectedEquipmentID == item.id {
                            VStack(spacing: 1) {
                                Text(item.name)
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundColor(Theme.text)
                                Text(item.status.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.system(size: 6, weight: .semibold))
                                    .foregroundColor(item.statusColor)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Theme.surface.opacity(0.9))
                            .cornerRadius(4)
                        }
                    }
                    .onTapGesture {
                        selectedEquipmentID = selectedEquipmentID == item.id ? nil : item.id
                    }
                }
            }

            // MARK: Photo Annotations (D-17, MAP-04)
            ForEach(photoAnnotations) { photo in
                Annotation(photo.filename, coordinate: photo.coordinate, anchor: .bottom) {
                    VStack(spacing: 2) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Theme.purple)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))

                        if selectedPhotoID == photo.id {
                            VStack(spacing: 1) {
                                Text(photo.filename)
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundColor(Theme.text)
                                    .lineLimit(1)
                                Text(photo.createdAt)
                                    .font(.system(size: 6, weight: .semibold))
                                    .foregroundColor(Theme.muted)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Theme.surface.opacity(0.9))
                            .cornerRadius(4)
                        }
                    }
                    .onTapGesture {
                        selectedPhotoID = selectedPhotoID == photo.id ? nil : photo.id
                    }
                }
            }
        }
        .mapControlVisibility(.hidden)
        .overlay(
            LinearGradient(
                colors: [
                    Color.black.opacity(satelliteMode ? 0.18 : 0.10),
                    Color.clear,
                    Theme.bg.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func updateCamera() {
        cameraPosition = .region(region(for: cameraPreset))
    }

    private func region(for preset: MapCameraPreset) -> MKCoordinateRegion {
        switch preset {
        case .network:
            return MKCoordinateRegion(
                center: MapSite.mapCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.055, longitudeDelta: 0.055)
            )
        case .selected:
            return selectedSite?.focusRegion ?? MapSite.defaultRegion
        case .logistics:
            if let logisticsSite = sites.first(where: { $0.type == "LOGISTICS" }) {
                return MKCoordinateRegion(
                    center: logisticsSite.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
            }
            return MapSite.defaultRegion
        case .weather:
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: MapSite.mapCenter.latitude + 0.01,
                    longitude: MapSite.mapCenter.longitude + 0.012
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        }
    }
}
