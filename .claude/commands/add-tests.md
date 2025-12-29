---
description: Add comprehensive tests for a component or feature
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: <component-or-file-path>
---

Target: $ARGUMENTS

Use test-engineer subagent. Follow DESIGN.md testing:

**Structure:** Arrange-Act-Assert
**Coverage:**
- Happy path
- Edge cases (empty, nil, boundaries)
- Error handling
- Concurrency (cancellation, async)

**Frameworks:** XCTest, Swift Testing (5.9+), protocol-based mocking

Run: `xcodebuild test -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 15 Pro'`
