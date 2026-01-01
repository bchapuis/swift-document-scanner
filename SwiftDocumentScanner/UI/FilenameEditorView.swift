import SwiftUI

/// View for editing PDF filename (works both as sheet and navigation destination)
struct FilenameEditorView: View {
    @Binding var filename: String
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("Document name", text: $filename, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .lineLimit(2...4)
                    .submitLabel(.done)
                    .onSubmit {
                        saveAndDismiss()
                    }
                    .accessibilityLabel("Document name")
                    .accessibilityHint("Enter a name for your document")
            } header: {
                Text("Document Name")
            } footer: {
                if !filename.isEmpty {
                    Text(LocalizationHelper.formatCharacterCount(filename.count))
                        .accessibilityLabel(LocalizationHelper.formatCharacterCount(filename.count))
                }
            }
        }
        .navigationTitle("Edit Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveAndDismiss()
                }
                .disabled(filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Done")
                .accessibilityHint(filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Enter a document name to continue" : "Save the document name and go back")
            }

            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                    .accessibilityLabel("Dismiss keyboard")
                }
            }
        }
        .task {
            // Small delay to ensure binding is updated before focusing
            try? await Task.sleep(for: .milliseconds(100))
            isTextFieldFocused = true
        }
    }

    private func saveAndDismiss() {
        guard !filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        onSave()
        dismiss()
    }
}

#Preview {
    FilenameEditorView(
        filename: .constant("2025-12-29 Example Document"),
        onSave: {}
    )
}
