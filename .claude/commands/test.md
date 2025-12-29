---
description: Run all tests for the iOS project
allowed-tools: Bash
argument-hint: [test-name]
---

Run tests for the iOS application using the iOS Simulator.

```bash
# Detect scheme name
SCHEME=$(xcodebuild -list -json | grep -A 1 '"schemes"' | tail -1 | sed 's/.*"\(.*\)".*/\1/' | head -1)

# Run all tests (if no arguments provided)
if [ -z "$ARGUMENTS" ]; then
  xcodebuild test -scheme "$SCHEME" -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
else
  # Run specific test
  xcodebuild test -scheme "$SCHEME" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:$ARGUMENTS
fi
```
