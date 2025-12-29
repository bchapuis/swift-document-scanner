---
description: Implement a feature or component for the iOS app
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: <feature-description>
---

Feature: $ARGUMENTS

1. Understand the feature requirements
2. Design the architecture (use swift-architect)
3. Implement the feature following iOS best practices
4. Write comprehensive tests (XCTest, Swift Testing)
5. Run tests: `xcodebuild test -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 15 Pro'`
6. Polish UI/UX (use ui-polish)
7. Build: `xcodebuild build -scheme <AppName> -sdk iphonesimulator`

Use subagents: swift-architect, test-engineer, performance-optimizer, ui-polish
