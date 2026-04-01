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

    private var liveScope: some View {
        GeometryReader { geometry in
            let bottomGap: CGFloat = 18

            ZStack {
                ScopeCameraPreview(session: cameraController.session)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )

                ScopeReticleOverlay()
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: max(0, geometry.size.height - bottomGap))
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.black.opacity(0.22))
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
    private let rangingMarks: [(distance: Int, lineHeightRatio: CGFloat)] = [
        (50, 1.0),
        (100, 0.5),
        (150, 1.0 / 3.0),
        (200, 0.25),
        (250, 0.2),
        (300, 1.0 / 6.0)
    ]
    private let reticleWidth: CGFloat = 320
    private let reticleLineHeight: CGFloat = 240

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let availableWidth = min(reticleWidth, max(0, size.width - 48))
            let baseLineHeight = min(reticleLineHeight, max(0, size.height - 120))

            VStack {
                Spacer(minLength: size.height * 0.14)

                HStack(alignment: .center, spacing: 0) {
                    ForEach(Array(rangingMarks.enumerated()), id: \.offset) { _, mark in
                        VStack(spacing: 10) {
                            Spacer(minLength: 0)

                            Capsule()
                                .fill(Color(red: 0.86, green: 0.13, blue: 0.13).opacity(0.92))
                                .frame(width: 3, height: baseLineHeight * mark.lineHeightRatio)
                                .shadow(color: .black.opacity(0.45), radius: 6, x: 0, y: 0)

                            Text("\(mark.distance)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(height: baseLineHeight + 28, alignment: .bottom)
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

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "scope.camera.session")
    private var isConfigured = false
    private var shouldRunSession = false

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

            if device.isRampingVideoZoom {
                device.cancelVideoZoomRamp()
            }

            if device.videoZoomFactor != 1.0 {
                do {
                    try device.lockForConfiguration()
                    device.videoZoomFactor = 1.0
                    device.unlockForConfiguration()
                } catch {
                    // Keep the live camera feed available even if zoom reset fails.
                }
            }

            isConfigured = true
        } catch {
            return
        }
    }
}
