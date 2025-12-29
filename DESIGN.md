# Software Design

## Architecture

```
UI (SwiftUI) → Domain (Pure Swift) → Data (Persistence/Network)
```

### Layers
- **UI**: Views, ViewModels (@Observable/@MainActor), state management
- **Domain**: Models, use cases, business logic (framework-agnostic)
- **Data**: Repositories, persistence, networking, external integrations

### State Management
- Unidirectional flow: View → ViewModel → Domain → Data → ViewModel → View
- **@Observable** (iOS 17+): Modern observation, automatic change tracking
- **ObservableObject** (iOS 13+): Legacy pattern with @Published
- Immutable state objects (struct/enum)
- Single source of truth in ViewModels

### Concurrency
- async/await with structured concurrency
- @MainActor for UI isolation
- Actors for shared mutable state
- Sendable for cross-actor types
- Task cancellation via checkCancellation()

## Core Principles

1. **Minimize Complexity**: Eliminate unnecessary state, avoid nested conditionals
2. **Deep Modules**: Small API hiding rich logic
3. **Pull Complexity Down**: High-level code reads like pseudocode
4. **Single Responsibility**: One purpose per abstraction
5. **Optimize for Reading**: Clarity over brevity
6. **Document Intent**: Comments explain *why*, code shows *how*

## Patterns

### State Modeling
Use enums with associated values, not booleans:

```swift
enum LoadingState<T> {
    case idle
    case loading(progress: Double)
    case loaded(data: T)
    case failed(error: String)
}
```

### Error Handling
Typed errors with LocalizedError:

```swift
enum DataError: LocalizedError {
    case notFound(id: String)
    case unauthorized
    case networkFailure(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notFound(let id): "Resource not found: \(id)"
        case .unauthorized: "Authentication required"
        case .networkFailure(let error): "Network error: \(error.localizedDescription)"
        }
    }
}
```

### Protocol-Oriented Design
Define protocols at boundaries:

```swift
protocol DataFetching: Sendable {
    func fetch(id: String) async throws -> Model
}

protocol Repository: Sendable {
    func save(_ item: Model) async throws
    func fetch(id: String) async throws -> Model
    func fetchAll() async throws -> [Model]
}
```

### Dependency Injection
Constructor injection for testability:

```swift
@MainActor
@Observable
class ItemViewModel {
    private let repository: any Repository

    init(repository: any Repository) {
        self.repository = repository
    }
}
```

### SwiftUI View Composition
Extract subviews, use @ViewBuilder:

```swift
struct ItemListView: View {
    let items: [Item]

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### Identifiable Protocol
Stable IDs for collections:

```swift
struct Item: Identifiable, Sendable {
    let id: UUID
    let name: String
    let createdAt: Date
}
```

### Value vs Reference Semantics
Prefer structs for immutable data, classes only for identity or reference sharing:

```swift
struct Model: Sendable {  // Value type - safe for concurrency
    let id: UUID
    let data: String
}

@MainActor
class ViewModel: ObservableObject {  // Reference type - needs identity
    @Published var state: LoadingState<Model>
}
```

### Retain Cycle Prevention
Use weak for delegates, unowned for guaranteed parent:

```swift
class DataProcessor {
    weak var delegate: ProcessorDelegate?  // Delegate pattern
}

class Node {
    unowned let parent: Node?  // Parent always outlives child
    let children: [Node]
}
```

## Testing

### Structure
Arrange-Act-Assert pattern:

```swift
func testFetchReturnsValidData() async throws {
    // Arrange
    let repository = DataRepository()
    let testId = "test-123"

    // Act
    let result = try await repository.fetch(id: testId)

    // Assert
    XCTAssertEqual(testId, result.id)
}
```

### Async Testing
```swift
func testCancellation() async throws {
    let task = Task {
        try await repository.fetchAll()
    }
    task.cancel()

    do {
        _ = try await task.value
        XCTFail("Should throw CancellationError")
    } catch is CancellationError {
        // Expected
    }
}
```

### Mocking
Protocol-based test doubles:

```swift
final class MockRepository: Repository {
    var fetchResult: Result<Model, Error> = .failure(TestError())

    func fetch(id: String) async throws -> Model {
        try fetchResult.get()
    }

    func save(_ item: Model) async throws {}
    func fetchAll() async throws -> [Model] { [] }
}
```

## Documentation

Use DocC-style comments for public APIs:

```swift
/// Fetches a data item from the repository.
///
/// - Parameter id: Unique identifier for the item
/// - Returns: The requested data model
/// - Throws: `DataError` if not found or unauthorized
func fetch(id: String) async throws -> Model
```

## Refactoring Checklist

- [ ] Single sentence description possible?
- [ ] Magic numbers → named constants?
- [ ] Duplicated logic extracted?
- [ ] Error cases handled gracefully?
- [ ] Code clear to newcomers?
- [ ] Complexity pushed to lower layers?
- [ ] Comments explain *why*?
- [ ] Proper access control (private/internal/public)?
- [ ] Value types where appropriate?
- [ ] Protocol conformance (Sendable, Identifiable, Codable)?
- [ ] Retain cycles avoided (weak/unowned)?
- [ ] Tests passing?
- [ ] Async/await instead of callbacks?
