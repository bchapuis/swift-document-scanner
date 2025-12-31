import SwiftUI
import VisionKit

@MainActor
@Observable
final class HomeViewModel {
    var state: ScanSessionState = .idle
    var showScanner = false
    var showPermissionAlert = false
    var showDocumentPicker = false
    var showShareSheet = false
    var currentDocument: Document?
    var currentPDFData: Data?
    var suggestedFilename: String = ""
    var editedFilename: String = ""
    var savedDocumentId: UUID?  // Track the auto-saved document ID

    private let ocrService = OCRService()
    private let pdfService = PDFService()
    private let documentRepository = DocumentRepository()

    func startScanning() {
        // Check if document scanning is available on this device
        guard VNDocumentCameraViewController.isSupported else {
            state = .failed(.cameraUnavailable)
            return
        }

        showScanner = true
        state = .scanning
    }

    func handleScanComplete(_ document: Document) {
        currentDocument = document
        showScanner = false

        // Start OCR processing
        Task {
            await processDocument(document)
        }
    }

    func handleScanCancel() {
        state = .idle
        showScanner = false
    }

    func handleScanError(_ error: ScanError) {
        state = .failed(error)
        showScanner = false

        if case .cameraPermissionDenied = error {
            showPermissionAlert = true
        }
    }

    func resetSession() {
        state = .idle
        currentDocument = nil
        currentPDFData = nil
        suggestedFilename = ""
        savedDocumentId = nil
    }

    // MARK: - Document Processing

    private func processDocument(_ document: Document) async {
        state = .processing

        do {
            // Step 1: Perform OCR on all pages
            let ocrResults = try await ocrService.recognizeText(from: document.pages)

            // Update document with OCR results
            var updatedDocument = document
            for (index, result) in ocrResults.enumerated() {
                updatedDocument.updatePageOCR(at: index, result: result)
            }
            currentDocument = updatedDocument

            // Step 2: Generate PDF with positioned text layers
            let pdfData = try await pdfService.generatePDF(
                from: updatedDocument.pages,
                withOCRResults: ocrResults
            )
            currentPDFData = pdfData

            // Step 3: Generate smart filename from OCR text
            let combinedText = updatedDocument.fullText
            suggestedFilename = await pdfService.generateSmartFilename(from: combinedText)

            // Step 4: Auto-save PDF to documents directory
            do {
                let savedDoc = try await documentRepository.save(
                    pdfData: pdfData,
                    displayName: suggestedFilename,
                    pageCount: updatedDocument.pageCount
                )
                savedDocumentId = savedDoc.id
            } catch {
                // Continue even if auto-save fails - user can still share/export
                print("Auto-save failed: \(error)")
            }

            // Update state to completed
            state = .completed(updatedDocument)

        } catch {
            state = .failed(.ocrFailed(underlying: error))
        }
    }

    func prepareEditFilename() {
        // Initialize edit field with suggested name (without .pdf)
        editedFilename = suggestedFilename.replacingOccurrences(of: ".pdf", with: "")
    }

    func saveDocument() {
        guard currentPDFData != nil else { return }
        showDocumentPicker = true
    }

    func confirmEditedFilename() {
        // Add .pdf extension if not present
        var finalFilename = editedFilename.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalFilename.isEmpty {
            if !finalFilename.hasSuffix(".pdf") {
                finalFilename += ".pdf"
            }
            suggestedFilename = finalFilename

            // Update the saved document's display name
            if let docId = savedDocumentId {
                Task {
                    try? await documentRepository.updateDisplayName(id: docId, newDisplayName: finalFilename)
                }
            }
        }
    }

    func updatePDFData(_ data: Data) {
        currentPDFData = data

        // Update the saved document's PDF data
        if let docId = savedDocumentId {
            Task {
                do {
                    let allDocs = await documentRepository.fetchAll()
                    if let savedDoc = allDocs.first(where: { $0.id == docId }) {
                        try data.write(to: savedDoc.fileURL)
                    }
                } catch {
                    print("Failed to update saved PDF: \(error)")
                }
            }
        }
    }

    func shareDocument() {
        showShareSheet = true
    }

    func handleSaveComplete(url: URL) {
        showDocumentPicker = false
        resetSession()
    }

    func handleSaveCancel() {
        showDocumentPicker = false
    }

    func handleSaveError(_ error: Error) {
        showDocumentPicker = false
        state = .failed(.saveFailed(underlying: error))
    }
}

enum ScanDestination: Hashable {
    case processing
    case actions(document: Document, pdfData: Data, suggestedFilename: String)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .processing:
            hasher.combine("processing")
        case .actions(let document, _, let filename):
            hasher.combine("actions")
            hasher.combine(document.id)
            hasher.combine(filename)
        }
    }

    static func == (lhs: ScanDestination, rhs: ScanDestination) -> Bool {
        switch (lhs, rhs) {
        case (.processing, .processing):
            return true
        case (.actions(let doc1, _, let name1), .actions(let doc2, _, let name2)):
            return doc1.id == doc2.id && name1 == name2
        default:
            return false
        }
    }
}

struct ScanFlowCoordinator: View {
    @State private var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            // Root: Welcome view
            WelcomeView(
                onScanTapped: viewModel.startScanning
            )
            .overlay {
                // Show loading overlay during processing
                if viewModel.state == .processing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)

                            Text("Processing...")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .navigationDestination(for: ScanDestination.self) { destination in
                switch destination {
                case .processing:
                    // No longer used - replaced with overlay
                    EmptyView()

                case .actions(let document, let pdfData, let suggestedFilename):
                    ScannedDocumentActionsView(
                        document: document,
                        suggestedFilename: suggestedFilename,
                        pdfData: pdfData,
                        editedFilename: $viewModel.editedFilename,
                        onSave: viewModel.saveDocument,
                        onShare: viewModel.shareDocument,
                        onFilenameConfirm: viewModel.confirmEditedFilename,
                        onPDFUpdate: viewModel.updatePDFData,
                        onPrepareEditFilename: viewModel.prepareEditFilename
                    )
                }
            }
            .onChange(of: viewModel.state) { oldState, newState in
                switch newState {
                case .processing:
                    // Processing now shown as overlay, no navigation needed
                    break

                case .completed(let document):
                    if let pdfData = viewModel.currentPDFData {
                        // Navigate to actions screen
                        navigationPath.append(ScanDestination.actions(
                            document: document,
                            pdfData: pdfData,
                            suggestedFilename: viewModel.suggestedFilename
                        ))
                    }

                case .idle:
                    // Clear navigation when resetting
                    navigationPath = NavigationPath()

                case .failed:
                    // Clear navigation on error
                    navigationPath = NavigationPath()

                default:
                    break
                }
            }
            .alert("Error", isPresented: .constant(viewModel.state.isFailed)) {
                Button("Try Again") {
                    viewModel.resetSession()
                }
            } message: {
                if case .failed(let error) = viewModel.state {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $viewModel.showScanner) {
                CameraScannerView(
                    onComplete: { document in
                        viewModel.handleScanComplete(document)
                    },
                    onCancel: {
                        viewModel.handleScanCancel()
                    },
                    onError: { error in
                        viewModel.handleScanError(error)
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $viewModel.showDocumentPicker) {
                if let pdfData = viewModel.currentPDFData {
                    FileSaveView(
                        pdfData: pdfData,
                        suggestedFilename: viewModel.suggestedFilename,
                        onSave: { url in
                            viewModel.handleSaveComplete(url: url)
                        },
                        onCancel: {
                            viewModel.handleSaveCancel()
                        },
                        onError: { error in
                            viewModel.handleSaveError(error)
                        }
                    )
                    .ignoresSafeArea()
                }
            }
            .alert("Camera Permission Required", isPresented: $viewModel.showPermissionAlert) {
                Button("Open Settings", role: .none) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.resetSession()
                }
            } message: {
                Text("Camera access is required to scan documents. Please enable it in Settings.")
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let pdfData = viewModel.currentPDFData {
                    ShareSheet(items: [pdfData], filename: viewModel.suggestedFilename)
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary file with the suggested filename
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        if let pdfData = items.first as? Data {
            try? pdfData.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            return activityVC
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    ScanFlowCoordinator()
}
