import SwiftUI

/// View for editing PDF filename (works both as sheet and navigation destination)
struct FilenameEditorView: View {
    @Binding var filename: String
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .accessibilityLabel("Edit filename")

            VStack(spacing: 8) {
                // Instructions
                Text("Edit Filename")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                // Text field
                TextField("Document name", text: $filename)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        saveAndDismiss()
                    }
                    .padding(.top, 4)
                    .accessibilityLabel("Document name")
                    .accessibilityHint("Enter a name for your document")

                // Character count hint
                Text("\(filename.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Done button
            Button {
                saveAndDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Done")
            .accessibilityHint("Double tap to save filename")
        }
        .padding()
        .navigationTitle("Edit Filename")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-focus text field when view appears
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
