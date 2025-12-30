# Architecture - Document Scanner

## System Overview

Document Scanner is an iOS application that uses VisionKit to scan multi-page documents, performs OCR using Vision framework, generates searchable PDFs with PDFKit, and provides intelligent filename suggestions based on document content.

```
┌─────────────────────────────────────────────────────────┐
│                   UI Layer (SwiftUI)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Welcome    │  │  Processing  │  │   Actions    │   │
│  │    View      │  │     View     │  │    View      │   │
│  └──────┬───────┘  └──────────────┘  └──────┬───────┘   │
│         │                                   │           │
│  ┌──────▼───────────────────────────────────▼───────┐   │
│  │         ScanFlowCoordinator (ViewModel)          │   │
│  │    - State management (@Observable)              │   │
│  │    - Navigation flow (NavigationStack)           │   │
│  │    - Coordinates services                        │   │
│  └──────┬──────────────┬──────────────┬─────────────┘   │
└─────────┼──────────────┼──────────────┼─────────────────┘
          │              │              │
┌─────────▼──────────────▼──────────────▼─────────────────┐
│                   Domain Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  Document    │  │     Page     │  │ ScanSession  │   │
│  │   (Model)    │  │   (Model)    │  │    State     │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │          SavedDocument (Metadata)                │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                    Data Layer (Actors)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  OCRService  │  │  PDFService  │  │ SmartFile-   │   │
│  │              │  │              │  │ nameService  │   │
│  │  (Vision)    │  │  (PDFKit)    │  │ (Heuristics) │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │      DocumentRepository (Persistence)            │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│              iOS System Frameworks                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  VisionKit   │  │    Vision    │  │   PDFKit     │   │
│  │  (Camera)    │  │    (OCR)     │  │   (PDF)      │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ FileManager  │  │ UserDefaults │  │UIActivity-   │   │
│  │ (Storage)    │  │ (Metadata)   │  │ViewController│   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### 1. UI Layer

#### ScanFlowCoordinator
- Central coordinator managing entire scan-to-save workflow
- Uses `@Observable` for reactive state management
- NavigationStack-based navigation with typed destinations
- Coordinates all services (OCR, PDF, Repository)

**State Management:**
```swift
@Observable
final class HomeViewModel {
    var state: ScanSessionState = .idle
    var currentDocument: Document?
    var currentPDFData: Data?
    var suggestedFilename: String = ""
    var savedDocumentId: UUID?  // Auto-saved document
}

enum ScanSessionState {
    case idle
    case scanning
    case processing
    case completed(Document)
    case failed(ScanError)
}
```

**Navigation Flow:**
```
Welcome → Camera Scanner → Processing → Actions
   ↓          ↓                ↓           ↓
  Idle    Scanning        Processing   Completed
                                           ↓
                                     (Auto-saved)
```

#### WelcomeView
- Entry point with "Scan Document" button
- Navigation to HistoryView (past scans)
- Clean, minimal interface
- VoiceOver labels and hints

#### ProcessingView
- OCR and PDF generation progress
- Animated processing indicator
- Automatic transition to actions on completion

#### ScannedDocumentActionsView
- Primary: Save to Files (export to user location)
- Secondary: Edit Name, Edit Pages, Share
- Sheet-based filename editor
- PDF preview/editing integration

#### HistoryView
- Lists all saved documents (newest first)
- Swipe-to-delete with confirmation
- Navigation to SavedDocumentActionsView
- Empty state with helpful message

#### Supporting Views
- **CameraScannerView**: UIViewControllerRepresentable wrapping VNDocumentCameraViewController
- **FileSaveView**: UIDocumentPickerViewController for exporting PDFs
- **FilenameEditorView**: Sheet-based filename editing
- **PDFEditorView**: PDF preview with PDFView
- **DesignSystem**: Centralized colors, typography, spacing, button styles

### 2. Domain Layer

#### Document
```swift
struct Document: Identifiable, Sendable {
    let id: UUID
    var pages: [Page]
    let createdAt: Date

    var fullText: String {
        pages.compactMap(\.extractedText).joined(separator: "\n")
    }

    var pageCount: Int { pages.count }
}
```

**Responsibilities:**
- Aggregate multiple scanned pages
- Combine OCR text from all pages
- Track page count for metadata

#### Page
```swift
struct Page: Identifiable, Sendable {
    let id: UUID
    let image: UIImage
    let scannedAt: Date
    var extractedText: String?  // Populated after OCR
}
```

**Responsibilities:**
- Represent single scanned page
- Store image and metadata
- Hold OCR-extracted text (async populated)

#### SavedDocument
```swift
struct SavedDocument: Identifiable, Codable, Sendable {
    let id: UUID
    let internalFilename: String  // "20241229-143052.pdf"
    var displayName: String        // "2025-12-29 Invoice.pdf" (editable)
    let fileURL: URL
    let createdAt: Date
    let pageCount: Int
}
```

**Responsibilities:**
- Metadata for saved PDFs
- Separate internal filename (timestamp) from user-facing name
- Enable renaming without file system changes
- Codable for UserDefaults persistence

#### ScanError
```swift
enum ScanError: LocalizedError, Sendable {
    case cameraPermissionDenied
    case cameraUnavailable
    case scanCancelled
    case ocrFailed(underlying: Error?)
    case pdfGenerationFailed(underlying: Error?)
    case saveFailed(underlying: Error?)
    case unknown(underlying: Error?)
}
```

### 3. Data Layer (Services)

#### OCRService (Actor)
```swift
actor OCRService {
    func recognizeText(from image: UIImage) async throws -> String
    func recognizeText(from pages: [Page]) async throws -> [String]
}
```

**Responsibilities:**
- Perform OCR using Vision framework (VNRecognizeTextRequest)
- Concurrent processing of multiple pages (TaskGroup)
- Language support: English, Spanish, French
- Recognition level: `.accurate` for best quality
- Error handling with graceful degradation

**Implementation Details:**
- Uses VNImageRequestHandler with CGImage
- Extracts top candidates from VNRecognizedTextObservation
- Processes pages concurrently while maintaining order
- Thread-safe via actor isolation

#### PDFService (Actor)
```swift
actor PDFService {
    func generatePDF(from pages: [Page], withOCRTexts: [String]) async throws -> Data
    func generateSmartFilename(from ocrText: String) async -> String
}
```

**Responsibilities:**
- Generate PDF documents with PDFKit
- Embed OCR text as invisible searchable layer
- Delegate smart filename generation to SmartFilenameService
- Preserve image quality and dimensions

**PDF Generation Process:**
1. Create PDFDocument
2. For each page:
   - Draw UIImage in PDF context
   - Add invisible text layer (setTextDrawingMode(.invisible))
   - Insert page into document
3. Return PDF data

#### SmartFilenameService (Actor)
```swift
actor SmartFilenameService {
    func generateFilename(from text: String) async -> String
}
```

**Responsibilities:**
- Extract meaningful information from OCR text
- Generate filename: "YYYY-MM-DD [Company] [DocType] [RefNum].pdf"
- Fallback to "YYYY-MM-DD Scan.pdf" if no info found
- Sanitize invalid filename characters

**Extraction Strategies:**
1. **Company Name Extraction:**
   - Legal suffixes (Inc, LLC, SA, GmbH, etc.)
   - All-caps headers (logo/company name)
   - Title Case in first 3 lines

2. **Document Type Detection:**
   - Priority-based keyword matching
   - Types: Invoice, Receipt, Statement, Contract, Certificate, Letter, Report, Form
   - Multilingual keywords (EN, FR)

3. **Date Extraction:**
   - ISO format: 2025-08-28
   - European: 28.08.2025, 28/08/2025
   - French: "28 août 2025"
   - English: "August 28, 2025"
   - Normalize to YYYY-MM-DD

4. **Reference Number Extraction:**
   - Invoice #, Receipt No., Ref: patterns
   - Alphanumeric codes (INV-2024-001)
   - Only for Invoice, Receipt, Statement, Contract types

**Design Decision: Heuristics vs. BERT**
- Chose pattern matching over Core ML BERT model to avoid:
  - 40-60 MB model size
  - ~500ms-1s inference latency
  - Unpredictable ML behavior
- Heuristics provide: instant results, predictable output, zero dependencies

#### DocumentRepository (Actor)
```swift
actor DocumentRepository {
    func save(pdfData: Data, displayName: String, pageCount: Int) throws -> SavedDocument
    func fetchAll() -> [SavedDocument]
    func delete(id: UUID) throws
    func updateDisplayName(id: UUID, newDisplayName: String) throws
}
```

**Responsibilities:**
- Persist PDFs to Documents directory
- Store metadata in UserDefaults (JSON)
- Manage document lifecycle (CRUD operations)
- Thread-safe file system operations

**Storage Strategy:**
- **PDFs:** Documents directory with timestamp filename (immutable)
- **Metadata:** UserDefaults with JSON encoding (fast, lightweight)
- **Filenames:** Internal (timestamp) vs. display (user-editable) separation
- **Cleanup:** Filter missing files on fetch

### 4. Native Framework Integration

#### VisionKit (Camera Scanner)
```swift
struct CameraScannerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController
}
```

**Integration:**
- VNDocumentCameraViewController for native scanning
- Automatic edge detection and perspective correction
- Multi-page capture with built-in UI
- Returns array of VNDocumentCameraScan results
- Convert to Page models with UIImage

**Camera Flow:**
1. Check `VNDocumentCameraViewController.isSupported`
2. Present modally via `.sheet`
3. User scans pages (camera handles detection)
4. Delegate callback with scan results
5. Convert to Document model
6. Dismiss and start processing

#### Vision Framework (OCR)
```swift
let request = VNRecognizeTextRequest { request, error in
    let observations = request.results as? [VNRecognizedTextObservation]
    // Extract text...
}
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
request.recognitionLanguages = ["en-US", "es-ES", "fr-FR"]
```

**Integration:**
- VNRecognizeTextRequest with `.accurate` level
- Multi-language support (EN, ES, FR)
- Continuation-based async/await wrapping
- Concurrent page processing with TaskGroup

#### PDFKit (PDF Generation)
```swift
UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
UIGraphicsBeginPDFPage()
image.draw(in: pageRect)
context.setTextDrawingMode(.invisible)
(text as NSString).draw(in: textRect, withAttributes: textAttributes)
UIGraphicsEndPDFContext()
```

**Integration:**
- UIGraphics PDF context for page creation
- Draw image at full resolution
- Invisible text layer for searchability
- PDFDocument for multi-page assembly

## Data Flow

### Complete Scan-to-Save Flow
```
1. User taps "Scan Document" → WelcomeView
2. HomeViewModel.startScanning()
3. Check VNDocumentCameraViewController.isSupported
4. Present CameraScannerView (sheet)
5. User scans pages via VisionKit
6. CameraScannerCoordinator receives scan results
7. Convert VNDocumentCameraScan → Document (with Pages)
8. Dismiss scanner, navigate to ProcessingView
9. HomeViewModel.processDocument() starts
   ├─ OCRService.recognizeText() (concurrent TaskGroup)
   ├─ Update Document with extracted text
   ├─ PDFService.generatePDF() with embedded text layer
   ├─ SmartFilenameService.generateFilename() from OCR text
   └─ DocumentRepository.save() (auto-save)
10. Navigate to ScannedDocumentActionsView
11. User can:
    ├─ Edit Name → FilenameEditorView → Update repository
    ├─ Edit Pages → PDFEditorView → Update PDF data
    ├─ Share → UIActivityViewController
    └─ Save to Files → UIDocumentPickerViewController
12. Return to WelcomeView
```

### History Flow
```
1. User taps "View Past Scans" → HistoryView
2. HistoryViewModel.loadDocuments()
3. DocumentRepository.fetchAll()
4. Display list of SavedDocuments
5. User taps document → SavedDocumentActionsView
6. User can:
   ├─ Open PDF → PDFEditorView (read-only)
   ├─ Share → UIActivityViewController
   └─ Swipe to delete → DocumentRepository.delete()
```

## Concurrency Model

### Actor Isolation
All services are actors for thread-safe operations:
- **OCRService**: Concurrent page processing
- **PDFService**: PDF generation on background
- **SmartFilenameService**: Heuristic text analysis
- **DocumentRepository**: File system operations

### @MainActor ViewModels
- **HomeViewModel**: UI state updates on main thread
- **HistoryViewModel**: Document list updates on main thread

### Async/await Flow
```swift
// In HomeViewModel
func processDocument(_ document: Document) async {
    state = .processing

    // Concurrent OCR
    let ocrTexts = try await ocrService.recognizeText(from: document.pages)

    // PDF generation
    let pdfData = try await pdfService.generatePDF(from: pages, withOCRTexts: ocrTexts)

    // Smart filename
    let filename = await pdfService.generateSmartFilename(from: document.fullText)

    // Auto-save
    let savedDoc = try await documentRepository.save(pdfData: pdfData, ...)

    state = .completed(document)
}
```

### TaskGroup for Concurrent OCR
```swift
try await withThrowingTaskGroup(of: (Int, String).self) { group in
    for (index, page) in pages.enumerated() {
        group.addTask {
            let text = try await self.recognizeText(from: page.image)
            return (index, text)
        }
    }
    // Collect results in order
    var results: [(Int, String)] = []
    for try await result in group {
        results.append(result)
    }
    return results.sorted { $0.0 < $1.0 }.map { $0.1 }
}
```

## Performance Considerations

### OCR Optimization
- **Concurrent processing**: All pages processed simultaneously
- **Recognition level**: `.accurate` for quality (slower but better)
- **Language correction**: Enabled for better results
- **Target**: < 2 seconds per page on modern devices

### PDF Generation
- **Full resolution**: Preserves original image quality
- **Invisible text layer**: No visual impact, full searchability
- **Memory efficiency**: Pages processed sequentially
- **Target**: < 3 seconds for 10-page document

### Smart Naming
- **Heuristics only**: No ML model overhead
- **Text truncation**: First 500 chars for performance
- **Regex caching**: Compiled patterns reused
- **Target**: < 100ms (typically instant)

### Storage
- **UserDefaults metadata**: Fast, lightweight (< 1 KB per document)
- **Timestamp filenames**: No file system renames on edit
- **Lazy loading**: History loads on demand
- **Cleanup**: Remove orphaned metadata on fetch

## Error Handling

### Graceful Degradation
```swift
// OCR failure → PDF still generated without text layer
catch {
    state = .failed(.ocrFailed(underlying: error))
    // User can still share/save scanned images as PDF
}

// Smart naming failure → Date-based fallback
if let smartName = extractSmartName(from: text) {
    return smartName
}
return generateDatePrefix()  // "2025-12-29"
```

### User-Facing Errors
- **Camera permission denied**: Alert with Settings link
- **Camera unavailable**: Alert (device has no camera)
- **Scan cancelled**: Silent dismissal, return to Welcome
- **OCR failed**: Alert, PDF still available
- **PDF generation failed**: Alert, retry option
- **Save failed**: Alert with error description

### Error Recovery
- **Auto-save failure**: Document still shareable, user notified
- **File picker cancel**: Return to actions, data retained
- **Share cancel**: Silent dismissal, return to actions

## Security & Privacy

### Permissions
- **Camera**: Requested on first scan via Info.plist (NSCameraUsageDescription)
- **Files**: Document picker handles permissions automatically
- **No analytics**: Zero tracking or data collection

### Data Protection
- **On-device processing**: All OCR happens locally (Vision framework)
- **No network requests**: Fully offline app
- **Local storage only**: Documents directory + UserDefaults
- **User control**: Files saved to user-chosen locations

### Sandboxing
- **App Container**: PDFs stored in Documents directory (backed up by iCloud)
- **Security-scoped URLs**: Document picker provides temporary access
- **No file system access**: User explicitly chooses save locations

## Testing Strategy

### Unit Tests (Domain & Services)
- **SmartFilenameService**: Company extraction, date parsing, document type detection
- **OCRService**: Mock Vision requests, concurrent processing logic
- **PDFService**: PDF generation, text embedding, filename sanitization
- **DocumentRepository**: CRUD operations, metadata encoding/decoding

### Integration Tests
- **Scan Flow**: VisionKit → OCR → PDF → Save
- **History Flow**: Save → Fetch → Display → Delete
- **Filename Flow**: OCR → Smart naming → Edit → Update

### UI Tests
- **Critical paths**:
  - Welcome → Scan → Save
  - Welcome → History → View document
  - Scan → Share (without saving)
- **Accessibility**: VoiceOver navigation, Dynamic Type
- **Error handling**: Permission denial, scan cancellation

### Performance Tests
- **OCR**: 10-page document processing time
- **PDF generation**: Memory usage with high-resolution images
- **App launch**: Cold start to interactive UI (target: < 2s)
- **History loading**: 100+ documents (fetch + render)

## Extension Points

### Future Enhancements
1. **Multi-language support**: Localization with .xcstrings
2. **Dark mode**: Color variants in Assets.xcassets
3. **Document editing**: Page reordering, deletion, rotation
4. **Cloud sync**: iCloud Drive integration
5. **Export formats**: JPEG, PNG, TIFF (in addition to PDF)
6. **Batch operations**: Multi-document scanning
7. **Advanced OCR**: Manual text correction, confidence scores
8. **Smart categorization**: Auto-tag documents by type
9. **Search**: Full-text search across saved documents
10. **Widgets**: Quick scan from home screen

### Architectural Flexibility
- **Plugin system**: Custom filename generators (protocol-based)
- **Service swapping**: Replace heuristics with ML model without UI changes
- **Storage backends**: Swap UserDefaults for CoreData/SwiftData
- **Export strategies**: Strategy pattern for different file formats

## Design Principles

1. **Native First**: Leverage iOS frameworks (VisionKit, Vision, PDFKit)
2. **Actor-based concurrency**: All services are actors for thread safety
3. **Coordinator pattern**: Centralized navigation and state management
4. **Separation of concerns**: UI → ViewModel → Services → Domain
5. **Sendable everywhere**: Full Swift 6 concurrency compliance
6. **Observable state**: Reactive UI updates with @Observable
7. **Graceful degradation**: App works even if OCR/naming fails
8. **User control**: Explicit save locations, editable filenames
9. **Privacy by design**: No network, no tracking, on-device processing
10. **Performance**: Async operations, concurrent processing, lazy loading
