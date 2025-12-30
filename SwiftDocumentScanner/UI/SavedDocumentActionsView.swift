import SwiftUI

/// Actions view for saved documents - allows editing and sharing of previously scanned documents
@MainActor
@Observable
final class SavedDocumentActionsViewModel {
    var showDocumentPicker = false
    var showShareSheet = false
    var editedFilename: String = ""
    var document: SavedDocument
    var pdfData: Data = Data()
    var fileSize: String?

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
                DocumentInfoHeader(
                    filename: viewModel.document.displayName,
                    pageCount: viewModel.document.pageCount,
                    createdAt: viewModel.document.createdAt,
                    fileSize: viewModel.fileSize
                )
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
