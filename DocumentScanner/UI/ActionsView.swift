import SwiftUI

/// Step 3: Document actions screen with save/edit/share options
struct ActionsView: View {
    let document: Document
    let suggestedFilename: String
    let pdfData: Data
    let editedFilename: Binding<String>
    let onSave: () -> Void
    let onShare: () -> Void
    let onBackToHome: () -> Void
    let onFilenameConfirm: () -> Void
    let onPDFUpdate: (Data) -> Void
    let onPrepareEditFilename: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            // Document info
            VStack(spacing: 8) {
                Text(suggestedFilename)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Action buttons (stacked vertically)
            VStack(spacing: 12) {
                // Save to Files - Primary action
                Button {
                    onSave()
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
                VStack(spacing: 6) {
                    // Edit Pages - NavigationLink
                    NavigationLink(destination: PDFEditorView(pdfData: pdfData, onUpdate: onPDFUpdate)) {
                        Label("Edit Pages", systemImage: "doc.on.doc")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                    }

                    // Edit Name - NavigationLink
                    NavigationLink(destination: FilenameEditorView(filename: editedFilename, onSave: onFilenameConfirm)) {
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
                        onPrepareEditFilename()
                    })

                    // Share
                    Button {
                        onShare()
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

                // Back to Home - Tertiary action
                Button {
                    onBackToHome()
                } label: {
                    Text("Back to Home")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var editedFilename = "2025-12-29 Example Document"

    ActionsView(
        document: Document(pages: [Page(image: UIImage())]),
        suggestedFilename: "2025-12-29 Example Document.pdf",
        pdfData: Data(),
        editedFilename: $editedFilename,
        onSave: {},
        onShare: {},
        onBackToHome: {},
        onFilenameConfirm: {},
        onPDFUpdate: { _ in },
        onPrepareEditFilename: {}
    )
}
