# Document Scanner - MVP Requirements

## Overview

A minimalistic document scanner app that wraps iOS native scanning capabilities (VisionKit) to provide a simple, focused user experience for scanning multi-page documents to PDF.

## User Stories

### Launch Camera Scanner
**As a user, I want to instantly launch the document scanner so that I can quickly capture a document without navigating through menus.**

**Acceptance Criteria:**
- [x] Single "Scan Document" button on home screen
- [x] Tapping button launches native VNDocumentCameraViewController
- [x] Camera opens in < 1 second
- [x] Automatic edge detection and perspective correction visible
- [x] No setup or configuration required

### Scan Multiple Pages
**As a user, I want to scan multiple pages in one session so that I can create a single PDF document from a multi-page paper document.**

**Acceptance Criteria:**
- [x] First page captured automatically when detected
- [x] "Add Page" button available after each capture
- [x] Can scan up to 50 pages in one session
- [x] Visual page count displayed (e.g., "Page 3 of 5")
- [x] Can review and retake any individual page
- [x] All scanning handled by native VNDocumentCameraViewController

### Save Document to Files
**As a user, I want to save my scanned document as a PDF with an intelligently suggested filename so that I can easily identify it later.**

**Acceptance Criteria:**
- [x] "Save" button available when scanning is complete
- [x] Tapping "Save" generates PDF using PDFKit
- [x] Smart filename generated using heuristic-based text analysis (not BERT - see design decision below)
- [x] Filename format: "YYYY-MM-DD Document Name.pdf" (date prefix)
- [x] If no meaningful text detected, fallback to: "YYYY-MM-DD Scan.pdf"
- [x] Examples:
  - OCR: "Invoice from Apple Inc..." → "2024-01-15 Apple Inc Invoice.pdf"
  - OCR: "Meeting Notes Q4 Planning" → "2024-01-15 Meeting Notes Q4 Planning.pdf"
  - No text → "2024-01-15 Scan.pdf"
- [x] Native file picker appears for location selection
- [x] User can rename file before saving (via Edit Name button)
- [x] PDF auto-saved to Documents directory AND exportable to Files
- [x] PDF preview available before export

**Design Decision:** Replaced Core ML BERT model with heuristic-based smart filename generation to avoid:
- 40-60 MB model size increase
- ~500ms-1s inference latency
- Unpredictable ML model behavior

Heuristics provide instant results (< 100ms), predictable output, and good accuracy for most documents.

### Share Document Directly
**As a user, I want to share my scanned PDF immediately via email, messages, or other apps so that I can send it to others without saving it first.**

**Acceptance Criteria:**
- [x] "Share" button available when scanning is complete
- [x] Tapping "Share" opens native iOS share sheet (UIActivityViewController)
- [x] PDF accessible to all standard share destinations: Mail, Messages, AirDrop, third-party apps
- [x] Can share without saving to Files (auto-saved to Documents directory)
- [x] Can use both "Save to Files" and "Share" for the same document
- [x] Share sheet dismissed returns to actions view

### Extract Text with OCR
**As a user, I want text automatically recognized in my scanned documents so that I can search, select, and copy text from the PDF.**

**Acceptance Criteria:**
- [x] OCR automatically runs on all scanned pages using Vision framework (VNRecognizeTextRequest)
- [x] Recognized text embedded as searchable layer in PDF
- [x] Text selectable and copyable when viewing PDF in Files app or other readers
- [x] OCR processing happens in background without blocking save/share
- [x] Supports multiple languages (automatic detection)
- [x] Works with both handwritten and printed text (using .accurate recognition level)
- [x] Configured for 3 languages: English, Spanish, French
- [x] OCR failures handled gracefully (PDF still generated without text layer)

### Handle Errors Gracefully
**As a user, I want the app to handle errors appropriately so that I understand what went wrong and can take corrective action.**

**Acceptance Criteria:**
- [x] Camera permission denied: Show alert explaining why permission is needed with link to Settings
- [x] Disk full during save: Show alert indicating insufficient storage
- [x] OCR fails: PDF still generated without searchable text layer, error displayed
- [x] Heuristic filename generation fails: Fall back to date-based filename without error
- [x] Share cancelled: Return to actions view without error
- [x] File save cancelled: Return to actions view, document data retained
- [ ] Maximum PDF size (100 MB): No limit currently enforced (future enhancement)

### View Document History (NEW)
**As a user, I want to view all my previously scanned documents so that I can access, share, or delete them later.**

**Acceptance Criteria:**
- [x] "View Past Scans" button on home screen
- [x] List of saved documents sorted by date (newest first)
- [x] Display filename, date, and page count for each document
- [x] Tap document to view actions (Open PDF, Share, Delete)
- [x] Swipe-to-delete with confirmation
- [x] Empty state with helpful message
- [x] Auto-save documents to Documents directory after scanning
- [x] PDF preview available for saved documents
- [x] Share saved documents via UIActivityViewController
- [x] VoiceOver labels for accessibility

**Implementation Notes:**
- Documents auto-saved to app's Documents directory with timestamp filenames
- Metadata stored in UserDefaults (lightweight, fast)
- Separate internal filename (immutable) from display name (user-editable)
- Orphaned file cleanup on fetch

### Edit Document Name (NEW)
**As a user, I want to edit the suggested filename before or after saving so that I can customize it to my needs.**

**Acceptance Criteria:**
- [x] "Edit Name" button in scanned document actions
- [x] Sheet-based filename editor with text field
- [x] Pre-filled with smart filename (without .pdf extension)
- [x] Real-time validation (no invalid characters)
- [x] Automatic .pdf extension appending
- [x] Update both in-memory document and saved metadata
- [x] Changes reflected immediately in history view

### Edit PDF Pages (NEW)
**As a user, I want to preview the scanned PDF before exporting so that I can verify the quality.**

**Acceptance Criteria:**
- [x] "Edit Pages" button in scanned document actions
- [x] Full-screen PDF preview with PDFView
- [x] Zoom and pan controls
- [x] Navigate between pages
- [x] Changes to PDF reflected in shared/exported version
- [ ] Page reordering (future enhancement)
- [ ] Page deletion (future enhancement)
- [ ] Page rotation (future enhancement)

## User Flow

```
1. Launch App
   ↓
2. Tap "Scan Document"
   ↓
3. [Native Camera] Scan pages (VNDocumentCameraViewController)
   ↓
4. [Background] OCR processing (Vision framework, concurrent)
   ↓
5. [Background] Heuristic analysis → Smart filename
   ↓
6. [Automatic] PDF auto-saved to Documents directory
   ↓
7. Actions screen displays with suggested name "YYYY-MM-DD [Topic].pdf"
   ↓
8. User options:
   ├─ "Edit Name" → Edit filename → Updates saved document
   ├─ "Edit Pages" → PDF preview (zoom, pan, navigate)
   ├─ "Share Document" → UIActivityViewController (Mail, Messages, AirDrop)
   └─ "Save to Files" → UIDocumentPickerViewController → Export copy
   ↓
9. Return to home screen

Alternative flows:
- Tap "View Past Scans" → HistoryView → Select document → Actions (Open PDF, Share, Delete)
- Scan cancelled → Return to home screen
```

## Technical Approach

### Native Frameworks
- **VisionKit**: `VNDocumentCameraViewController` for scanning
- **Vision**: `VNRecognizeTextRequest` for OCR text recognition (concurrent TaskGroup processing)
- **PDFKit**: PDF generation from scanned images with embedded text layer
- **UIDocumentPickerViewController**: Export to Files
- **UIActivityViewController**: Share functionality
- **FileManager**: Local persistence to Documents directory
- **UserDefaults**: Metadata storage (JSON encoding)

### Architecture
- **Domain**: Document, Page, SavedDocument models; ScanSessionState, ScanError enums
- **Data**: OCRService, PDFService, SmartFilenameService, DocumentRepository (all actors)
- **UI**: ScanFlowCoordinator (MVVM pattern), SwiftUI views, native controller wrappers

## Out of Scope (MVP)

- ❌ Document editing (crop, rotate, filters during scan) - VNDocumentCameraViewController handles this
- ✅ Document management / history - **IMPLEMENTED** (HistoryView, auto-save)
- ❌ Cloud sync - iCloud Drive backup only (automatic via Documents directory)
- ❌ Password-protected PDFs
- ❌ Annotations or signatures
- ❌ Batch operations / multi-document scanning
- ❌ Manual text correction / editing
- ❌ Advanced PDF editing (page reordering, deletion, rotation) - Future enhancement
- ❌ Core ML BERT model - **REPLACED** with heuristic-based smart naming

## Non-Functional Requirements

### Performance
- OCR processing: < 2 seconds per page (concurrent processing, runs in background)
- Heuristic filename generation: < 100ms (instant, pattern matching)
- PDF generation with embedded text: < 3 seconds for 10 pages
- App launch: < 2 seconds
- Minimal battery impact (all processing on-device, optimized by Apple)
- Concurrent page processing: TaskGroup for parallel OCR

### Usability
- Zero learning curve (familiar iOS patterns)
- Accessible with VoiceOver (partial - in progress)
- Supports Dynamic Type (in progress)
- Works in portrait and landscape
- Auto-save with instant access to history
- Editable filenames before and after save

### Privacy
- No analytics or tracking
- No network requests (all OCR processing on-device)
- Camera permission requested on first use
- Files permission requested when saving
- All text recognition happens locally using Vision framework

### Compatibility
- iOS 17.0+ (for latest VisionKit features)
- iPhone only (optimized for one-handed use)
- Light mode support (Dark mode in progress)
- Swift 5.9+, Swift Concurrency (async/await, actors)
- Universal binary (ARM64)

## Success Metrics

1. ✅ User completes scan session in < 60 seconds (including OCR and smart naming)
2. ✅ Zero custom camera code (100% native VisionKit)
3. ⏳ OCR processing completes in < 2 seconds per page (not profiled yet)
4. ✅ Heuristic filename generation completes in < 100ms (instant)
5. ⏳ Crash-free rate > 99.5% (needs TestFlight data)
6. ✅ Document auto-save with history access
7. ⏳ App Store approval on first submission (not submitted yet)

## Implementation Phases

### Phase 1: Core Scanning (COMPLETED)
- ✅ Integrate VNDocumentCameraViewController
- ✅ Handle scanned image results
- ✅ Basic UI for launching scanner
- ✅ WelcomeView with scan button

### Phase 2: PDF Generation & OCR (COMPLETED)
- ✅ Integrate Vision framework for OCR (VNRecognizeTextRequest)
- ✅ Concurrent processing of pages with TaskGroup
- ✅ Process scanned images for text recognition
- ✅ Convert images to PDF using PDFKit with embedded text layer
- ✅ Invisible text layer for searchability
- ✅ Date-based filename fallback

### Phase 3: Smart Naming & Share (COMPLETED)
- ✅ Heuristic-based smart filename generation (replaced BERT)
- ✅ Company name extraction (legal suffixes, all-caps, title case)
- ✅ Document type detection (Invoice, Receipt, Statement, Contract, etc.)
- ✅ Date extraction and normalization
- ✅ Reference number extraction
- ✅ Smart filename generation pipeline (OCR → Heuristics → filename)
- ✅ Share sheet integration (UIActivityViewController)
- ✅ UI polish with DesignSystem
- ✅ Partial accessibility (VoiceOver labels on some views)

### Phase 4: Document Management & History (COMPLETED)
- ✅ DocumentRepository for local persistence
- ✅ Auto-save to Documents directory
- ✅ UserDefaults metadata storage
- ✅ HistoryView with saved documents list
- ✅ Swipe-to-delete functionality
- ✅ Document actions (Open PDF, Share, Delete)
- ✅ PDF preview with PDFEditorView
- ✅ Filename editing with FilenameEditorView
- ✅ ScanFlowCoordinator for navigation

### Phase 5: Polish & App Store Prep (IN PROGRESS)
- [ ] Complete accessibility (VoiceOver, Dynamic Type, keyboard nav)
- [ ] Dark mode support with color variants
- [ ] Localization (.xcstrings, 5 languages)
- [ ] Performance profiling and optimization
- [ ] Comprehensive test coverage (80%+)
- [ ] SwiftLint integration
- [ ] App icon and launch screen
- [ ] App Store screenshots and metadata
- [ ] Privacy manifest and entitlements
- [ ] TestFlight beta testing
- [ ] App Store submission

## Usage Scenarios

### Scenario 1: Quick Single-Page Scan
```
Given I need to scan a receipt
When I open the app and tap "Scan Document"
Then the camera opens immediately
And I scan one page
And tap "Save"
And choose a folder in Files
Then the PDF is saved
And I return to the home screen
```

### Scenario 2: Multi-Page Document
```
Given I need to scan a 5-page document
When I start a scanning session
Then I scan page 1 automatically
And tap "Add Page" for pages 2-5
And review all pages
And tap "Save"
Then a single PDF with 5 pages is created
```

### Scenario 3: Scan and Share
```
Given I need to send a scanned document via email
When I complete a scanning session
And tap "Share" instead of "Save"
Then the iOS share sheet appears
And I select Mail
And the PDF is attached to a new email
```

### Scenario 4: Search and Copy Text from Scanned Document
```
Given I scanned a document with contact information
When I save the PDF to Files
And open it in Files app or another PDF reader
Then I can search for specific words in the document
And select and copy text (phone number, email, address)
And the text is copied to clipboard
And I can paste it into another app
```

### Scenario 5: Smart Filename Generation (Heuristics)
```
Given I scanned an invoice from Apple Inc dated March 15, 2024
When OCR completes and extracts "Invoice from Apple Inc..."
Then the system analyzes the text using heuristics
And auto-saves with filename "2024-03-15 Apple Inc Invoice.pdf"
And displays the actions screen with the suggested name
And I can tap "Edit Name" to customize it before exporting
```

```
Given I scanned a blank page or unreadable document
When OCR finds no meaningful text
Then the system falls back to "2025-12-29 Scan.pdf" (today's date)
And I can edit the name via "Edit Name" button
```

### Scenario 6: Document History (NEW)
```
Given I previously scanned several documents
When I tap "View Past Scans" from the home screen
Then I see a list of all saved documents sorted by date
And each shows filename, date, and page count
When I tap on a document
Then I can view the PDF, share it, or delete it
When I swipe left on a document
Then I can quickly delete it
```

## Design Principles

1. **Native First**: Use iOS system UI wherever possible
2. **Minimal Friction**: Launch to scan in one tap
3. **Zero Configuration**: No settings, no accounts
4. **Transparent**: User controls where files are saved
5. **Fast**: Optimize for speed over features

## Constraints

- Must use VNDocumentCameraViewController (no custom camera)
- Must use standard iOS share sheet (no custom sharing)
- Auto-save to Documents directory (user can export to Files)
- No third-party dependencies for core functionality
- All processing on-device (no cloud API calls)
- Heuristic-based smart naming (no ML models)

## Technical Implementation Notes

### Heuristic-Based Smart Filename Generation

**Approach:**
Use pattern matching and regex to extract document metadata from OCR text.

**Extraction Strategies:**

1. **Company Name Extraction:**
   - Legal suffixes: Inc, Inc., LLC, Ltd, SA, SARL, GmbH, AG
   - All-caps headers (3-30 chars, >70% uppercase)
   - Single word brand names (4-20 chars, all caps)
   - Title Case in first 3 lines (2-4 words, no numbers)

2. **Document Type Detection (Priority-based):**
   - Invoice (keywords: "invoice #", "bill to", "amount due")
   - Receipt (keywords: "receipt #", "thank you for your purchase")
   - Statement (keywords: "account statement", "current balance")
   - Contract (keywords: "this agreement", "hereby agree")
   - Certificate, Letter, Report, Form, Memo, Meeting Notes
   - Multilingual: English + French keywords

3. **Date Extraction:**
   - ISO format: 2025-08-28
   - European: 28.08.2025, 28/08/2025
   - French: "28 août 2025"
   - English: "August 28, 2025"
   - Normalize to YYYY-MM-DD

4. **Reference Number Extraction:**
   - Patterns: "Invoice #12345", "Ref: INV-2024-001"
   - Only for Invoice, Receipt, Statement, Contract types
   - Alphanumeric codes (3-15 chars)

**Pipeline:**
```
1. OCR Text Extraction (Vision framework, concurrent)
   ↓
2. Text Preprocessing (first 500 chars, whitespace normalization)
   ↓
3. Heuristic Analysis (pattern matching, regex)
   ├─ Extract company name
   ├─ Detect document type
   ├─ Extract document date (if found)
   └─ Extract reference number (if applicable)
   ↓
4. Filename Construction: "YYYY-MM-DD [Company] [DocType] [#RefNum].pdf"
   ↓
5. Fallback: "YYYY-MM-DD Scan.pdf" (if no info found)
```

**Filename Sanitization:**
- Remove invalid characters: `/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`
- Limit length to 80 characters
- Trim whitespace
- Replace multiple spaces with single space

**Performance:**
- < 100ms processing time (instant)
- No ML model overhead
- Predictable results
- Zero dependencies

**Implementation:**
See `SmartFilenameService.swift` for detailed implementation.
