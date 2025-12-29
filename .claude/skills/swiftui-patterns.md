---
name: swiftui-patterns
description: Auto-invoked for SwiftUI components. State management, animations, performance for iOS.
allowed-tools: Read, Edit, Glob, Grep
---

## State Management

**@Observable (iOS 17+):**
```swift
@Observable
class FeedViewModel {
    var items: [Item] = []
    var isLoading = false
}

struct FeedView: View {
    let viewModel: FeedViewModel  // No property wrapper!

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
        }
    }
}
```

**ObservableObject (iOS 16 and earlier):**
```swift
class FeedViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
}

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
}
```

**Environment Injection:**
```swift
@Observable
class AppState {
    var user: User?
    var theme: Theme = .light
}

@main
struct App: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView().environment(appState)
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
}
```

## Performance

**List Optimization:**
```swift
List {
    ForEach(items, id: \.id) { item in
        ItemRow(item: item).equatable()
    }
}

struct ItemRow: View, Equatable {
    let item: Item

    static func == (lhs: ItemRow, rhs: ItemRow) -> Bool {
        lhs.item.id == rhs.item.id
    }
}

// For large lists, use LazyVStack/LazyVGrid
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
    .padding()
}
```

**Animations:**
```swift
@State private var expanded = false

Rectangle()
    .frame(height: expanded ? 300 : 48)
    .animation(.spring(duration: 0.25), value: expanded)
```

**Reduce Motion:**
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

Rectangle()
    .animation(reduceMotion ? .none : .spring(), value: state)
```

## Custom Modifiers

```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
```

## PreferenceKey

```swift
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct ParentView: View {
    @State private var childSize: CGSize = .zero

    var body: some View {
        ChildView()
            .background(GeometryReader { geometry in
                Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
            })
            .onPreferenceChange(SizePreferenceKey.self) { size in
                childSize = size
            }
    }
}
```

## Accessibility

```swift
Button("Delete") { deleteFile() }
    .keyboardShortcut(.delete)
    .accessibilityLabel("Delete selected file")
    .accessibilityHint("Moves file to trash")
    .accessibilityAddTraits(.isDestructive)

@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20
Image(systemName: "doc").frame(width: iconSize, height: iconSize)
```

## iOS Navigation

**NavigationStack (iOS 16+):**
```swift
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
    .navigationTitle("Items")
}
```

**TabView:**
```swift
TabView {
    FeedView()
        .tabItem {
            Label("Feed", systemImage: "house.fill")
        }

    ProfileView()
        .tabItem {
            Label("Profile", systemImage: "person.fill")
        }
}
```

**Sheets & Alerts:**
```swift
struct ContentView: View {
    @State private var showSheet = false
    @State private var showAlert = false

    var body: some View {
        Button("Show Sheet") { showSheet = true }
            .sheet(isPresented: $showSheet) {
                DetailView()
            }
            .alert("Are you sure?", isPresented: $showAlert) {
                Button("Delete", role: .destructive) { deleteItem() }
                Button("Cancel", role: .cancel) {}
            }
    }
}
```

## Checklist

- [ ] @State for view-local state
- [ ] @Observable for ViewModels (iOS 17+)
- [ ] Stable IDs for List and ForEach
- [ ] Lazy stacks for large lists
- [ ] .equatable() for expensive views
- [ ] Respect Reduce Motion
- [ ] VoiceOver labels and hints
- [ ] Dynamic Type support (@ScaledMetric)
- [ ] Touch targets 44x44pt minimum
- [ ] Safe area awareness
