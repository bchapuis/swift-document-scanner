import SwiftUI

/// Step 3: Document actions screen with save/edit/share options
struct ActionsView: View {
    let document: Document
    let suggestedFilename: String
    let onSave: () -> Void
    let onEditPages: () -> Void
    let onEditName: () -> Void
    let onShare: () -> Void
    let onScanAnother: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            // Compact document info
            VStack(spacing: 8) {
                Text(suggestedFilename)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                    .font(.caption)
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
                    // Edit Pages
                    Button {
                        onEditPages()
                    } label: {
                        Label("Edit Pages", systemImage: "doc.on.doc")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                    }

                    // Edit Name
                    Button {
                        onEditName()
                    } label: {
                        Label("Edit Name", systemImage: "character.cursor.ibeam")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                    }

                    // Share
                    Button {
                        onShare()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                    }
                }

                // Scan Another - Tertiary action
                Button {
                    onScanAnother()
                } label: {
                    Text("Scan Another Document")
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
    ActionsView(
        document: Document(pages: [Page(image: UIImage())]),
        suggestedFilename: "2025-12-29 Example Document.pdf",
        onSave: {},
        onEditPages: {},
        onEditName: {},
        onShare: {},
        onScanAnother: {}
    )
}
