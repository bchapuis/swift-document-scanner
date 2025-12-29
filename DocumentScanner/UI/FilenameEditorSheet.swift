import SwiftUI

/// Sheet view for editing PDF filename
struct FilenameEditorSheet: View {
    @Binding var filename: String
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    // Instructions
                    Text("Edit Filename")
                        .font(.title2)
                        .fontWeight(.semibold)

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

                    // Character count hint
                    Text("\(filename.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            }
            .padding()
            .navigationTitle("Edit Filename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Auto-focus text field when sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
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
    FilenameEditorSheet(
        filename: .constant("2025-12-29 Example Document"),
        onSave: {}
    )
}
