// swift-tools-version: 5.9

// WARNING:
// This is a Swift Playgrounds app package. Edit the app's settings in Swift Playgrounds
// (or Xcode) rather than by hand where possible.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Moonlit Meadows",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .iOSApplication(
            name: "Moonlit Meadows",
            targets: ["AppModule"],
            // Kept from Bunny Meadows so existing progress carries over.
            bundleIdentifier: "com.example.BunnyMeadows",
            teamIdentifier: "",
            displayVersion: "2.0",
            bundleVersion: "2",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.pink),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            exclude: ["README.md", "ART_ASSETS.md", "MenuArt"]
        )
    ]
)
