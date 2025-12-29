---
description: Refactor code following project design principles
allowed-tools: Read, Edit, Glob, Grep, Bash
argument-hint: <file-path-or-description>
---

Target: $ARGUMENTS

Use swift-architect subagent. Apply DESIGN.md principles:
1. Minimize complexity (guard over nested if)
2. Enums for state (not booleans)
3. Extensions for organization
4. Immutability (structs)
5. Result types for expected failures

**Before:** Run tests
**After:** Run tests, verify behavior preserved
