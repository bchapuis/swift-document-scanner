import SwiftUI
import VisionKit

/// SwiftUI wrapper for VNDocumentCameraViewController
struct DocumentScannerView: UIViewControllerRepresentable {
    let onComplete: (Document) -> Void
    let onCancel: () -> Void
    let onError: (ScanError) -> Void
    
    func makeCoordinator() -> DocumentScannerCoordinator {
        DocumentScannerCoordinator(
            onComplete: onComplete,
            onCancel: onCancel,
            onError: onError
        )
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
}
