import UIKit
import Foundation

/// Represents a single scanned page in a document
struct Page: Identifiable, Sendable {
    let id: UUID
    let image: UIImage
    let scannedAt: Date

    /// OCR result with positioned text (populated asynchronously)
    var ocrResult: OCRResult?

    /// Convenience accessor for extracted text (backwards compatibility)
    var extractedText: String? {
        ocrResult?.fullText
    }

    init(image: UIImage, scannedAt: Date = Date()) {
        self.id = UUID()
        self.image = image
        self.scannedAt = scannedAt
        self.ocrResult = nil
    }
}
