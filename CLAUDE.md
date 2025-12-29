# CLAUDE.md

Quick reference for Claude Code.

## Commands

```bash
# Clean, Build & Run (use /run slash command)
xcodebuild clean && rm -rf ~/Library/Developer/Xcode/DerivedData && xcodebuild -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build && xcrun simctl boot "iPhone 15 Pro" && xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/<AppName>-*/Build/Products/Debug-iphonesimulator/<AppName>.app && xcrun simctl launch booted <bundle-id>

# Build (Debug)
xcodebuild -scheme <AppName> -sdk iphonesimulator -configuration Debug build

# Build (Release)
xcodebuild -scheme <AppName> -sdk iphoneos -configuration Release build

# Test
xcodebuild test -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
swift test

# Clean
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData

# Archive & Export
xcodebuild archive -scheme <AppName> -sdk iphoneos -archivePath ./build/<AppName>.xcarchive
xcodebuild -exportArchive -archivePath ./build/<AppName>.xcarchive -exportPath ./build/Release -exportOptionsPlist ExportOptions.plist

# Code Sign & Upload
codesign --verify --verbose ./build/Release/<AppName>.app
xcrun altool --upload-app --type ios --file ./build/Release/<AppName>.ipa --username "email" --password "@keychain:AC_PASSWORD"

# Lint
swiftlint lint
swiftlint --fix

# DocC
xcodebuild docbuild -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Profile
instruments -t "Time Profiler" -w "iPhone 15 Pro" <AppName>
instruments -t "Allocations" -w "iPhone 15 Pro" <AppName>

# Simulator Management
xcrun simctl list devices available
xcrun simctl boot "iPhone 15 Pro"
xcrun simctl shutdown all
```

## Tech Stack

- Swift 5.9+, SwiftUI, iOS 17+
- Xcode 15+, Swift Concurrency (async/await, actors)
- Universal binary (ARM64)

## Structure

```
<AppName>/
├── <AppName>.xcodeproj
├── <AppName>/
│   ├── App.swift              # @main
│   ├── Info.plist
│   ├── <AppName>.entitlements
│   ├── Domain/                # Models, use cases
│   ├── Data/                  # Persistence, networking
│   └── UI/                    # SwiftUI views
└── Tests/
```

## Key Files

**Info.plist**: Bundle ID, permissions, minimum iOS version
**Entitlements**: Capabilities (push notifications, iCloud, etc.)
**ExportOptions.plist**: Distribution config (App Store, Ad Hoc, Enterprise)

## Xcode Shortcuts

- **Cmd+B**: Build | **Cmd+R**: Run | **Cmd+U**: Test
- **Cmd+Shift+K**: Clean | **Cmd+Shift+O**: Open Quickly
- **Cmd+I**: Profile | **Cmd+Option+P**: Resume Preview

## Documentation

- **[REQUIREMENTS.md](REQUIREMENTS.md)**: Feature specifications and acceptance criteria
- **[DESIGN.md](DESIGN.md)**: Generic iOS design patterns, principles, and best practices
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Scanner-specific architecture, components, and data flows
- **[CLAUDE.md](CLAUDE.md)**: Quick reference for commands and project structure (this file)
