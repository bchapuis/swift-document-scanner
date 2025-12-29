---
name: swift-refactoring
description: Auto-invoked for refactoring Swift code. Applies project design principles.
allowed-tools: Read, Edit, Glob, Grep
---

## Principles

1. Minimize complexity: guard over nested if
2. Enums for state: not booleans
3. Extensions for organization
4. Immutability: prefer structs
5. Result types for expected failures

## Patterns

**Guard Statements:**
```swift
// Before
if FileManager.default.fileExists(atPath: url.path) {
    if FileManager.default.isReadableFile(atPath: url.path) {
        return readFile(at: url)
    }
}

// After
guard FileManager.default.fileExists(atPath: url.path) else {
    return .failure(.doesNotExist)
}
guard FileManager.default.isReadableFile(atPath: url.path) else {
    return .failure(.permissionDenied)
}
return readFile(at: url)
```

**Enum State:**
```swift
// Before
struct LoadingState {
    var isLoading: Bool
    var data: [Item]?
    var error: String?
}

// After
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}
```

**@Observable Migration:**
```swift
// Before (ObservableObject)
class FeedViewModel: ObservableObject {
    @Published var state: LoadingState<[Item]> = .idle
}

// After (@Observable)
@Observable
class FeedViewModel {
    var state: LoadingState<[Item]> = .idle  // No @Published
}
```

**Actor Isolation:**
```swift
// Before (unsafe)
class DataProcessor {
    var itemsProcessed: Int = 0  // Data race!
}

// After (safe)
actor DataProcessor {
    private var itemsProcessed: Int = 0
    func getProgress() -> Int { itemsProcessed }
}
```

**Sendable Conformance:**
```swift
struct User: Sendable {
    let id: UUID
    let name: String  // Immutable
    let createdAt: Date
}
```

## Checklist

- [ ] Single sentence description?
- [ ] Magic numbers → constants?
- [ ] Duplicated logic extracted?
- [ ] Error cases handled?
- [ ] Code clear to newcomers?
- [ ] Tests passing?
