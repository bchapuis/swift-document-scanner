import SwiftUI
import VisionKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var state: ScanSessionState = .idle
    @Published var showScanner = false
    @Published var showPermissionAlert = false
    @Published var showDocumentPicker = false
    @Published var showEditFilename = false
    @Published var showPDFPreview = false
    @Published var showShareSheet = false
    @Published var currentDocument: Document?
    @Published var currentPDFData: Data?
    @Published var suggestedFilename: String = ""
    @Published var editedFilename: String = ""

    private let ocrService = OCRService()
    private let pdfService = PDFService()

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
    }

    // MARK: - Document Processing

    private func processDocument(_ document: Document) async {
        state = .processing

        do {
            // Step 1: Perform OCR on all pages
            let ocrTexts = try await ocrService.recognizeText(from: document.pages)

            // Update document with OCR text
            var updatedDocument = document
            for (index, text) in ocrTexts.enumerated() {
                updatedDocument.updatePageText(at: index, text: text)
            }
            currentDocument = updatedDocument

            // Step 2: Generate PDF with embedded text
            let pdfData = try await pdfService.generatePDF(
                from: updatedDocument.pages,
                withOCRTexts: ocrTexts
            )
            currentPDFData = pdfData

            // Step 3: Generate smart filename from OCR text
            let combinedText = updatedDocument.fullText
            suggestedFilename = await pdfService.generateSmartFilename(from: combinedText)

            // Update state to completed
            state = .completed(updatedDocument)

        } catch {
            state = .failed(.ocrFailed(underlying: error))
        }
    }

    func prepareEditFilename() {
        // Initialize edit field with suggested name (without .pdf)
        editedFilename = suggestedFilename.replacingOccurrences(of: ".pdf", with: "")
        showEditFilename = true
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
        }
        showEditFilename = false
    }

    func showPreview() {
        showPDFPreview = true
    }

    func updatePDFData(_ data: Data) {
        currentPDFData = data
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

struct ScanFlowCoordinator: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .scanning:
                    // Step 1: Welcome
                    WelcomeView(
                        onScanTapped: viewModel.startScanning
                    )

                case .processing:
                    // Step 2: Processing
                    ProcessingView()

                case .completed(let document):
                    // Step 3: Actions
                    ActionsView(
                        document: document,
                        suggestedFilename: viewModel.suggestedFilename,
                        onSave: viewModel.saveDocument,
                        onEditPages: viewModel.showPreview,
                        onEditName: viewModel.prepareEditFilename,
                        onShare: viewModel.shareDocument,
                        onScanAnother: {
                            viewModel.resetSession()
                            viewModel.startScanning()
                        }
                    )

                case .failed(let error):
                    // Error state
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)

                        Text(error.localizedDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            viewModel.resetSession()
                        } label: {
                            Text("Try Again")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
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
            .sheet(isPresented: $viewModel.showEditFilename) {
                FilenameEditorSheet(
                    filename: $viewModel.editedFilename,
                    onSave: {
                        viewModel.confirmEditedFilename()
                    }
                )
            }
            .sheet(isPresented: $viewModel.showPDFPreview) {
                if let pdfData = viewModel.currentPDFData {
                    PDFEditorSheet(pdfData: pdfData) { updatedData in
                        viewModel.updatePDFData(updatedData)
                    }
                }
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
