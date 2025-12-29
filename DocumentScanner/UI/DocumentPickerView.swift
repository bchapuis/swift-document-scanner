import SwiftUI
import UniformTypeIdentifiers

/// SwiftUI wrapper for UIDocumentPickerViewController to save PDFs
struct DocumentPickerView: UIViewControllerRepresentable {
    let pdfData: Data
    let suggestedFilename: String
    let onSave: (URL) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSave: onSave, onCancel: onCancel, onError: onError)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Create a temporary file with the PDF data
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suggestedFilename)
        
        do {
            try pdfData.write(to: tempURL)
        } catch {
            context.coordinator.onError(error)
        }
        
        // Create document picker for saving (export mode)
        let picker = UIDocumentPickerViewController(forExporting: [tempURL])
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSave: (URL) -> Void
        let onCancel: () -> Void
        let onError: (Error) -> Void
        
        init(onSave: @escaping (URL) -> Void,
             onCancel: @escaping () -> Void,
             onError: @escaping (Error) -> Void) {
            self.onSave = onSave
            self.onCancel = onCancel
            self.onError = onError
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onCancel()
                return
            }
            
            onSave(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
