import Foundation

struct BallisticsInputs: Equatable {
    let distanceToTargetYards: Double
    let opticHeightInches: Double
    let zeroDistanceYards: Double
}

struct AimingRecommendation {
    let impactOffsetInches: Double
    let holdOffsetInches: Double
}

enum BallisticsModel {
    private static let trajectoryData: [Double: [Double: [Double: Double]]] = [
        1.42: [
            10.0: [50.0: 5.3, 100.0: 11.2, 150.0: 15.9, 200.0: 19.5, 250.0: 21.7, 300.0: 22.4],
            15.0: [50.0: 3.0, 100.0: 6.5, 150.0: 8.9, 200.0: 10.2, 250.0: 10.1, 300.0: 8.4],
            20.0: [50.0: 1.9, 100.0: 4.2, 150.0: 5.5, 200.0: 5.6, 250.0: 4.4, 300.0: 1.6],
            25.0: [50.0: 1.2, 100.0: 2.9, 150.0: 3.5, 200.0: 3.0, 250.0: 1.1, 300.0: -2.4],
            30.0: [50.0: 0.8, 100.0: 2.0, 150.0: 2.2, 200.0: 1.2, 250.0: -1.1, 300.0: -5.0],
        ],
        1.57: [
            10.0: [50.0: 5.9, 100.0: 12.5, 150.0: 18.0, 200.0: 22.3, 250.0: 25.3, 300.0: 26.7],
            15.0: [50.0: 3.4, 100.0: 7.4, 150.0: 10.3, 200.0: 12.0, 250.0: 12.5, 300.0: 11.3],
            20.0: [50.0: 2.1, 100.0: 4.8, 150.0: 6.5, 200.0: 7.0, 250.0: 6.1, 300.0: 3.7],
            25.0: [50.0: 1.4, 100.0: 3.3, 150.0: 4.3, 200.0: 4.0, 250.0: 2.4, 300.0: -0.7],
            30.0: [50.0: 0.9, 100.0: 2.4, 150.0: 2.8, 200.0: 2.1, 250.0: 0.0, 300.0: -3.6],
        ],
        1.93: [
            10.0: [50.0: 7.4, 100.0: 15.7, 150.0: 23.1, 200.0: 29.2, 250.0: 34.0, 300.0: 37.2],
            15.0: [50.0: 4.2, 100.0: 9.4, 150.0: 13.5, 200.0: 16.5, 250.0: 18.1, 300.0: 18.1],
            20.0: [50.0: 2.6, 100.0: 6.3, 150.0: 8.8, 200.0: 10.2, 250.0: 10.3, 300.0: 8.7],
            25.0: [50.0: 1.7, 100.0: 4.4, 150.0: 6.1, 200.0: 6.5, 250.0: 5.7, 300.0: 3.2],
            30.0: [50.0: 1.1, 100.0: 3.2, 150.0: 4.3, 200.0: 4.1, 250.0: 2.7, 300.0: -0.4],
        ],
        2.26: [
            10.0: [50.0: 8.7, 100.0: 18.7, 150.0: 27.7, 200.0: 35.5, 250.0: 41.9, 300.0: 46.8],
            15.0: [50.0: 5.0, 100.0: 11.3, 150.0: 16.5, 200.0: 20.6, 250.0: 23.3, 300.0: 24.4],
            20.0: [50.0: 3.1, 100.0: 7.6, 150.0: 11.0, 200.0: 13.2, 250.0: 14.1, 300.0: 13.4],
            25.0: [50.0: 2.0, 100.0: 5.4, 150.0: 7.7, 200.0: 8.8, 250.0: 8.6, 300.0: 6.8],
            30.0: [50.0: 1.3, 100.0: 4.0, 150.0: 5.6, 200.0: 6.0, 250.0: 5.1, 300.0: 2.6],
        ],
    ]

    static func recommendation(for inputs: BallisticsInputs) -> AimingRecommendation {
        let opticHeight = Presets.closest(inputs.opticHeightInches, in: Presets.opticHeightsInches)
        let zeroDistance = Presets.closest(inputs.zeroDistanceYards, in: Presets.zeroDistancesYards)
        let targetDistance = Presets.closest(inputs.distanceToTargetYards, in: Presets.distancesYards)
        let impactInches = trajectoryData[opticHeight]?[zeroDistance]?[targetDistance] ?? 0.0

        return AimingRecommendation(
            impactOffsetInches: impactInches,
            holdOffsetInches: -impactInches
        )
    }
}

enum Presets {
    static let distancesYards: [Double] = [50, 100, 150, 200, 250, 300]
    static let opticHeightsInches: [Double] = [1.42, 1.57, 1.93, 2.26]
    static let zeroDistancesYards: [Double] = [10, 15, 20, 25, 30]

    static func normalizedSetup(
        distanceToTarget: Double,
        opticHeight: Double,
        zeroDistance: Double
    ) -> (distanceToTarget: Double, opticHeight: Double, zeroDistance: Double) {
        (
            distanceToTarget: closest(distanceToTarget, in: distancesYards),
            opticHeight: closest(opticHeight, in: opticHeightsInches),
            zeroDistance: closest(zeroDistance, in: zeroDistancesYards)
        )
    }

    static func closest(_ value: Double, in options: [Double]) -> Double {
        options.min { abs($0 - value) < abs($1 - value) } ?? value
    }
}
