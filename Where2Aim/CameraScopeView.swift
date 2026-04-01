import AVFoundation
import SwiftUI
import UIKit

struct ScopeView: View {
    @StateObject private var cameraController = ScopeCameraController()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.05, blue: 0.05), Color(red: 0.14, green: 0.17, blue: 0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Group {
                    switch cameraController.authorizationStatus {
                    case .authorized:
                        liveScope
                            .ignoresSafeArea(edges: .top)
                    case .notDetermined:
                        permissionPrompt
                            .padding(20)
                    case .denied, .restricted:
                        permissionDenied
                            .padding(20)
                    @unknown default:
                        permissionDenied
                            .padding(20)
                    }
                }
            }
        }
        .task {
            cameraController.refreshAuthorization()
            await cameraController.prepareIfNeeded()
        }
        .onAppear {
            cameraController.startSession()
        }
        .onDisappear {
            cameraController.stopSession()
        }
    }

    @State private var zoomAtGestureStart: CGFloat = 2.0

    private var liveScope: some View {
        GeometryReader { geometry in
            let bottomGap: CGFloat = 18

            ZStack {
                ScopeCameraPreview(session: cameraController.session)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )

                ScopeReticleOverlay(cameraFOVDegrees: cameraController.cameraFOVDegrees,
                                    zoomFactor: cameraController.zoomFactor)
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: max(0, geometry.size.height - bottomGap))
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.black.opacity(0.22))
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        cameraController.setZoom(zoomAtGestureStart * scale)
                    }
                    .onEnded { scale in
                        zoomAtGestureStart = cameraController.zoomFactor
                    }
            )
        }
    }

    private var permissionPrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Camera Access")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("The scope screen needs the rear camera to show a live view with the reticle overlay.")
                .foregroundStyle(.white.opacity(0.76))

            Button {
                cameraController.requestAccess()
            } label: {
                Text("Enable Camera")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.89, green: 0.93, blue: 0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
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

    private var permissionDenied: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Camera Unavailable")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("Camera access is denied or restricted. Turn it on in Settings to use the Scope page.")
                .foregroundStyle(.white.opacity(0.76))
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

}

private struct ScopeReticleOverlay: View {
    /// Horizontal FOV of the camera sensor in degrees.
    /// In portrait mode with resizeAspectFill the sensor's horizontal axis maps to the
    /// screen's vertical axis, so this value is also the effective vertical FOV of the display.
    let cameraFOVDegrees: Double
    /// Digital zoom factor applied to the camera feed. Zooming crops the sensor,
    /// so the on-screen angular size of any object scales linearly with zoom.
    let zoomFactor: CGFloat

    private let distances: [Int] = [50, 100, 150, 200, 250, 300]
    /// Height of a 5′9″ person in metres.
    private let personHeightM: Double = 1.7526
    private let yardsToMeters: Double = 0.9144
    private let reticleWidth: CGFloat = 320

    /// Returns the on-screen height (in points) that a 5′9″ person would appear at
    /// `distanceYards` yards, given the current screen height, camera vertical FOV, and zoom.
    private func lineHeight(for distanceYards: Int, screenHeight: CGFloat) -> CGFloat {
        let vFOVRad = cameraFOVDegrees * .pi / 180.0
        let distanceM = Double(distanceYards) * yardsToMeters
        let fraction = personHeightM / (distanceM * 2.0 * tan(vFOVRad / 2.0))
        return max(4, CGFloat(fraction) * screenHeight * zoomFactor)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let availableWidth = min(reticleWidth, max(0, size.width - 48))
            let tallestLine = lineHeight(for: distances[0], screenHeight: size.height)

            VStack {
                Spacer(minLength: size.height * 0.14)

                HStack(alignment: .center, spacing: 0) {
                    ForEach(distances, id: \.self) { distance in
                        VStack(spacing: 10) {
                            Spacer(minLength: 0)

                            Capsule()
                                .fill(Color(red: 0.86, green: 0.13, blue: 0.13).opacity(0.92))
                                .frame(width: 3, height: lineHeight(for: distance, screenHeight: size.height))
                                .shadow(color: .black.opacity(0.45), radius: 6, x: 0, y: 0)

                            Text("\(distance)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(height: tallestLine + 28, alignment: .bottom)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: availableWidth)

                Spacer()
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

private struct ScopeCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewOrientation()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updatePreviewOrientation()
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer backing layer.")
        }

        return layer
    }

    private func updatePreviewOrientation() {
        guard let connection = previewLayer.connection else {
            return
        }

        let interfaceOrientation = window?.windowScene?.interfaceOrientation ?? .portrait

        if connection.isVideoRotationAngleSupported(0) {
            connection.videoRotationAngle = Self.rotationAngle(for: interfaceOrientation)
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = Self.videoOrientation(for: interfaceOrientation)
        }
    }

    private static func rotationAngle(for orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .portrait:
            return 90
        case .landscapeRight:
            return 0
        case .portraitUpsideDown:
            return 270
        case .landscapeLeft:
            return 180
        default:
            return 90
        }
    }

    private static func videoOrientation(for orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .portrait:
            return .portrait
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}

private final class ScopeCameraController: ObservableObject, @unchecked Sendable {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    /// Horizontal FOV of the active camera format (degrees). Doubles as the display's
    /// vertical FOV in portrait mode with resizeAspectFill. Defaults to 65° until the
    /// session is configured and the real value is read from the device.
    @Published private(set) var cameraFOVDegrees: Double = 65.0
    /// The zoom factor applied to the camera feed. Published so the reticle overlay
    /// can scale line heights to match the zoomed view.
    @Published private(set) var zoomFactor: CGFloat = 2.0

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "scope.camera.session")
    private var isConfigured = false
    private var shouldRunSession = false
    private var captureDevice: AVCaptureDevice?

    func setZoom(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.captureDevice else { return }
            do {
                try device.lockForConfiguration()
                let clamped = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
                DispatchQueue.main.async { self.zoomFactor = clamped }
            } catch {}
        }
    }

    func refreshAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = status
        }
    }

    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else {
                return
            }

            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
            }

            guard granted else {
                return
            }

            Task {
                await self.prepareIfNeeded()
                self.startSession()
            }
        }
    }

    func prepareIfNeeded() async {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized, !isConfigured else {
            return
        }

        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                self.configureSession()

                if self.shouldRunSession, self.isConfigured, !self.session.isRunning {
                    self.session.startRunning()
                }

                continuation.resume()
            }
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else {
                return
            }

            self.shouldRunSession = true

            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
                  self.isConfigured,
                  !self.session.isRunning else {
                return
            }

            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else {
                return
            }

            self.shouldRunSession = false

            guard self.session.isRunning else {
                return
            }

            self.session.stopRunning()
        }
    }

    private func configureSession() {
        guard !isConfigured else {
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
        }

        session.inputs.forEach { session.removeInput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                return
            }
            session.addInput(input)
            captureDevice = device

            if device.isRampingVideoZoom {
                device.cancelVideoZoomRamp()
            }

            let targetZoom: CGFloat = 2.0
            var appliedZoom: CGFloat = device.videoZoomFactor
            if device.videoZoomFactor != targetZoom {
                do {
                    try device.lockForConfiguration()
                    appliedZoom = min(targetZoom, device.activeFormat.videoMaxZoomFactor)
                    device.videoZoomFactor = appliedZoom
                    device.unlockForConfiguration()
                } catch {
                    // Keep the live camera feed available even if zoom reset fails.
                }
            }

            isConfigured = true

            let fov = Double(device.activeFormat.videoFieldOfView)
            let zoom = appliedZoom
            DispatchQueue.main.async { [weak self] in
                self?.cameraFOVDegrees = fov
                self?.zoomFactor = zoom
            }
        } catch {
            return
        }
    }
}
