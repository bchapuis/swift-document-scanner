import SwiftUI
import PDFKit

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

    private let repository = DocumentRepository()

    init(document: SavedDocument) {
        self.document = document
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
        let fileURL = document.fileURL
        Task.detached(priority: .background) {
            guard let pdfDocument = PDFDocument(url: fileURL),
                  let page = pdfDocument.page(at: 0) else {
                return
            }

            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 396 / max(pageRect.width, pageRect.height) // 132pt * 3 for @3x
            let thumbnailSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            let thumbnailImage = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(origin: .zero, size: thumbnailSize))

                context.cgContext.translateBy(x: 0, y: thumbnailSize.height)
                context.cgContext.scaleBy(x: scale, y: -scale)

                page.draw(with: .mediaBox, to: context.cgContext)
            }

            await MainActor.run {
                self.thumbnail = thumbnailImage
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
        // Save the updated PDF back to disk
        Task {
            do {
                try data.write(to: document.fileURL)
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
    @State private var viewModel: SavedDocumentActionsViewModel

    init(document: SavedDocument) {
        _viewModel = State(wrappedValue: SavedDocumentActionsViewModel(document: document))
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
                                        .fill(Color.red.gradient)

                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white)
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

                // Edit Pages
                NavigationLink(destination: PDFEditorView(pdfData: viewModel.pdfData, onUpdate: viewModel.updatePDFData)) {
                    Label("Edit Pages", systemImage: "doc.on.doc")
                }
                .disabled(viewModel.pdfData.isEmpty)
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

                // Share
                Button {
                    viewModel.shareDocument()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
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
            ShareSheet(items: [viewModel.document.fileURL], filename: viewModel.document.displayName)
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
