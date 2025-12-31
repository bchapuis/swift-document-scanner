import SwiftUI
import QuickLook

/// SwiftUI wrapper for QuickLook PDF preview
struct PDFPreviewView: UIViewControllerRepresentable {
    let pdfURL: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.navigationItem.largeTitleDisplayMode = .never
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(pdfURL: pdfURL)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let pdfURL: URL

        init(pdfURL: URL) {
            self.pdfURL = pdfURL
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return pdfURL as QLPreviewItem
        }
    }
}
