import SwiftUI
import PDFKit

/// Actions view for scanned documents - allows editing and exporting freshly scanned documents
struct ScannedDocumentActionsView: View {
    let document: Document
    let suggestedFilename: String
    let pdfData: Data
    let editedFilename: Binding<String>
    let onSave: () -> Void
    let onShare: () -> Void
    let onFilenameConfirm: () -> Void
    let onPDFUpdate: (Data) -> Void
    let onPrepareEditFilename: () -> Void
    let savedDocumentId: UUID?
    let repository: DocumentRepository?

    @State private var thumbnail: UIImage?
    @State private var showPreview = false

    init(document: Document, suggestedFilename: String, pdfData: Data, editedFilename: Binding<String>, onSave: @escaping () -> Void, onShare: @escaping () -> Void, onFilenameConfirm: @escaping () -> Void, onPDFUpdate: @escaping (Data) -> Void, onPrepareEditFilename: @escaping () -> Void, savedDocumentId: UUID? = nil, repository: DocumentRepository? = nil) {
        self.document = document
        self.suggestedFilename = suggestedFilename
        self.pdfData = pdfData
        self.editedFilename = editedFilename
        self.onSave = onSave
        self.onShare = onShare
        self.onFilenameConfirm = onFilenameConfirm
        self.onPDFUpdate = onPDFUpdate
        self.onPrepareEditFilename = onPrepareEditFilename
        self.savedDocumentId = savedDocumentId
        self.repository = repository
    }

    private var pdfFileSize: String {
        LocalizationHelper.formatFileSize(Int64(pdfData.count))
    }

    private var previewURL: URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(suggestedFilename)
        try? pdfData.write(to: tempURL)
        return tempURL
    }

    var body: some View {
        List {
            // Header Section
            Section {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Button {
                        showPreview = true
                    } label: {
                        // PDF Thumbnail
                        Group {
                            if let thumbnail = thumbnail {
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
                    .accessibilityLabel("PDF preview")
                    .accessibilityHint("Double tap to view full PDF preview")

                    // Metadata
                    HStack(spacing: 4) {
                        Text(LocalizationHelper.formatRelativeDate(document.createdAt))
                        Text("•")
                        Text(LocalizationHelper.formatPageCount(document.pageCount))
                        Text("•")
                        Text(pdfFileSize)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Document details: \(LocalizationHelper.formatPageCount(document.pageCount)), \(pdfFileSize), scanned \(LocalizationHelper.formatRelativeDate(document.createdAt))")
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: DesignSystem.Spacing.xl, leading: 0, bottom: DesignSystem.Spacing.xl, trailing: 0))
            }

            // Edit Section
            Section {
                // Edit Name
                NavigationLink(destination:
                    FilenameEditorView(filename: editedFilename, onSave: onFilenameConfirm)
                        .onAppear {
                            onPrepareEditFilename()
                        }
                ) {
                    Label("Edit Name", systemImage: "character.cursor.ibeam")
                }
                .accessibilityLabel("Edit document name")
                .accessibilityHint("Current name: \(suggestedFilename.replacingOccurrences(of: ".pdf", with: ""))")

                // Edit Pages
                NavigationLink(destination: PDFEditorView(pdfData: pdfData, onUpdate: onPDFUpdate)) {
                    Label("Edit Pages", systemImage: "doc.on.doc")
                }
                .accessibilityLabel("Edit pages")
                .accessibilityHint("Reorder or delete pages from the PDF")
            } header: {
                Text("Edit")
            }

            // Export Section
            Section {
                // Save to Files
                Button {
                    onSave()
                } label: {
                    Label("Save to Files", systemImage: "folder.badge.plus")
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .accessibilityLabel("Save to Files")
                .accessibilityHint("Choose a location to save the PDF in the Files app")

                // Share
                Button {
                    onShare()
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
        .navigationTitle(suggestedFilename.replacingOccurrences(of: ".pdf", with: ""))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadThumbnail()
        }
        .navigationDestination(isPresented: $showPreview) {
            PDFPreviewView(pdfURL: previewURL)
        }
    }

    private func loadThumbnail() {
        // Try to load cached thumbnail if document was auto-saved
        if let savedDocumentId = savedDocumentId, let repository = repository {
            Task {
                let cachedThumbnail = await repository.loadThumbnail(id: savedDocumentId)
                await MainActor.run {
                    thumbnail = cachedThumbnail
                }
            }
        } else {
            // Fall back to generating thumbnail on-the-fly
            Task.detached(priority: .background) {
                let url = await previewURL
                guard let pdfDocument = PDFDocument(url: url),
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
                    thumbnail = thumbnailImage
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var editedFilename = "2025-12-29 Example Document"

    NavigationStack {
        ScannedDocumentActionsView(
            document: Document(pages: [Page(image: UIImage())]),
            suggestedFilename: "2025-12-29 Example Document.pdf",
            pdfData: Data(),
            editedFilename: $editedFilename,
            onSave: {},
            onShare: {},
            onFilenameConfirm: {},
            onPDFUpdate: { _ in },
            onPrepareEditFilename: {}
        )
    }
}
