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
            } header: {
                Text("Document Name")
            } footer: {
                if !filename.isEmpty {
                    Text("\(filename.count) characters")
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
            }

            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
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
