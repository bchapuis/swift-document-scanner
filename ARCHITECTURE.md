# Architecture - Document Scanner

## System Overview

Document Scanner is an iOS application that scans, analyzes, and manages document file trees with size calculations, duplicate detection, and export capabilities.

```
┌─────────────────────────────────────────────────────────┐
│                     UI Layer (SwiftUI)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Scanner    │  │   Browser    │  │   Export     │   │
│  │    View      │  │     View     │  │     View     │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                 │                 │           │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐   │
│  │   Scanner    │  │   Browser    │  │   Export     │   │
│  │  ViewModel   │  │  ViewModel   │  │  ViewModel   │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
└─────────┼─────────────────┼─────────────────┼───────────┘
          │                 │                 │
┌─────────▼─────────────────▼─────────────────▼───────────┐
│                    Domain Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Scanner    │  │   Analyzer   │  │   Exporter   │   │
│  │  Use Cases   │  │  Use Cases   │  │  Use Cases   │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                 │                 │           │
│  ┌──────▼─────────────────▼─────────────────▼─────────┐ │
│  │              Domain Models                         │ │
│  │  FileNode, ScanResult, DuplicateGroup, etc.        │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                    Data Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   File       │  │   Storage    │  │   Export     │   │
│  │ Repository   │  │ Repository   │  │ Repository   │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                 │                 │           │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐   │
│  │ FileManager  │  │  CoreData    │  │ FileSystem   │   │
│  │   (iOS)      │  │   (Local)    │  │   Writer     │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### 1. UI Layer

#### ScannerView
- File/folder selection interface
- Real-time scan progress display
- Permission request handling
- Results visualization

**State:**
```swift
enum ScanState {
    case idle
    case requestingPermission
    case scanning(progress: ScanProgress)
    case complete(result: ScanResult)
    case failed(error: ScanError)
}

struct ScanProgress {
    let currentPath: URL
    let filesScanned: Int
    let bytesProcessed: Int64
    let estimatedTotal: Int?
}
```

#### BrowserView
- Tree navigation (hierarchical file structure)
- Size visualization (charts/graphs)
- Duplicate highlighting
- Sorting/filtering controls

**Features:**
- Expandable tree with lazy loading
- Size heatmap visualization
- Quick actions (reveal in Finder, delete, share)
- Search and filter by name/size/type

#### ExportView
- Format selection (JSON, CSV, HTML)
- Export options configuration
- Preview before export
- Share sheet integration

### 2. Domain Layer

#### Scanner Use Cases

**ScanDirectoryUseCase**
```swift
protocol ScanDirectoryUseCase: Sendable {
    func execute(
        url: URL,
        options: ScanOptions,
        progress: @escaping (ScanProgress) -> Void
    ) async throws -> ScanResult
}
```

**Responsibilities:**
- Traverse directory tree recursively
- Calculate file/folder sizes
- Collect metadata (creation date, modification date, type)
- Handle permissions errors gracefully
- Support cancellation
- Report progress

**ScanOptions:**
```swift
struct ScanOptions: Sendable {
    let includeHidden: Bool
    let followSymlinks: Bool
    let maxDepth: Int?
    let excludePatterns: [String]
    let calculateChecksums: Bool  // For duplicate detection
}
```

#### Analyzer Use Cases

**FindDuplicatesUseCase**
```swift
protocol FindDuplicatesUseCase: Sendable {
    func execute(root: FileNode) async throws -> [DuplicateGroup]
}
```

**Responsibilities:**
- Group files by size first (quick filter)
- Calculate checksums for same-size files
- Group by checksum to find true duplicates
- Return duplicate groups with total wasted space

**AnalyzeSizeDistributionUseCase**
```swift
protocol AnalyzeSizeDistributionUseCase: Sendable {
    func execute(root: FileNode) -> SizeDistribution
}
```

**Responsibilities:**
- Calculate size by file type
- Find largest files/folders
- Generate size percentiles
- Identify size outliers

#### Exporter Use Cases

**ExportScanResultUseCase**
```swift
protocol ExportScanResultUseCase: Sendable {
    func execute(
        result: ScanResult,
        format: ExportFormat,
        destination: URL
    ) async throws
}

enum ExportFormat {
    case json
    case csv
    case html(template: HTMLTemplate)
}
```

### 3. Domain Models

#### FileNode
```swift
struct FileNode: Identifiable, Sendable, Codable {
    let id: UUID
    let path: URL
    let name: String
    let size: Int64
    let isDirectory: Bool
    let createdAt: Date
    let modifiedAt: Date
    let children: [FileNode]

    // Computed
    var totalSize: Int64 {
        isDirectory ? children.reduce(size) { $0 + $1.totalSize } : size
    }

    var fileCount: Int {
        isDirectory ? children.reduce(0) { $0 + $1.fileCount } : 1
    }

    var fileType: FileType {
        FileType(from: path.pathExtension)
    }
}
```

#### ScanResult
```swift
struct ScanResult: Identifiable, Sendable, Codable {
    let id: UUID
    let rootNode: FileNode
    let scannedAt: Date
    let options: ScanOptions
    let statistics: ScanStatistics
}

struct ScanStatistics: Sendable, Codable {
    let totalFiles: Int
    let totalDirectories: Int
    let totalSize: Int64
    let largestFile: FileNode?
    let scanDuration: TimeInterval
    let errorsEncountered: [ScanError]
}
```

#### DuplicateGroup
```swift
struct DuplicateGroup: Identifiable, Sendable {
    let id: UUID
    let checksum: String
    let files: [FileNode]

    var wastedSpace: Int64 {
        files.dropFirst().reduce(0) { $0 + $1.size }
    }

    var originalFile: FileNode { files[0] }
    var duplicates: [FileNode] { Array(files.dropFirst()) }
}
```

### 4. Data Layer

#### FileRepository
```swift
protocol FileRepository: Sendable {
    /// Scan directory tree with progress reporting
    func scan(
        url: URL,
        options: ScanOptions,
        progress: @escaping @Sendable (ScanProgress) -> Void
    ) async throws -> FileNode

    /// Check if path is accessible
    func checkAccess(url: URL) async throws -> Bool

    /// Request permissions for path
    func requestAccess(url: URL) async throws
}
```

**Implementation:**
- Uses FileManager for file system operations
- Handles bookmark-based security-scoped resources
- Implements efficient traversal with actor isolation
- Supports cancellation via Task.checkCancellation()

#### StorageRepository
```swift
protocol StorageRepository: Sendable {
    /// Save scan result locally
    func save(_ result: ScanResult) async throws

    /// Load recent scan results
    func fetchRecent(limit: Int) async throws -> [ScanResult]

    /// Delete scan result
    func delete(id: UUID) async throws

    /// Export to specific format
    func export(
        _ result: ScanResult,
        format: ExportFormat,
        destination: URL
    ) async throws
}
```

**Implementation:**
- CoreData for persistent storage
- JSON encoder/decoder for serialization
- File handle for large exports
- Background context for database operations

## Data Flow

### Scan Flow
```
1. User selects folder → ScannerView
2. ScannerView triggers ScannerViewModel.startScan(url)
3. ScannerViewModel calls ScanDirectoryUseCase.execute()
4. Use case delegates to FileRepository.scan()
5. FileRepository traverses filesystem, reports progress
6. Progress callbacks update ScannerViewModel state
7. State changes trigger UI updates
8. Completion updates ScanState.complete(result)
9. Result saved via StorageRepository.save()
10. Navigate to BrowserView with result
```

### Analysis Flow
```
1. User opens scan result → BrowserView
2. BrowserViewModel loads result from StorageRepository
3. User requests duplicate analysis
4. BrowserViewModel calls FindDuplicatesUseCase.execute()
5. Use case processes FileNode tree
6. Results displayed in BrowserView
7. User can select duplicates for deletion
```

### Export Flow
```
1. User selects export → ExportView
2. User chooses format (JSON/CSV/HTML)
3. ExportViewModel calls ExportScanResultUseCase.execute()
4. Use case delegates to StorageRepository.export()
5. Repository writes to selected destination
6. Share sheet presented with file
```

## Concurrency Model

### Actor Isolation

**FileScanner Actor**
```swift
actor FileScanner: FileRepository {
    private let fileManager = FileManager.default
    private var isCancelled = false

    func scan(
        url: URL,
        options: ScanOptions,
        progress: @escaping @Sendable (ScanProgress) -> Void
    ) async throws -> FileNode {
        try Task.checkCancellation()
        // Scanning logic with periodic progress callbacks
    }

    func cancel() {
        isCancelled = true
    }
}
```

**@MainActor ViewModels**
All ViewModels are @MainActor-isolated to ensure UI updates happen on main thread.

### Background Processing
- File scanning runs on background Task
- Progress updates dispatched to @MainActor
- Long-running operations support cancellation
- Database operations use background contexts

## Performance Considerations

### Lazy Loading
- BrowserView loads tree nodes on-demand
- Children only loaded when parent expanded
- Prevents loading entire tree into memory

### Streaming
- Large exports written in chunks
- FileHandle used for streaming writes
- Memory-efficient for large scan results

### Caching
- Size calculations cached in FileNode
- Checksum results cached during duplicate detection
- Recent scans cached in memory

### Batch Processing
- File operations batched to reduce syscalls
- Database saves batched for efficiency
- Progress updates throttled (max 10/sec)

## Security & Privacy

### Permissions
- Request file access via NSOpenPanel (macOS) / UIDocumentPickerViewController (iOS)
- Store security-scoped bookmarks for re-access
- Handle permission denial gracefully

### Data Protection
- No data sent to external servers
- All storage local (CoreData)
- Exports respect file system permissions

### Error Handling
```swift
enum ScanError: LocalizedError {
    case permissionDenied(path: URL)
    case pathNotFound(path: URL)
    case pathNotAccessible(path: URL)
    case scanCancelled
    case unexpectedError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let path):
            "Permission denied: \(path.lastPathComponent)"
        case .pathNotFound(let path):
            "Path not found: \(path.lastPathComponent)"
        case .pathNotAccessible(let path):
            "Cannot access: \(path.lastPathComponent)"
        case .scanCancelled:
            "Scan cancelled by user"
        case .unexpectedError(let error):
            "Unexpected error: \(error.localizedDescription)"
        }
    }
}
```

## Testing Strategy

### Unit Tests
- Domain models (FileNode, ScanResult)
- Use cases with mock repositories
- ViewModels with mock use cases

### Integration Tests
- FileRepository with temp directories
- StorageRepository with in-memory CoreData
- End-to-end scan → save → load

### UI Tests
- Scanner flow (select → scan → view)
- Browser navigation
- Export functionality

### Performance Tests
- Large directory scanning (10k+ files)
- Memory usage during scan
- Export performance for large results

## Extension Points

### Plugin System
Future support for:
- Custom analyzers (e.g., image analysis, code metrics)
- Custom export formats
- Custom visualizations

### Sharing Extensions
- Share extension for quick scans
- Document provider extension for access from other apps
