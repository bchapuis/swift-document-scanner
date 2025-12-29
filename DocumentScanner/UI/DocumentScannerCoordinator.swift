import SwiftUI
import VisionKit

/// UIKit coordinator to bridge VNDocumentCameraViewController with SwiftUI
final class DocumentScannerCoordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    let onComplete: (Document) -> Void
    let onCancel: () -> Void
    let onError: (ScanError) -> Void
    
    init(
        onComplete: @escaping (Document) -> Void,
        onCancel: @escaping () -> Void,
        onError: @escaping (ScanError) -> Void
    ) {
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onError = onError
    }
    
    // MARK: - VNDocumentCameraViewControllerDelegate
    
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        var document = Document()
        
        // Extract all scanned pages
        for pageIndex in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageIndex)
            let page = Page(image: image)
            document.addPage(page)
        }
        
        controller.dismiss(animated: true) { [weak self] in
            self?.onComplete(document)
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.onCancel()
        }
    }
    
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: Error
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.onError(.unknown(underlying: error))
        }
    }
}
