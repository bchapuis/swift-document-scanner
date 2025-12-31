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

    @State private var thumbnail: UIImage?
    @State private var showPreview = false

    private var pdfFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(pdfData.count), countStyle: .file)
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

                    // Metadata
                    HStack(spacing: 4) {
                        Text(document.createdAt, format: .relative(presentation: .named))
                        Text("•")
                        Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                        Text("•")
                        Text(pdfFileSize)
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
                    FilenameEditorView(filename: editedFilename, onSave: onFilenameConfirm)
                        .onAppear {
                            onPrepareEditFilename()
                        }
                ) {
                    Label("Edit Name", systemImage: "character.cursor.ibeam")
                }

                // Edit Pages
                NavigationLink(destination: PDFEditorView(pdfData: pdfData, onUpdate: onPDFUpdate)) {
                    Label("Edit Pages", systemImage: "doc.on.doc")
                }
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

                // Share
                Button {
                    onShare()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
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
