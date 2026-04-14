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

    // D-11: Overlay persistence
    @AppStorage("ConstructOS.Maps.OverlaySatellite") private var savedSatellite = true
    @AppStorage("ConstructOS.Maps.OverlayTraffic") private var savedTraffic = false
    @AppStorage("ConstructOS.Maps.OverlayThermal") private var savedThermal = true
    @AppStorage("ConstructOS.Maps.OverlayCrew") private var savedCrew = true
    @AppStorage("ConstructOS.Maps.OverlayWeather") private var savedWeather = false
    @AppStorage("ConstructOS.Maps.OverlayPhotos") private var savedPhotos = false

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

                HStack(spacing: 8) {
                    Toggle("SATELLITE", isOn: $satelliteMode)
                        .toggleStyle(.button)
                    Toggle("THERMAL", isOn: $thermalOverlay)
                        .toggleStyle(.button)
                    Toggle("CREWS", isOn: $crewOverlay)
                        .toggleStyle(.button)
                    Toggle("WEATHER", isOn: $weatherOverlay)
                        .toggleStyle(.button)
                    Toggle("AUTO TRACK", isOn: $autoTrack)
                        .toggleStyle(.button)
                    Toggle("TRAFFIC", isOn: $trafficOverlay)
                        .toggleStyle(.button)
                    Toggle("PHOTOS", isOn: $photosOverlay)
                        .toggleStyle(.button)
                }
                .font(.system(size: 8, weight: .bold))

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
                    }
                    .frame(width: 250)
                }
            }
            .padding(14)
        }
        .background(Theme.bg)
        .onChange(of: satelliteMode) { _, new in savedSatellite = new }
        .onChange(of: trafficOverlay) { _, new in savedTraffic = new }
        .onChange(of: thermalOverlay) { _, new in savedThermal = new }
        .onChange(of: crewOverlay) { _, new in savedCrew = new }
        .onChange(of: weatherOverlay) { _, new in savedWeather = new }
        .onChange(of: photosOverlay) { _, new in savedPhotos = new }
        .onAppear {
            satelliteMode = savedSatellite
            trafficOverlay = savedTraffic
            thermalOverlay = savedThermal
            crewOverlay = savedCrew
            weatherOverlay = savedWeather
            photosOverlay = savedPhotos
        }
        .task {
            isLoadingData = true
            do {
                equipmentPositions = try await SupabaseService.shared.fetchEquipmentPositions()
            } catch {
                CrashReporter.shared.reportError("Maps equipment load failed: \(error.localizedDescription)")
                equipmentPositions = mockEquipmentPositions
            }
            do {
                let docs: [SupabaseGpsDocument] = try await SupabaseService.shared.fetch(
                    "cs_documents",
                    query: ["select": "id,filename,gps_lat,gps_lng,created_at", "gps_lat": "not.is.null", "gps_lng": "not.is.null"]
                )
                photoAnnotations = docs.map { doc in
                    MapPhotoAnnotation(
                        id: doc.id,
                        filename: doc.filename,
                        coordinate: CLLocationCoordinate2D(latitude: doc.gpsLat, longitude: doc.gpsLng),
                        createdAt: doc.createdAt
                    )
                }
            } catch {
                CrashReporter.shared.reportError("Maps photo load failed: \(error.localizedDescription)")
            }
            isLoadingData = false
        }
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
    let activeSweep: Int
    let cameraPreset: MapCameraPreset
    @State private var cameraPosition: MapCameraPosition = .region(MapSite.defaultRegion)
    @State private var selectedEquipmentID: String?
    @State private var selectedPhotoID: String?
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
        .onAppear {
            if !savedCameraJSON.isEmpty,
               let data = savedCameraJSON.data(using: .utf8),
               let cam = try? JSONDecoder().decode(SavedCamera.self, from: data) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: cam.lat, longitude: cam.lng),
                    span: MKCoordinateSpan(latitudeDelta: cam.spanLat, longitudeDelta: cam.spanLng)
                ))
            } else {
                updateCamera()
            }
        }
        .onDisappear {
            let currentRegion = region(for: cameraPreset)
            let cam = SavedCamera(
                lat: currentRegion.center.latitude,
                lng: currentRegion.center.longitude,
                spanLat: currentRegion.span.latitudeDelta,
                spanLng: currentRegion.span.longitudeDelta
            )
            if let data = try? JSONEncoder().encode(cam), let str = String(data: data, encoding: .utf8) {
                savedCameraJSON = str
            }
        }
        .onChange(of: selectedSiteID) { _, _ in
            updateCamera()
        }
        .onChange(of: cameraPreset) { _, _ in
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
                MapPolyline(coordinates: item.coordinates)
                    .stroke(item.route.color.opacity(crewOverlay ? 0.92 : 0.25), lineWidth: crewOverlay ? 4 : 2)
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
