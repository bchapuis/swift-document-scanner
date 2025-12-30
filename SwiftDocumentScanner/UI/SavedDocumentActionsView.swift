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

    private let repository = DocumentRepository()

    init(document: SavedDocument) {
        self.document = document
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
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            // Header with document info
            DocumentInfoHeader(
                filename: viewModel.document.displayName,
                pageCount: viewModel.document.pageCount
            )

            // Action buttons
            VStack(spacing: DesignSystem.Spacing.buttonGroup) {
                // Save to Files - Primary action
                PrimaryActionButton(
                    title: "Save to Files",
                    icon: "folder.badge.plus",
                    action: viewModel.saveToFiles
                )

                // Secondary actions
                VStack(spacing: DesignSystem.Spacing.secondaryButtons) {
                    // Edit Name
                    SecondaryActionButton(
                        title: "Edit Name",
                        icon: "character.cursor.ibeam",
                        destination: FilenameEditorView(
                            filename: $viewModel.editedFilename,
                            onSave: viewModel.confirmEditedFilename
                        ),
                        onTap: viewModel.prepareEditFilename
                    )

                    // Edit Pages
                    SecondaryActionButton(
                        title: "Edit Pages",
                        icon: "doc.on.doc",
                        destination: PDFEditorView(pdfData: viewModel.pdfData, onUpdate: viewModel.updatePDFData),
                        isDisabled: viewModel.pdfData.isEmpty
                    )

                    // Share
                    SecondaryPlainButton(
                        title: "Share Document",
                        icon: "square.and.arrow.up",
                        action: viewModel.shareDocument
                    )
                }
            }
            .padding(.horizontal)

            Spacer()
        }
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
