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

    func saveDocument(editFilename: Bool) {
        guard currentPDFData != nil else { return }

        if editFilename {
            prepareEditFilename()
        } else {
            // Use suggested filename directly
            showDocumentPicker = true
        }
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
        // Could show a success message here
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

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // App Icon/Logo placeholder
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("Document Scanner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Scan documents and save as searchable PDFs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()

                // Scan Button (hidden when document is ready)
                if case .completed = viewModel.state {
                    // Don't show scan button when document is ready
                } else {
                    Button {
                        viewModel.startScanning()
                    } label: {
                        Label("Scan Document", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.state == .scanning)
                }

                // Status messages and actions
                if case .processing = viewModel.state {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Processing document...")
                            .font(.headline)

                        Text("Performing OCR and generating PDF")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }

                if case .failed(let error) = viewModel.state {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if case .completed(let document) = viewModel.state {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)

                        Text("PDF Ready!")
                            .font(.headline)

                        Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Suggested filename display
                        Text(viewModel.suggestedFilename)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)

                        // Action buttons (stacked vertically)
                        VStack(spacing: 12) {
                            // Save to Files - Primary action
                            Button {
                                viewModel.saveDocument(editFilename: false)
                            } label: {
                                Label("Save to Files", systemImage: "folder.badge.plus")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }

                            // Secondary actions in lighter style
                            VStack(spacing: 8) {
                                // Edit Pages
                                Button {
                                    viewModel.showPreview()
                                } label: {
                                    Label("Edit Pages", systemImage: "doc.on.doc")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                        .background(Color.secondary.opacity(0.15))
                                        .foregroundStyle(.primary)
                                        .cornerRadius(10)
                                }

                                // Edit Name
                                Button {
                                    viewModel.prepareEditFilename()
                                } label: {
                                    Label("Edit Name", systemImage: "character.cursor.ibeam")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                        .background(Color.secondary.opacity(0.15))
                                        .foregroundStyle(.primary)
                                        .cornerRadius(10)
                                }

                                // Share
                                Button {
                                    viewModel.shareDocument()
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                        .background(Color.secondary.opacity(0.15))
                                        .foregroundStyle(.primary)
                                        .cornerRadius(10)
                                }
                            }

                            // Scan Another - Tertiary action
                            Button {
                                viewModel.resetSession()
                                viewModel.startScanning()
                            } label: {
                                Text("Scan Another Document")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showScanner) {
                DocumentScannerView(
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
                    DocumentPickerView(
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
                FilenameEditorView(
                    filename: $viewModel.editedFilename,
                    onSave: {
                        viewModel.confirmEditedFilename()
                    }
                )
            }
            .sheet(isPresented: $viewModel.showPDFPreview) {
                if let pdfData = viewModel.currentPDFData {
                    PDFPreviewView(pdfData: pdfData) { updatedData in
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
    HomeView()
}
