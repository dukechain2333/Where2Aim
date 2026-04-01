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
    private static let muzzleVelocityFeetPerSecond = 2900.0
    private static let gravityFeetPerSecondSquared = 32.174

    static func recommendation(for inputs: BallisticsInputs) -> AimingRecommendation {
        let distanceFeet = inputs.distanceToTargetYards * 3.0
        let zeroFeet = max(inputs.zeroDistanceYards * 3.0, 1.0)
        let opticHeightFeet = inputs.opticHeightInches / 12.0

        let zeroDropFeet = drop(atDistanceFeet: zeroFeet)
        let launchSlope = (opticHeightFeet + zeroDropFeet) / zeroFeet

        let impactFeet = (-opticHeightFeet) + (launchSlope * distanceFeet) - drop(atDistanceFeet: distanceFeet)
        let impactInches = impactFeet * 12.0
        let holdInches = -impactInches

        return AimingRecommendation(
            impactOffsetInches: impactInches,
            holdOffsetInches: holdInches
        )
    }

    private static func drop(atDistanceFeet distanceFeet: Double) -> Double {
        let timeSeconds = distanceFeet / muzzleVelocityFeetPerSecond
        return 0.5 * gravityFeetPerSecondSquared * timeSeconds * timeSeconds
    }
}

enum Presets {
    static let distancesYards: [Double] = [50, 100, 150, 200, 250, 300]
    static let opticHeightsInches: [Double] = [1.54, 1.70, 1.93, 2.04, 2.26, 2.33]
    static let zeroDistancesYards: [Double] = [10, 15, 20, 25, 30]
}
