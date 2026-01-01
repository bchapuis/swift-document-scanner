import SwiftUI
import PDFKit
import SwiftData

/// Actions view for saved documents - allows editing and sharing of previously scanned documents
@MainActor
@Observable
final class SavedDocumentActionsViewModel {
    var showDocumentPicker = false
    var showShareSheet = false
    var showPreview = false
    var editedFilename: String = ""
    var document: SavedDocument
    var pdfData: Data = Data()
    var fileSize: String?
    var thumbnail: UIImage?

    private let repository: DocumentRepository

    init(document: SavedDocument, modelContext: ModelContext) {
        self.document = document
        self.repository = DocumentRepository(modelContext: modelContext)
        self.fileSize = getFileSize()
    }

    private func getFileSize() -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: document.fileURL.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    func loadPDFData() {
        // Load PDF data asynchronously
        Task {
            if let data = try? Data(contentsOf: document.fileURL) {
                await MainActor.run {
                    self.pdfData = data
                }
            }
        }
    }

    func loadThumbnail() {
        Task {
            let loadedThumbnail = await repository.loadThumbnail(id: document.id)
            await MainActor.run {
                self.thumbnail = loadedThumbnail
            }
        }
    }

    func saveToFiles() {
        showDocumentPicker = true
    }

    func shareDocument() {
        showShareSheet = true
    }

    func prepareEditFilename() {
        editedFilename = document.displayName.replacingOccurrences(of: ".pdf", with: "")
    }

    func updatePDFData(_ data: Data) {
        pdfData = data
        // Save the updated PDF back to disk and regenerate thumbnail
        Task {
            do {
                try data.write(to: document.fileURL)
                // Regenerate thumbnail after PDF update
                try? await repository.regenerateThumbnail(id: document.id)
                // Reload the updated thumbnail
                let updatedThumbnail = await repository.loadThumbnail(id: document.id)
                await MainActor.run {
                    self.thumbnail = updatedThumbnail
                }
            } catch {
                print("Failed to save updated PDF: \(error)")
            }
        }
    }

    func confirmEditedFilename() {
        var finalFilename = editedFilename.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalFilename.isEmpty {
            if !finalFilename.hasSuffix(".pdf") {
                finalFilename += ".pdf"
            }

            // Update local document
            document.displayName = finalFilename

            // Update in repository
            Task {
                try? await repository.updateDisplayName(id: document.id, newDisplayName: finalFilename)
            }
        }
    }

    func handleSaveComplete(url: URL) {
        showDocumentPicker = false
    }

    func handleSaveCancel() {
        showDocumentPicker = false
    }

    func handleSaveError(_ error: Error) {
        showDocumentPicker = false
    }
}

struct SavedDocumentActionsView: View {
    @Environment(\.modelContext) private var modelContext
    let document: SavedDocument

    var body: some View {
        SavedDocumentActionsViewContent(document: document, modelContext: modelContext)
    }
}

private struct SavedDocumentActionsViewContent: View {
    @State private var viewModel: SavedDocumentActionsViewModel

    init(document: SavedDocument, modelContext: ModelContext) {
        _viewModel = State(wrappedValue: SavedDocumentActionsViewModel(document: document, modelContext: modelContext))
    }

    private var metadataAccessibilityLabel: String {
        var label = "Document details: \(viewModel.document.pageCount) page\(viewModel.document.pageCount == 1 ? "" : "s")"
        if let fileSize = viewModel.fileSize {
            label += ", \(fileSize)"
        }
        label += ", scanned \(viewModel.document.createdAt.formatted(.relative(presentation: .named)))"
        return label
    }

    var body: some View {
        List {
            // Header Section
            Section {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Button {
                        viewModel.showPreview = true
                    } label: {
                        // PDF Thumbnail
                        Group {
                            if let thumbnail = viewModel.thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary.opacity(0.1))

                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(height: 176)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.pdfData.isEmpty)
                    .accessibilityLabel("PDF preview")
                    .accessibilityHint(viewModel.pdfData.isEmpty ? "Preview loading" : "Double tap to view full PDF preview")

                    // Metadata
                    HStack(spacing: 4) {
                        Text(viewModel.document.createdAt, format: .relative(presentation: .named))
                        Text("•")
                        Text("\(viewModel.document.pageCount) page\(viewModel.document.pageCount == 1 ? "" : "s")")
                        if let fileSize = viewModel.fileSize {
                            Text("•")
                            Text(fileSize)
                        }
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(metadataAccessibilityLabel)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: DesignSystem.Spacing.xl, leading: 0, bottom: DesignSystem.Spacing.xl, trailing: 0))
            }

            // Edit Section
            Section {
                // Edit Name
                NavigationLink(destination:
                    FilenameEditorView(filename: $viewModel.editedFilename, onSave: viewModel.confirmEditedFilename)
                        .onAppear {
                            viewModel.prepareEditFilename()
                        }
                ) {
                    Label("Edit Name", systemImage: "character.cursor.ibeam")
                }
                .accessibilityLabel("Edit document name")
                .accessibilityHint("Current name: \(viewModel.document.displayName.replacingOccurrences(of: ".pdf", with: ""))")

                // Edit Pages
                NavigationLink(destination: PDFEditorView(pdfData: viewModel.pdfData, onUpdate: viewModel.updatePDFData)) {
                    Label("Edit Pages", systemImage: "doc.on.doc")
                }
                .disabled(viewModel.pdfData.isEmpty)
                .accessibilityLabel("Edit pages")
                .accessibilityHint(viewModel.pdfData.isEmpty ? "Loading PDF data" : "Reorder or delete pages from the PDF")
            } header: {
                Text("Edit")
            }

            // Export Section
            Section {
                // Save to Files
                Button {
                    viewModel.saveToFiles()
                } label: {
                    Label("Save to Files", systemImage: "folder.badge.plus")
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .accessibilityLabel("Save to Files")
                .accessibilityHint("Choose a location to save the PDF in the Files app")

                // Share
                Button {
                    viewModel.shareDocument()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
                .accessibilityHint("Share the PDF via email, messages, or other apps")
            } header: {
                Text("Export")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.document.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadPDFData()
            viewModel.loadThumbnail()
        }
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            FileSaveView(
                pdfData: viewModel.pdfData,
                suggestedFilename: viewModel.document.displayName,
                onSave: viewModel.handleSaveComplete,
                onCancel: viewModel.handleSaveCancel,
                onError: viewModel.handleSaveError
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: [viewModel.pdfData], filename: viewModel.document.displayName)
        }
        .navigationDestination(isPresented: $viewModel.showPreview) {
            PDFPreviewView(pdfURL: viewModel.document.fileURL)
        }
    }
}

#Preview {
    NavigationStack {
        SavedDocumentActionsView(
            document: SavedDocument(
                internalFilename: "20251229-120000.pdf",
                displayName: "Example Document.pdf",
                fileURL: URL(fileURLWithPath: "/tmp/example.pdf"),
                pageCount: 3
            )
        )
    }
}
