---
description: Clean, build, and run the iOS application in simulator
allowed-tools: Bash
---

Clean, build, and run the iOS application in the iPhone simulator.

You should:
1. Detect the scheme name from the .xcodeproj file
2. Clean the project and remove derived data
3. Build the application using xcodebuild for iOS Simulator
4. Boot the simulator (iPhone 15 Pro by default)
5. Install and launch the app
6. Confirm the app has been launched

```bash
# First, detect the scheme name
SCHEME=$(xcodebuild -list -json | grep -A 1 '"schemes"' | tail -1 | sed 's/.*"\(.*\)".*/\1/' | head -1)

# Clean, build, and run
xcodebuild clean && \
rm -rf ~/Library/Developer/Xcode/DerivedData && \
xcodebuild -scheme "$SCHEME" -sdk iphonesimulator -configuration Debug build && \
xcrun simctl boot "iPhone 15 Pro" 2>/dev/null || true && \
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug-iphonesimulator/*.app && \
xcrun simctl launch --console booted $(xcodebuild -scheme "$SCHEME" -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER | awk '{print $3}')
```
