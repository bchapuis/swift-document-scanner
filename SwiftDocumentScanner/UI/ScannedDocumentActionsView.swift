import SwiftUI

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

    private var pdfFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(pdfData.count), countStyle: .file)
    }

    var body: some View {
        List {
            // Header Section
            Section {
                DocumentInfoHeader(
                    filename: suggestedFilename,
                    pageCount: document.pageCount,
                    createdAt: document.createdAt,
                    fileSize: pdfFileSize
                )
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
        .navigationTitle("Document Ready")
        .navigationBarTitleDisplayMode(.inline)
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
