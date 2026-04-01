# Where2Aim

Where2Aim is an iOS SwiftUI app for shooters using a red dot sight who want a faster way to decide where to hold at common distances. Instead of only showing raw drop values, the app turns a basic ballistic estimate into a visual aiming recommendation and includes two companion tools: a field distance map and a live scope-style overlay.

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

## Tech Stack

- `SwiftUI` for the UI
- `MapKit` and `CoreLocation` for target placement and distance measurement
- `AVFoundation` for the live camera preview
- A lightweight custom ballistic model in [`/Users/qianzehao/Where2Aim/Where2Aim/Ballistics.swift`](/Users/qianzehao/Where2Aim/Where2Aim/Ballistics.swift)

## Project Structure

- [`/Users/qianzehao/Where2Aim/Where2Aim/ContentView.swift`](/Users/qianzehao/Where2Aim/Where2Aim/ContentView.swift): app shell and aiming recommendation UI
- [`/Users/qianzehao/Where2Aim/Where2Aim/Ballistics.swift`](/Users/qianzehao/Where2Aim/Where2Aim/Ballistics.swift): ballistic input presets and impact/hold calculations
- [`/Users/qianzehao/Where2Aim/Where2Aim/MapView.swift`](/Users/qianzehao/Where2Aim/Where2Aim/MapView.swift): location-enabled map and distance measurement workflow
- [`/Users/qianzehao/Where2Aim/Where2Aim/CameraScopeView.swift`](/Users/qianzehao/Where2Aim/Where2Aim/CameraScopeView.swift): camera-backed scope overlay
- [`/Users/qianzehao/Where2Aim/Where2Aim/Where2AimApp.swift`](/Users/qianzehao/Where2Aim/Where2Aim/Where2AimApp.swift): app entry point

## Running Locally

1. Open [`/Users/qianzehao/Where2Aim/Where2Aim.xcodeproj`](/Users/qianzehao/Where2Aim/Where2Aim.xcodeproj) in Xcode.
2. Select an iPhone simulator or a connected device.
3. Build and run the `Where2Aim` target.
4. Grant location access for the `Map` tab and camera access for the `Scope` tab when prompted.

## How Aiming Recommendations Work

The aiming recommendation uses:

- target distance in yards
- optic height in inches
- zero distance in yards

The app estimates bullet drop using a simplified gravity-based model with a fixed muzzle velocity, then computes:

- `impact offset`: where the round is expected to land relative to the point of aim
- `hold offset`: how far the shooter should hold to compensate

This is intentionally lightweight and fast for field reference, not a full external ballistics solver.

## Current Presets

- Target distance: `50`, `100`, `150`, `200`, `250`, `300` yards
- Optic height: `1.54`, `1.70`, `1.93`, `2.04`, `2.26`, `2.33` inches
- Zero distance: `10`, `15`, `20`, `25`, `30` yards

## Permissions

The app requests:

- camera access for the `Scope` tab
- location access for the `Map` tab

## Limitations

- The ballistic model is simplified and does not account for drag, ammunition differences, wind, temperature, altitude, or sight adjustments.
- The `Scope` tab is a visual aid only and does not calibrate against a real optic.
- Map-based distance estimates depend on GPS accuracy and the precision of the tapped target point.

## Roadmap Ideas

- richer ballistic inputs such as ammo profile and muzzle velocity
- improved target visualization with explicit hold zones
- saved rifle/optic profiles
- calibration options for the scope overlay
- exportable setup presets

## License

No license file is currently included in this repository.
