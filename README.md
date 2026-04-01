# Where2Aim

Where2Aim is an iOS SwiftUI app for shooters using a red dot sight who want a faster way to decide where to hold at common distances. Instead of only showing raw drop values, the app turns a ballistic lookup table into a visual aiming recommendation and includes two companion tools: a field distance map and a live scope-style overlay.

## What The App Does

Where2Aim currently has three tabs:

- `Aim`: choose distance to target, optic height, and zero distance, then get an estimated impact offset and hold recommendation.
- `Map`: use your current location and a tapped target point to estimate field distance in meters, kilometers, and yards.
- `Scope`: show the rear camera feed with a reticle-style overlay for quick visual reference.

## Features

- SwiftUI interface with a three-tab workflow.
- Ballistic recommendation based on target distance, optic height, and zero distance.
- Preset setup values for common distances and riser heights.
- Persistent last-used aiming setup with `UserDefaults`.
- Satellite map view with tap-to-place target measurement.
- Rear-camera overlay with range-reference marks for 50 to 300 yards.

## Requirements

- Xcode 16 or later recommended
- iOS 17.0+
- Swift 5+
- A physical iPhone is recommended for the `Map` and `Scope` tabs because they rely on location services and camera access.

## How Aiming Recommendations Work

The aiming recommendation uses:

- target distance in yards
- optic height in inches
- zero distance in yards

The app uses a baked-in drop table from the provided `.223 Rem 55gr FMJ` dataset, then computes:

- `impact offset`: where the round is expected to land relative to the point of aim
- `hold offset`: how far the shooter should hold to compensate

The current table reflects Federal Premium `.223 Rem 55gr FMJ` data at `3,240 fps` for the supported riser, zero, and target-distance combinations. This is still a fast field-reference tool, not a full external ballistics solver.

## Current Presets

- Target distance: `50`, `100`, `150`, `200`, `250`, `300` yards
- Optic height: `1.42`, `1.57`, `1.93`, `2.26` inches
- Zero distance: `10`, `15`, `20`, `25`, `30` yards

## Permissions

The app requests:

- camera access for the `Scope` tab
- location access for the `Map` tab

## License

This project is licensed under the MIT License.
