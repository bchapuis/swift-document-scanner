---
name: xcode-swift-build
description: Auto-invoked for building, testing, packaging iOS Swift/Xcode projects.
allowed-tools: Bash, Read, Edit
---

## Commands

```bash
# Build for Simulator
xcodebuild -scheme <AppName> -sdk iphonesimulator -configuration Debug build

# Build for Device
xcodebuild -scheme <AppName> -sdk iphoneos -configuration Release build

# Test
xcodebuild test -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
xcodebuild test -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:<AppName>Tests/UserTests

# Clean
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData

# Archive (for App Store or TestFlight)
xcodebuild archive -scheme <AppName> -sdk iphoneos -archivePath ./build/<AppName>.xcarchive

# Export Archive
xcodebuild -exportArchive -archivePath ./build/<AppName>.xcarchive \
  -exportPath ./build/Release -exportOptionsPlist ExportOptions.plist

# List available simulators
xcrun simctl list devices available

# Boot simulator
xcrun simctl boot "iPhone 15 Pro"

# Install app on simulator
xcrun simctl install booted /path/to/App.app

# Launch app on simulator
xcrun simctl launch booted com.example.bundleid
```

## Compiler Flags

```bash
# Enable strict concurrency (Swift 6 ready)
-strict-concurrency=complete
-enable-actor-data-race-checks
-warn-concurrency
```

## Entitlements (iOS)

```xml
<!-- Push Notifications -->
<key>aps-environment</key>
<string>development</string>

<!-- iCloud -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.example.app</string>
</array>

<!-- App Groups -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.example.app</string>
</array>

<!-- Sign in with Apple -->
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

## Troubleshooting

```bash
# View entitlements
codesign -d --entitlements :- build/Release/<AppName>.app

# Verify signature
codesign --verify --verbose build/Release/<AppName>.app

# Clear caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm

# Reset simulator
xcrun simctl erase "iPhone 15 Pro"
xcrun simctl shutdown all

# Check provisioning profiles
security find-identity -v -p codesigning

# View crash logs
xcrun simctl spawn booted log show --predicate 'process == "<AppName>"' --last 1h

# Debug simulator app data
xcrun simctl get_app_container booted com.example.bundleid data
```
