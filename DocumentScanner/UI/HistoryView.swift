import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var documents: [SavedDocument] = []

    private let repository = DocumentRepository()

    func loadDocuments() {
        Task {
            documents = await repository.fetchAll()
        }
    }

    func deleteDocument(_ document: SavedDocument) {
        Task {
            try? await repository.delete(id: document.id)
            documents = await repository.fetchAll()
        }
    }
}

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        List {
            if viewModel.documents.isEmpty {
                emptyStateRow
            } else {
                ForEach(viewModel.documents) { document in
                    NavigationLink(destination: SavedDocumentDetailView(document: document)) {
                        DocumentRow(document: document)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteDocument(document)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Past Scans")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadDocuments()
        }
    }

    private var emptyStateRow: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Scans Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your scanned documents will appear here")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

struct DocumentRow: View {
    let document: SavedDocument

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(document.createdAt, style: .date)
                    Text("•")
                    Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// Detail view for saved documents - reuses ActionsView pattern
@MainActor
final class SavedDocumentDetailViewModel: ObservableObject {
    @Published var showDocumentPicker = false
    @Published var showShareSheet = false
    @Published var editedFilename: String = ""
    @Published var document: SavedDocument
    @Published var pdfData: Data = Data()

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

struct SavedDocumentDetailView: View {
    @StateObject private var viewModel: SavedDocumentDetailViewModel

    init(document: SavedDocument) {
        _viewModel = StateObject(wrappedValue: SavedDocumentDetailViewModel(document: document))
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            // Document info
            VStack(spacing: 8) {
                Text(viewModel.document.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("\(viewModel.document.pageCount) page\(viewModel.document.pageCount == 1 ? "" : "s")")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Action buttons (reusing ActionsView pattern)
            VStack(spacing: 12) {
                // Save to Files - Primary action
                Button {
                    viewModel.saveToFiles()
                } label: {
                    Label("Save to Files", systemImage: "folder.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }

                // Secondary actions
                VStack(spacing: 6) {
                    NavigationLink(destination: PDFEditorView(pdfData: viewModel.pdfData) { updatedData in
                        viewModel.updatePDFData(updatedData)
                    }) {
                        Label("Edit Pages", systemImage: "doc.on.doc")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.pdfData.isEmpty)

                    NavigationLink(destination: FilenameEditorView(
                        filename: $viewModel.editedFilename,
                        onSave: {
                            viewModel.confirmEditedFilename()
                        }
                    )) {
                        Label("Edit Name", systemImage: "character.cursor.ibeam")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        viewModel.prepareEditFilename()
                    })

                    Button {
                        viewModel.shareDocument()
                    } label: {
                        Label("Share Document", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                    }
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
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: [viewModel.document.fileURL], filename: viewModel.document.displayName)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
