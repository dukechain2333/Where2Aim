import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        TabView {
            RecommendationPage()
                .tabItem {
                    Label("Aim", systemImage: "target")
                }

            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            ScopeView()
                .tabItem {
                    Label("Scope", systemImage: "scope")
                }
        }
        .tint(Color(red: 0.92, green: 0.96, blue: 0.88))
    }
}

private struct RecommendationPage: View {
    @State private var distanceToTarget: Double
    @State private var opticHeight: Double
    @State private var zeroDistance: Double
    @State private var remoteAim: CGSize = .zero

    init() {
        let lastSetup = SetupSelectionStore.loadLastSetup()
        _distanceToTarget = State(initialValue: lastSetup.distanceToTarget)
        _opticHeight = State(initialValue: lastSetup.opticHeight)
        _zeroDistance = State(initialValue: lastSetup.zeroDistance)
    }

    private var recommendation: AimingRecommendation {
        BallisticsModel.recommendation(
            for: BallisticsInputs(
                distanceToTargetYards: distanceToTarget,
                opticHeightInches: opticHeight,
                zeroDistanceYards: zeroDistance
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.11, blue: 0.12), Color(red: 0.18, green: 0.21, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        inputCard
                        resultCard
                    }
                    .padding(20)
                }
            }
        }
        .onChange(of: currentSetup) { _, newSetup in
            SetupSelectionStore.saveLastSetup(newSetup)
        }
    }

    private var currentSetup: SetupSelection {
        SetupSelection(
            distanceToTarget: distanceToTarget,
            opticHeight: opticHeight,
            zeroDistance: zeroDistance
        )
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setup")
                .font(.headline)
                .foregroundStyle(.white)

            labeledPicker(
                title: "Distance to target (yd)",
                selection: $distanceToTarget,
                values: Presets.distancesYards
            )

            labeledPicker(
                title: "Optic riser height (\")",
                selection: $opticHeight,
                values: Presets.opticHeightsInches
            )

            labeledPicker(
                title: "Zero distance (yd)",
                selection: $zeroDistance,
                values: Presets.zeroDistancesYards
            )
        }
        .padding(20)
        .background(cardBackground)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendation")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                statChip(title: "Impact offset", value: String(format: "%.1f in", recommendation.impactOffsetInches))
                statChip(title: "Suggested hold", value: String(format: "%.1f in", recommendation.holdOffsetInches))
            }

            VStack(alignment: .leading, spacing: 10) {
                RemoteThumbpad(offset: $remoteAim)

                TargetVisualization(
                    holdOffsetInches: recommendation.holdOffsetInches,
                    remoteAim: remoteAim
                )

                targetLegend
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.09))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func labeledPicker(title: String, selection: Binding<Double>, values: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))

            Picker(title, selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(format(value)).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))

            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.16))
        )
    }

    private var targetLegend: some View {
        HStack(spacing: 14) {
            legendItem(color: .green, label: "Green: Hit")
            legendItem(color: .red, label: "Red: Aim")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private func format(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

private struct SetupSelection: Equatable {
    let distanceToTarget: Double
    let opticHeight: Double
    let zeroDistance: Double
}

private enum SetupSelectionStore {
    private static let distanceKey = "lastSetup.distanceToTarget"
    private static let opticHeightKey = "lastSetup.opticHeight"
    private static let zeroDistanceKey = "lastSetup.zeroDistance"

    static func loadLastSetup() -> SetupSelection {
        let defaults = UserDefaults.standard

        return SetupSelection(
            distanceToTarget: value(forKey: distanceKey, defaults: defaults, fallback: 50.0),
            opticHeight: value(forKey: opticHeightKey, defaults: defaults, fallback: 1.93),
            zeroDistance: value(forKey: zeroDistanceKey, defaults: defaults, fallback: 25.0)
        )
    }

    static func saveLastSetup(_ setup: SetupSelection) {
        let defaults = UserDefaults.standard
        defaults.set(setup.distanceToTarget, forKey: distanceKey)
        defaults.set(setup.opticHeight, forKey: opticHeightKey)
        defaults.set(setup.zeroDistance, forKey: zeroDistanceKey)
    }

    private static func value(forKey key: String, defaults: UserDefaults, fallback: Double) -> Double {
        guard defaults.object(forKey: key) != nil else {
            return fallback
        }

        return defaults.double(forKey: key)
    }
}

private struct TargetVisualization: View {
    let holdOffsetInches: Double
    let remoteAim: CGSize
    private static let baseHeight: CGFloat = 220
    private static let canvasInset: CGFloat = 10
    private static let targetHeightRatio: CGFloat = 0.76
    private static let targetTravelInches: CGFloat = 30
    private static let baseTargetHeight: CGFloat = baseHeight * targetHeightRatio

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let targetHeight = Self.baseTargetHeight
            let targetWidth = min(size.width - 40, targetHeight * 0.56)
            let layout = layoutMetrics
            let markerX = markerXPosition(in: size.width)
            let markerGreenY = layout.topExtension + layout.greenY
            let markerRedY = layout.topExtension + layout.redY
            let baseCenterX = size.width / 2

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.16))

                USPSATargetShape()
                    .fill(Color(red: 0.74, green: 0.58, blue: 0.36))
                    .frame(width: targetWidth, height: targetHeight)
                    .position(x: baseCenterX, y: layout.topExtension + Self.canvasInset + (targetHeight / 2))

                USPSAScoringZone()
                    .stroke(Color.black.opacity(0.2), lineWidth: 1.5)
                    .frame(width: targetWidth * 0.42, height: targetHeight * 0.28)
                    .position(x: baseCenterX, y: layout.topExtension + Self.canvasInset + (targetHeight * 0.54))

                marker(color: .green)
                    .position(x: markerX, y: markerGreenY)

                marker(color: .red)
                    .position(x: markerX, y: markerRedY)
            }
        }
        .frame(height: canvasHeight)
    }

    private func marker(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 9, height: 9)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 0)
    }

    private var canvasHeight: CGFloat {
        Self.baseHeight + layoutMetrics.topExtension + layoutMetrics.bottomExtension
    }

    private var layoutMetrics: (greenY: CGFloat, redY: CGFloat, topExtension: CGFloat, bottomExtension: CGFloat) {
        let pixelsPerInch = Self.baseTargetHeight / Self.targetTravelInches
        let availableHeight = Self.baseHeight - (Self.canvasInset * 2)
        let normalizedY = (clamp(remoteAim.height, min: -1, max: 1) + 1) / 2
        let greenY = Self.canvasInset + (normalizedY * availableHeight)
        let redY = greenY - (holdOffsetInches * pixelsPerInch)
        let minY = min(greenY, redY)
        let maxY = max(greenY, redY)
        let topExtension = max(0, Self.canvasInset - minY)
        let bottomExtension = max(0, maxY - (Self.baseHeight - Self.canvasInset))
        return (greenY, redY, topExtension, bottomExtension)
    }

    private func markerXPosition(in width: CGFloat) -> CGFloat {
        let horizontalInset: CGFloat = 24
        let availableWidth = max(0, width - (horizontalInset * 2))
        let normalizedX = (clamp(remoteAim.width, min: -1, max: 1) + 1) / 2
        return horizontalInset + (normalizedX * availableWidth)
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}

private struct RemoteThumbpad: View {
    @Binding var offset: CGSize
    @GestureState private var remoteGestureState: RemoteGestureState = .inactive
    @State private var didSendActivationFeedback = false

    private static let cardHeight: CGFloat = 220
    private static let knobSize: CGFloat = 54
    private static let maxTravel: CGFloat = 70

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Remote")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            thumbpad
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.16))
        )
    }

    private var thumbpad: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: backgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )

            crosshair

            Circle()
                .fill(Color(red: 0.89, green: 0.93, blue: 0.9))
                .frame(width: Self.knobSize, height: Self.knobSize)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: 6)
                .offset(
                    x: offset.width * Self.maxTravel,
                    y: offset.height * Self.maxTravel
                )

            VStack {
                HStack {
                    Spacer()

                    Button {
                        offset = .zero
                    } label: {
                        Label("Recenter", systemImage: "scope")
                            .labelStyle(.iconOnly)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.22))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.cardHeight)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .gesture(remoteGesture)
        .onChange(of: remoteGestureState) { _, newValue in
            if newValue.isActive {
                guard !didSendActivationFeedback else {
                    return
                }

                triggerActivationFeedback()
                didSendActivationFeedback = true
            } else {
                didSendActivationFeedback = false
            }
        }
    }

    private var crosshair: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(width: 2, height: 150)

            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(maxWidth: .infinity)
                .frame(height: 2)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 132, height: 132)
        }
    }

    private func clampedOffset(for translation: CGSize) -> CGSize {
        let distance = sqrt((translation.width * translation.width) + (translation.height * translation.height))
        let boundedTranslation: CGSize
        if distance > Self.maxTravel, distance > 0 {
            let scale = Self.maxTravel / distance
            boundedTranslation = CGSize(width: translation.width * scale, height: translation.height * scale)
        } else {
            boundedTranslation = translation
        }

        return CGSize(
            width: boundedTranslation.width / Self.maxTravel,
            height: boundedTranslation.height / Self.maxTravel
        )
    }

    private var remoteGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.4, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($remoteGestureState) { value, state, _ in
                switch value {
                case .first(true):
                    state = .armed
                case .second(true, let drag?):
                    state = .dragging(drag.translation)
                default:
                    state = .inactive
                }
            }
            .onChanged { value in
                guard case .second(true, let drag?) = value else {
                    return
                }

                offset = clampedOffset(for: drag.translation)
            }
    }

    private var backgroundColors: [Color] {
        if remoteGestureState.isActive {
            return [Color.white.opacity(0.12), Color.white.opacity(0.05)]
        }

        return [Color.white.opacity(0.08), Color.white.opacity(0.03)]
    }

    private var borderColor: Color {
        remoteGestureState.isActive ? Color.green.opacity(0.38) : Color.white.opacity(0.1)
    }

    private func triggerActivationFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.75)
    }
}

private enum RemoteGestureState: Equatable {
    case inactive
    case armed
    case dragging(CGSize)

    var isActive: Bool {
        switch self {
        case .inactive:
            return false
        case .armed, .dragging:
            return true
        }
    }
}

private struct USPSATargetShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.1))
        path.addLine(to: CGPoint(x: w, y: h * 0.42))
        path.addLine(to: CGPoint(x: w * 0.82, y: h))
        path.addLine(to: CGPoint(x: w * 0.18, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.42))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.1))
        path.closeSubpath()
        return path
    }
}

private struct USPSAScoringZone: Shape {
    func path(in rect: CGRect) -> Path {
        RoundedRectangle(cornerRadius: rect.width * 0.18, style: .continuous)
            .path(in: rect)
    }
}

#Preview {
    ContentView()
}
