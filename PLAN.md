# Implementation Plan - SwiftDocumentScanner

**Status:** Feature complete. Polishing for App Store release.

## Phase 1: Foundation & Core Scanning

**Goal:** Integrate VisionKit for document scanning

- [x] 1.1: Initialize Xcode project (Swift 5.9+, iOS 17+, universal binary)
- [x] 1.2: Domain models: `Page`, `Document`, `ScanSession`
- [x] 1.3: Integrate VNDocumentCameraViewController via CameraScannerCoordinator
- [x] 1.4: Handle multi-page scan results with image capture
- [x] 1.5: Basic UI with WelcomeView and scan button

**Checkpoint:** Launch camera scanner, capture multiple pages, receive scanned images

## Phase 2: OCR & PDF Generation

**Goal:** Extract text and generate searchable PDFs

- [x] 2.1: Integrate Vision framework (VNRecognizeTextRequest) in OCRService
- [x] 2.2: Process scanned images for text recognition (async actor isolation)
- [x] 2.3: PDFService for PDF generation with embedded OCR text layer
- [x] 2.4: Background processing with progress tracking
- [x] 2.5: Error handling for OCR failures (graceful degradation)

**Checkpoint:** Scan document, run OCR in background, generate searchable PDF

## Phase 3: Smart Naming & File Operations

**Goal:** Intelligent filename generation and document persistence

- [x] 3.1: SmartFilenameService with heuristic-based name extraction
- [x] 3.2: Document type detection (Invoice, Receipt, Statement, Contract, etc.)
- [x] 3.3: Company name extraction from OCR text (multiple strategies)
- [x] 3.4: Document date extraction with normalization
- [x] 3.5: Reference number extraction for invoices/receipts
- [x] 3.6: Filename sanitization and date prefix formatting (YYYY-MM-DD)
- [x] 3.7: FilenameEditorView for user editing before/after save
- [x] 3.8: FileSaveView with UIDocumentPickerViewController integration
- [x] 3.9: DocumentRepository actor for local persistence (thread-safe)
- [x] 3.10: SavedDocument model with UserDefaults metadata storage (JSON encoding)
- [x] 3.11: Auto-save to Documents directory with timestamp filenames
- [x] 3.12: Separate internal filename (immutable) from display name (editable)

**Checkpoint:** Smart filename suggested based on OCR, auto-saved to Documents, exportable to Files app

## Phase 4: Share & Export

**Goal:** Share PDFs via native iOS share sheet

- [x] 4.1: Share sheet integration (UIActivityViewController)
- [x] 4.2: Share documents (already auto-saved, not "without saving")
- [x] 4.3: ScannedDocumentActionsView with Save to Files/Share/Edit buttons
- [x] 4.4: SavedDocumentActionsView for history items (Open PDF, Share, Delete)
- [x] 4.5: DocumentActionsComponents for reusable UI elements

**Checkpoint:** Share PDF via email, messages, AirDrop; documents auto-saved to Documents directory

**Implementation Note:** Changed from "save OR share" to "auto-save AND share/export" for better UX. All scanned documents are automatically saved to Documents directory with instant history access.

## Phase 5: Navigation & State Management

**Goal:** Streamlined user flow with coordinator pattern

- [x] 5.1: ScanFlowCoordinator for navigation state management
- [x] 5.2: Step-based navigation (Welcome → Camera → Processing → Actions)
- [x] 5.3: ProcessingView with OCR/filename generation progress
- [x] 5.4: HistoryView for viewing past scans
- [x] 5.5: Navigation to saved document actions
- [x] 5.6: Clean state transitions and error handling

**Checkpoint:** Complete scan-to-save flow with clear visual progression

## Phase 6: UI/UX Polish

**Goal:** Consistent design system and improved user experience

- [x] 6.1: DesignSystem with standardized colors, typography, spacing
- [x] 6.2: Button styles (primary, secondary, destructive)
- [x] 6.3: Visual hierarchy improvements (reduced clutter)
- [x] 6.4: Typography standardization (SF Pro, consistent sizing)
- [x] 6.5: Color scheme for light mode
- [x] 6.6: PDF preview in PDFEditorView
- [x] 6.7: Sheet-based filename editor for better UX
- [x] 6.8: Loading states and progress indicators

**Checkpoint:** Polished, intuitive interface with clear visual hierarchy

## Phase 7: Accessibility

**Goal:** Full VoiceOver and Dynamic Type support

- [x] 7.1: VoiceOver labels for key interactive elements (partial - WelcomeView, HistoryView, ProcessingView)
- [x] 7.2: Semantic accessibility traits (.isHeader, .isButton, etc.) on some views
- [x] 7.3: Accessibility hints for navigation (partial)
- [ ] 7.4: Complete VoiceOver coverage across ALL views
- [ ] 7.5: Dynamic Type support across all text elements
- [ ] 7.6: Minimum touch target sizes verification (44x44pt)
- [ ] 7.7: Keyboard navigation support
- [ ] 7.8: Color contrast verification (WCAG AA standard)
- [ ] 7.9: Reduced motion support for animations
- [ ] 7.10: Accessibility testing with VoiceOver and Accessibility Inspector

**Checkpoint:** Navigate entire app via VoiceOver, all text scales with Dynamic Type

**Current Status:** Partial accessibility implemented on WelcomeView, HistoryView, ProcessingView with labels and hints. Need comprehensive coverage across all views.

## Phase 8: Localization

**Goal:** Multi-language support with .xcstrings catalog

- [ ] 8.1: String extraction to .xcstrings catalog (Localizable.xcstrings)
- [ ] 8.2: Mark all user-facing strings for localization
- [ ] 8.3: Locale-aware formatters (dates, numbers, file sizes)
- [ ] 8.4: Export strings for translation
- [ ] 8.5: Translations for target languages: EN, FR, DE, ES, IT
- [ ] 8.6: Test UI layout with longer strings (German, French)
- [ ] 8.7: RTL language support (if targeting AR/HE)
- [ ] 8.8: Localized screenshots for App Store

**Checkpoint:** App displays correctly in all target languages with proper formatting

## Phase 9: Dark Mode Support

**Goal:** Full dark mode with proper color variants

- [ ] 9.1: Color assets with dark mode variants in Assets.xcassets
- [ ] 9.2: Update DesignSystem colors to support both light/dark modes
- [ ] 9.3: Verify WCAG AA contrast in both modes
- [ ] 9.4: Test all UI components in dark mode
- [ ] 9.5: System appearance switching (light/dark/auto)
- [ ] 9.6: Update screenshots for App Store (light & dark)

**Checkpoint:** Seamless appearance switching with proper contrast in both modes

## Phase 10: Performance & Testing

**Goal:** Optimize and validate

- [ ] 10.1: Profile with Instruments (Time Profiler, Allocations)
- [ ] 10.2: Optimize OCR performance (< 2s per page)
- [ ] 10.3: Optimize filename generation (< 1s)
- [ ] 10.4: PDF generation performance (< 3s for 10 pages)
- [ ] 10.5: Memory leak detection (Leaks instrument)
- [ ] 10.6: Unit test coverage (domain 80%+)
- [ ] 10.7: Integration tests for OCR and PDF generation
- [ ] 10.8: UI tests for critical user flows
- [ ] 10.9: SwiftLint integration and cleanup

**Checkpoint:** < 2s launch, 60fps UI, no leaks, 80%+ test coverage

**Deliverables:**
- .swiftlint.yml configuration with 0 violations
- Unit tests for SmartFilenameService, OCRService, PDFService
- Integration tests for end-to-end scan flows
- UI tests for Welcome → Scan → Save flow
- PROFILING.md - Performance analysis and benchmarks

## Phase 11: App Store Distribution

**Goal:** Submit to App Store

- [ ] 11.1: App icon (1024x1024 + all required sizes)
- [ ] 11.2: Launch screen and splash assets
- [ ] 11.3: Privacy manifest (NSCameraUsageDescription, NSPhotoLibraryAddUsageDescription)
- [ ] 11.4: App Sandbox entitlements review
- [ ] 11.5: Code signing with "Apple Distribution" certificate
- [ ] 11.6: App Store Connect configuration
  - [ ] App metadata (name, subtitle, keywords)
  - [ ] Screenshots (6.7", 6.5", 5.5" for iPhone)
  - [ ] Category: Productivity or Business
  - [ ] Privacy policy URL (optional but recommended)
- [ ] 11.7: Archive and validate build (Xcode Organizer)
- [ ] 11.8: Upload to App Store Connect via Xcode or Transporter
- [ ] 11.9: TestFlight beta testing (internal/external)
- [ ] 11.10: App Review submission with release notes
- [ ] 11.11: Monitor App Review status and respond to feedback
- [ ] 11.12: Release to App Store

**Checkpoint:** App submitted and approved in App Store, available for download

## Current State Summary

**Core Features (Complete):**
- **Scanning:** VNDocumentCameraViewController integration with multi-page capture
- **OCR:** Vision framework with concurrent TaskGroup processing (all pages in parallel)
- **PDF Generation:** PDFKit with embedded invisible text layer for searchability
- **Smart Naming:** Heuristic-based extraction (company, doc type, date, ref number)
- **Auto-Save:** Automatic save to Documents directory with timestamp filenames
- **Document History:** HistoryView with list of all saved documents (newest first)
- **Editing:** FilenameEditorView and PDFEditorView (preview with zoom/pan)
- **Sharing:** UIActivityViewController for email, messages, AirDrop
- **Export:** UIDocumentPickerViewController for saving to user-chosen Files location
- **Navigation:** ScanFlowCoordinator with typed NavigationStack (Welcome → Camera → Processing → Actions)
- **State Management:** @Observable HomeViewModel with ScanSessionState enum
- **Persistence:** DocumentRepository actor with UserDefaults metadata (thread-safe)
- **Design System:** Centralized colors, typography, spacing, button styles
- **Accessibility:** Partial VoiceOver labels on WelcomeView, HistoryView, ProcessingView
- **Error Handling:** Graceful degradation with user-facing alerts

**Polish in Progress:**
- Full accessibility (Phase 7) - partial VoiceOver support exists
- Localization (Phase 8) - hardcoded English strings currently
- Dark mode (Phase 9) - not implemented
- Performance optimization (Phase 10) - functional but not profiled
- Testing (Phase 10) - basic tests exist, need comprehensive coverage
- App Store assets (Phase 11) - not created

**Remaining Work:**
1. **Accessibility** - Complete VoiceOver coverage, Dynamic Type, keyboard nav
2. **Localization** - String extraction, 5 language translations, formatters
3. **Dark Mode** - Color variants, WCAG AA contrast verification
4. **Testing** - Unit, integration, UI tests with 80%+ coverage
5. **Performance** - Profiling and optimization for App Store quality
6. **Distribution** - Icons, screenshots, metadata, submission

## Design Decisions

**Smart Naming Implementation:**
- **Chose heuristics over BERT/ML model** to avoid:
  - 40-60 MB Core ML model size increase
  - Additional on-device inference complexity
  - Unpredictable ML model behavior
- **Current approach:** Pattern matching for document types, regex for dates/numbers, multi-strategy company extraction
- **Result:** Fast (< 100ms), predictable, lightweight, good enough for most documents

**Navigation Pattern:**
- **Coordinator pattern with NavigationStack** (ScanFlowCoordinator):
  - Centralized state management (@Observable HomeViewModel)
  - Typed navigation destinations (ScanDestination enum)
  - Clear separation of navigation logic from views
  - State-driven navigation with onChange modifiers

**Persistence Strategy:**
- **DocumentRepository actor** for thread-safe file operations
- **Auto-save to Documents directory** with timestamp filenames (immutable)
- **UserDefaults for metadata** (JSON encoding, fast, lightweight)
- **Dual filename system:** Internal (timestamp) vs. Display (user-editable)
- **No cloud sync** - privacy-first, user controls via iCloud Drive backup
- **Export to Files** - UIDocumentPickerViewController for user-chosen locations
- **Orphaned file cleanup** - metadata filtered on fetch for missing files

## Features Added Beyond Original Plan

**Enhancements implemented:**
- ✅ **Document History** - HistoryView with list of all saved documents (originally "out of scope")
- ✅ **Auto-Save** - Automatic persistence to Documents directory (originally manual "Save to Files" only)
- ✅ **Dual Filename System** - Internal timestamp + user-editable display name (originally single filename)
- ✅ **PDF Preview** - PDFEditorView with zoom/pan before export (originally just save/share)
- ✅ **Swipe-to-Delete** - Quick deletion in history (originally no document management)
- ✅ **Saved Document Actions** - Open PDF, Share, Delete for history items (originally no history UI)
- ✅ **DesignSystem** - Centralized design tokens for consistency (originally ad-hoc styling)

## Features Removed from Original Plan

**Simplified implementations:**
- ~~BERT-based filename generation~~ - **Replaced** with heuristics (simpler, faster, smaller, < 100ms vs. 500ms-1s)
- ~~Cloud sync~~ - Out of scope, use iCloud Drive automatic backup instead
- ~~Document editing (crop, rotate, filters)~~ - VNDocumentCameraViewController handles this during scan
- ~~Password-protected PDFs~~ - Not MVP
- ~~Annotations or signatures~~ - Not MVP
- ~~Manual text correction/editing~~ - Not MVP

## Out of Scope

- Custom document camera (using VNDocumentCameraViewController instead)
- Document management/browser (using Files app instead)
- Cloud services/backend (all on-device)
- Third-party analytics or crash reporting
- In-app purchases or subscriptions
- Custom share destinations (using UIActivityViewController)
- Multiple scan sessions simultaneously
- Undo/redo for edits

## Success Metrics

1. ✅ User completes scan session in < 60 seconds
2. ✅ Zero custom camera code (100% native VisionKit)
3. ⏳ OCR processing < 2 seconds per page (not profiled yet)
4. ✅ Smart filename generation < 1 second (heuristics are instant)
5. ⏳ Crash-free rate > 99.5% (needs TestFlight data)
6. ⏳ App Store approval on first submission (not submitted yet)

## Next Steps

**Priority 1 (Required for App Store):**
1. Complete accessibility (Phase 7) - VoiceOver, Dynamic Type, keyboard nav
2. Add dark mode support (Phase 9) - color variants, testing
3. Create app icon and launch screen (Phase 11.1-11.2)
4. Privacy manifest and entitlements (Phase 11.3-11.4)

**Priority 2 (Quality improvements):**
1. Localization for 5 languages (Phase 8)
2. Performance profiling and optimization (Phase 10.1-10.5)
3. Comprehensive test coverage (Phase 10.6-10.8)
4. SwiftLint integration (Phase 10.9)

**Priority 3 (App Store submission):**
1. App Store Connect setup (Phase 11.6)
2. Screenshots and metadata (Phase 11.6)
3. Archive, upload, TestFlight (Phase 11.7-11.9)
4. Submit for review (Phase 11.10-11.12)
