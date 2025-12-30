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

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            // Header with document info
            DocumentInfoHeader(
                filename: suggestedFilename,
                pageCount: document.pageCount
            )

            // Action buttons (stacked vertically)
            VStack(spacing: DesignSystem.Spacing.buttonGroup) {
                // Save to Files - Primary action
                PrimaryActionButton(
                    title: "Save to Files",
                    icon: "folder.badge.plus",
                    action: onSave
                )

                // Secondary actions
                VStack(spacing: DesignSystem.Spacing.secondaryButtons) {
                    // Edit Name
                    SecondaryActionButton(
                        title: "Edit Name",
                        icon: "character.cursor.ibeam",
                        destination: FilenameEditorView(filename: editedFilename, onSave: onFilenameConfirm),
                        onTap: onPrepareEditFilename
                    )

                    // Edit Pages
                    SecondaryActionButton(
                        title: "Edit Pages",
                        icon: "doc.on.doc",
                        destination: PDFEditorView(pdfData: pdfData, onUpdate: onPDFUpdate)
                    )

                    // Share
                    SecondaryPlainButton(
                        title: "Share Document",
                        icon: "square.and.arrow.up",
                        action: onShare
                    )
                }
            }
            .padding(.horizontal)

            Spacer()
        }
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
