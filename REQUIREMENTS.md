# Document Scanner - MVP Requirements

## Overview

A minimalistic document scanner app that wraps iOS native scanning capabilities (VisionKit) to provide a simple, focused user experience for scanning multi-page documents to PDF.

## User Stories

### Launch Camera Scanner
**As a user, I want to instantly launch the document scanner so that I can quickly capture a document without navigating through menus.**

**Acceptance Criteria:**
- [ ] Single "Scan Document" button on home screen
- [ ] Tapping button launches native VNDocumentCameraViewController
- [ ] Camera opens in < 1 second
- [ ] Automatic edge detection and perspective correction visible
- [ ] No setup or configuration required

### Scan Multiple Pages
**As a user, I want to scan multiple pages in one session so that I can create a single PDF document from a multi-page paper document.**

**Acceptance Criteria:**
- [ ] First page captured automatically when detected
- [ ] "Add Page" button available after each capture
- [ ] Can scan up to 50 pages in one session
- [ ] Visual page count displayed (e.g., "Page 3 of 5")
- [ ] Can review and retake any individual page
- [ ] All scanning handled by native VNDocumentCameraViewController

### Save Document to Files
**As a user, I want to save my scanned document as a PDF with an intelligently suggested filename so that I can easily identify it later.**

**Acceptance Criteria:**
- [ ] "Save" button available when scanning is complete
- [ ] Tapping "Save" generates PDF using PDFKit
- [ ] Smart filename generated using Core ML BERT model based on OCR text
- [ ] Filename format: "YYYY-MM-DD Document Name.pdf" (date prefix)
- [ ] If no meaningful text detected, fallback to: "YYYY-MM-DD Scan.pdf"
- [ ] Examples:
  - OCR: "Invoice from Apple Inc..." → "2024-01-15 Apple Inc Invoice.pdf"
  - OCR: "Meeting Notes Q4 Planning" → "2024-01-15 Meeting Notes Q4 Planning.pdf"
  - No text → "2024-01-15 Scan.pdf"
- [ ] Native file picker appears for location selection
- [ ] User can rename file before saving
- [ ] PDF saved successfully to chosen Files location
- [ ] Confirmation shown after successful save

### Share Document Directly
**As a user, I want to share my scanned PDF immediately via email, messages, or other apps so that I can send it to others without saving it first.**

**Acceptance Criteria:**
- [ ] "Share" button available when scanning is complete
- [ ] Tapping "Share" opens native iOS share sheet (UIActivityViewController)
- [ ] PDF accessible to all standard share destinations: Mail, Messages, AirDrop, third-party apps
- [ ] Can share without saving to Files
- [ ] Can use both "Save" and "Share" for the same document
- [ ] Share sheet dismissed returns to app home screen

### Extract Text with OCR
**As a user, I want text automatically recognized in my scanned documents so that I can search, select, and copy text from the PDF.**

**Acceptance Criteria:**
- [ ] OCR automatically runs on all scanned pages using Vision framework (VNRecognizeTextRequest)
- [ ] Recognized text embedded as searchable layer in PDF
- [ ] Text selectable and copyable when viewing PDF in Files app or other readers
- [ ] OCR processing happens in background without blocking save/share
- [ ] Supports multiple languages (automatic detection)
- [ ] Works with both handwritten and printed text (using .accurate recognition level)
- [ ] Tested with at least 3 languages: English, Spanish, French
- [ ] OCR failures handled gracefully (PDF still generated without text layer)

### Handle Errors Gracefully
**As a user, I want the app to handle errors appropriately so that I understand what went wrong and can take corrective action.**

**Acceptance Criteria:**
- [ ] Camera permission denied: Show alert explaining why permission is needed with link to Settings
- [ ] Disk full during save: Show alert indicating insufficient storage
- [ ] OCR fails: PDF still generated without searchable text layer, no user-facing error
- [ ] BERT filename generation fails: Fall back to date-based filename without error
- [ ] Share cancelled: Return to home screen without error
- [ ] File save cancelled: Return to home screen, document data retained until user exits
- [ ] Maximum PDF size (100 MB): Show warning if approaching limit, prevent additional pages beyond limit

## User Flow

```
1. Launch App
   ↓
2. Tap "Scan Document"
   ↓
3. [Native Camera] Scan pages
   ↓
4. [Background] OCR processing (Vision framework)
   ↓
5. Tap "Save" when done
   ↓
6. [Background] BERT analyzes text → Smart filename
   ↓
7. File picker opens with suggested name "YYYY-MM-DD [Topic].pdf"
   ↓
8. Choose location & optionally rename
   ↓
9. PDF saved with searchable text
   ↓
10. Return to home screen

Alternative: Tap "Share" at step 5 to skip saving
```

## Technical Approach

### Native Frameworks
- **VisionKit**: `VNDocumentCameraViewController` for scanning
- **Vision**: `VNRecognizeTextRequest` for OCR text recognition
- **Core ML**: BERT model for intelligent filename generation from OCR text
- **PDFKit**: PDF generation from scanned images with embedded text layer
- **UIDocumentPickerViewController**: Save to Files
- **UIActivityViewController**: Share functionality

### Architecture
- **Domain**: Document model (pages, text content, PDF generation, smart naming)
- **Data**: File system persistence, PDF creation, OCR processing, BERT inference
- **UI**: Minimal wrapper around native controllers

## Out of Scope (MVP)

- ❌ Document editing (crop, rotate, filters) - VNDocumentCameraViewController handles this
- ❌ Document management / history - Files app handles this
- ❌ Cloud sync - iCloud Drive handles this
- ❌ Password-protected PDFs
- ❌ Annotations or signatures
- ❌ Batch operations
- ❌ Manual text correction / editing

## Non-Functional Requirements

### Performance
- OCR processing: < 2 seconds per page (runs in background)
- BERT filename generation: < 1 second (runs after OCR)
- PDF generation with embedded text: < 3 seconds for 10 pages
- App launch < 2 seconds
- Minimal battery impact (all processing on-device, optimized by Apple)

### Usability
- Zero learning curve (familiar iOS patterns)
- Accessible with VoiceOver
- Supports Dynamic Type
- Works in portrait and landscape

### Privacy
- No analytics or tracking
- No network requests (all OCR processing on-device)
- Camera permission requested on first use
- Files permission requested when saving
- All text recognition happens locally using Vision framework

### Compatibility
- iOS 17.0+ (for latest VisionKit features)
- iPhone only (optimized for one-handed use)
- Light and Dark mode support

## Success Metrics

1. User completes scan session in < 60 seconds (including OCR and smart naming)
2. Zero custom camera code (100% native VisionKit)
3. OCR processing completes in < 2 seconds per page
4. BERT filename generation completes in < 1 second
5. Crash-free rate > 99.5%

## Implementation Phases

### Phase 1: Core Scanning (Week 1)
- Integrate VNDocumentCameraViewController
- Handle scanned image results
- Basic UI for launching scanner

### Phase 2: PDF Generation & OCR (Week 1-2)
- Integrate Vision framework for OCR (VNRecognizeTextRequest)
- Process scanned images for text recognition
- Convert images to PDF using PDFKit with embedded text layer
- Implement save to Files
- Basic filename generation (date-based fallback)

### Phase 3: Smart Naming & Share (Week 2-3)
- Download and integrate BERT Core ML model
- Implement question-answering system for filename extraction
- Smart filename generation pipeline (OCR → BERT → filename)
- Add share sheet integration
- UI polish and animations
- Accessibility (VoiceOver, Dynamic Type)
- App icon and launch screen
- Performance optimization for multi-page OCR and BERT inference

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

### Scenario 5: Smart Filename Generation
```
Given I scanned an invoice from Apple Inc dated March 15, 2024
When OCR completes and extracts "Invoice from Apple Inc..."
And I tap "Save"
Then the system uses BERT to analyze the text
And suggests filename "2024-03-15 Apple Inc Invoice.pdf"
And the file picker opens with this suggested name
And I can rename it if desired or save as-is
```

```
Given I scanned a blank page or unreadable document
When OCR finds no meaningful text
And I tap "Save"
Then the system falls back to "2024-03-15 Scan.pdf"
And I can rename it before saving
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
- Must use Files app for storage (no app-specific library)
- No third-party dependencies for core functionality
- BERT model must run on-device (no cloud API calls)

## Technical Implementation Notes

### BERT-Based Smart Filename Generation

**Approach:**
Use Core ML BERT model for question-answering to extract document metadata from OCR text.

**Questions to Ask BERT:**
1. "What is the main topic of this document?" → Extract subject/title
2. "What type of document is this?" → Identify invoice, receipt, contract, etc.
3. "What company or organization is mentioned?" → Extract organization name

**Pipeline:**
```
1. OCR Text Extraction (Vision framework)
   ↓
2. Text Preprocessing (first 500 characters for performance)
   ↓
3. BERT Question-Answering (Core ML)
   ↓
4. Answer Parsing & Sanitization
   ↓
5. Filename Construction: "YYYY-MM-DD [Answer].pdf"
   ↓
6. Fallback: "YYYY-MM-DD Scan.pdf" (if confidence < threshold)
```

**Model:**
- Use Apple's DistilBERT or MobileBERT for better performance
- Download from Apple's Core ML model gallery or convert from Hugging Face
- Model size: ~40-60 MB (acceptable for on-device)
- Inference time: ~500ms-1s on iPhone 12+

**Filename Sanitization:**
- Remove special characters: `/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`
- Limit length to 100 characters
- Trim whitespace
- Replace multiple spaces with single space

**Example Implementation Reference:**
https://developer.apple.com/documentation/coreml/finding-answers-to-questions-in-a-text-document
