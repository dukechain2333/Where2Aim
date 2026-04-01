import CoreLocation
import MapKit
import SwiftUI

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct MapView: View {
    private static let defaultVisibleWidthYards = 300.0
    private static let metersPerYard = 0.9144

    @StateObject private var locationController = MapLocationController()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var targetCoordinate: CLLocationCoordinate2D?
    @State private var hasCenteredOnUser = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.08, blue: 0.08), Color(red: 0.16, green: 0.19, blue: 0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Group {
                    switch locationController.authorizationStatus {
                    case .authorizedAlways, .authorizedWhenInUse:
                        mapContent
                    case .notDetermined:
                        locationPrompt
                            .padding(20)
                    case .denied, .restricted:
                        locationDenied
                            .padding(20)
                    @unknown default:
                        locationDenied
                            .padding(20)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            locationController.refreshAuthorization()
            locationController.requestIfNeeded()
        }
        .onAppear {
            locationController.startUpdating()
        }
        .onDisappear {
            locationController.stopUpdating()
        }
        .onChange(of: locationController.currentCoordinate) { _, coordinate in
            guard let coordinate, !hasCenteredOnUser else {
                return
            }

            cameraPosition = defaultCameraPosition(centeredAt: coordinate)
            hasCenteredOnUser = true
        }
    }

    private var mapContent: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let safeBottom = geometry.safeAreaInsets.bottom

            Group {
                if isLandscape {
                    HStack(alignment: .top, spacing: 16) {
                        mapSurface(height: max(geometry.size.height - safeBottom - 24, 280))
                            .frame(maxWidth: .infinity)

                        distancePanel
                            .frame(width: min(max(geometry.size.width * 0.24, 220), 280))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, max(safeBottom, 18))
                } else {
                    VStack(spacing: 16) {
                        mapSurface(height: min(max(geometry.size.height * 0.72, 360), 600))

                        distancePanel
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, max(safeBottom, 18))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func mapSurface(height: CGFloat) -> some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let targetCoordinate {
                    Annotation("Target", coordinate: targetCoordinate) {
                        PinBadge(label: "B", tint: Color(red: 0.85, green: 0.18, blue: 0.18))
                    }
                }

                if let userCoordinate = locationController.currentCoordinate {
                    Annotation("You", coordinate: userCoordinate) {
                        PinBadge(label: "A", tint: Color(red: 0.16, green: 0.72, blue: 0.38))
                    }

                    if let targetCoordinate {
                        MapPolyline(coordinates: [userCoordinate, targetCoordinate])
                            .stroke(
                                Color(red: 0.85, green: 0.18, blue: 0.18),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                    }
                }
            }
            .mapStyle(.imagery(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let mapPoint = CGPoint(x: value.location.x, y: value.location.y)
                        guard let coordinate = proxy.convert(mapPoint, from: .local) else {
                            return
                        }

                        targetCoordinate = coordinate
                    }
            )
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var locationPrompt: some View {
        permissionCard(
            title: "Location Access",
            message: "The Map page needs your current location to pin the first point and measure the distance to a tapped target."
        ) {
            Button {
                locationController.requestIfNeeded()
            } label: {
                Text("Enable Location")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.89, green: 0.93, blue: 0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var locationDenied: some View {
        permissionCard(
            title: "Location Unavailable",
            message: "Location access is denied or restricted. Turn it on in Settings to place the first point at your position."
        ) {
            EmptyView()
        }
    }

    private var distancePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let distanceSummary {
                Text(distanceSummary)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text(placeholderSummary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            if horizontalSizeClass == .compact && isLandscapeLike {
                VStack(spacing: 10) {
                    recenterButton
                    clearTargetButton
                }
            } else {
                HStack(spacing: 12) {
                    recenterButton
                    clearTargetButton
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscapeLike: Bool {
        horizontalSizeClass == .compact && verticalSizeClass == .compact
    }

    private var recenterButton: some View {
        Button {
            recenterOnUser()
        } label: {
            Label("Recenter", systemImage: "location.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var clearTargetButton: some View {
        Button {
            targetCoordinate = nil
        } label: {
            Label("Clear Target", systemImage: "xmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.91, green: 0.95, blue: 0.88))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(targetCoordinate == nil)
        .opacity(targetCoordinate == nil ? 0.45 : 1)
    }

    private func permissionCard<Content: View>(
        title: String,
        message: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text(message)
                .foregroundStyle(.white.opacity(0.76))

            content()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var placeholderSummary: String {
        if locationController.currentCoordinate == nil {
            return "Waiting for your current location"
        }

        return "Tap the map to place the second point"
    }

    private var distanceSummary: String? {
        guard let userCoordinate = locationController.currentCoordinate,
              let targetCoordinate else {
            return nil
        }

        let start = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let end = CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude)
        let distanceMeters = start.distance(from: end)
        let distanceYards = distanceMeters * 1.09361

        if distanceMeters >= 1000 {
            return String(format: "%.2f km • %.0f yd", distanceMeters / 1000, distanceYards)
        }

        return String(format: "%.0f m • %.0f yd", distanceMeters, distanceYards)
    }

    private func recenterOnUser() {
        guard let coordinate = locationController.currentCoordinate else {
            return
        }

        cameraPosition = defaultCameraPosition(centeredAt: coordinate)
    }

    private func defaultCameraPosition(centeredAt coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .camera(
            MapCamera(
                centerCoordinate: coordinate,
                distance: Self.defaultVisibleWidthYards * Self.metersPerYard,
                heading: 0,
                pitch: 0
            )
        )
    }
}

private struct PinBadge: View {
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint)
                .clipShape(Circle())

            Triangle()
                .fill(tint)
                .frame(width: 12, height: 8)
                .offset(y: -1)
        }
        .shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: 4)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

private final class MapLocationController: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        authorizationStatus = manager.authorizationStatus
        currentCoordinate = manager.location?.coordinate
    }

    func refreshAuthorization() {
        authorizationStatus = manager.authorizationStatus
    }

    func requestIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func startUpdating() {
        guard manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse else {
            return
        }

        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            currentCoordinate = manager.location?.coordinate
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentCoordinate = locations.last?.coordinate
    }
}
