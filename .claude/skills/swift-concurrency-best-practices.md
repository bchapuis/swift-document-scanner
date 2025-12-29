---
name: swift-concurrency-best-practices
description: Auto-invoked for Swift concurrency (async/await, actors, tasks).
allowed-tools: Read, Edit, Glob, Grep
---

## Patterns

**Async Network I/O:**
```swift
func fetchItems() async throws -> [Item] {
    let (data, _) = try await URLSession.shared.data(from: url)
    let items = try JSONDecoder().decode([Item].self, from: data)

    try Task.checkCancellation()

    return items
}
```

**Actors for Shared State:**
```swift
actor DataCache {
    private var itemsCount: Int = 0

    func updateCount(_ count: Int) {
        itemsCount += count
    }

    func getCount() -> Int {
        itemsCount
    }
}
```

**@MainActor for UI:**
```swift
@MainActor
@Observable
class FeedViewModel {
    var state: LoadingState<[Item]> = .idle

    func loadFeed() {
        Task {
            state = .loading
            do {
                let items = try await repository.fetchItems()
                state = .loaded(items)
            } catch {
                state = .failed(error)
            }
        }
    }
}
```

**Cancellation:**
```swift
func fetchAllItems() async throws -> [Item] {
    var results: [Item] = []
    let pages = 1...10

    for page in pages {
        try Task.checkCancellation()  // Respect cancellation
        let items = try await fetchPage(page)
        results.append(contentsOf: items)
    }

    return results
}
```

**Progress with AsyncStream:**
```swift
func downloadWithProgress(url: URL) -> AsyncStream<DownloadProgress> {
    AsyncStream { continuation in
        Task {
            let (bytes, response) = try await URLSession.shared.bytes(from: url)
            let totalBytes = response.expectedContentLength

            var downloadedBytes: Int64 = 0
            for try await byte in bytes {
                downloadedBytes += 1

                if downloadedBytes % 1024 == 0 {
                    let progress = Double(downloadedBytes) / Double(totalBytes)
                    continuation.yield(DownloadProgress(progress: progress))
                }
            }
            continuation.finish()
        }
    }
}
```

**TaskGroup for Parallelism:**
```swift
func fetchMultipleResources(urls: [URL]) async throws -> [Data] {
    try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask { try await fetchData(from: url) }
        }

        var results: [Data] = []
        for try await data in group {
            results.append(data)
        }
        return results
    }
}
```

**Sendable Types:**
```swift
struct FetchResult: Sendable {
    let items: [Item]
    let timestamp: Date
    let page: Int
}

protocol DataRepository: Sendable {
    func fetchItems() async throws -> [Item]
}
```

## Anti-Patterns

❌ **Don't mix DispatchQueue with async/await:**
```swift
// Bad
DispatchQueue.global().async {
    await fetchItems()
}

// Good
Task {
    await fetchItems()
}
```

❌ **Don't forget @MainActor for UI:**
```swift
// Bad - can crash
class ViewModel: ObservableObject {
    @Published var state: State

    func update() async {
        state = .loading  // Might be on background thread!
    }
}

// Good - guaranteed main thread
@MainActor
class ViewModel: ObservableObject {
    @Published var state: State

    func update() async {
        state = .loading  // Always on main thread
    }
}
```

## Checklist

- [ ] async/await for I/O
- [ ] Actors for shared mutable state
- [ ] @MainActor for UI
- [ ] Task.checkCancellation() in loops
- [ ] Sendable conformance for cross-actor types
- [ ] TaskGroup for parallelism
- [ ] Enable -strict-concurrency=complete
