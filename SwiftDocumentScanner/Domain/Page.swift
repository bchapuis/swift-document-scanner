import UIKit
import Foundation

/// Represents a single scanned page in a document
struct Page: Identifiable, Sendable {
    let id: UUID
    let image: UIImage
    let scannedAt: Date
    
    /// OCR-extracted text from this page (populated asynchronously)
    var extractedText: String?
    
    init(image: UIImage, scannedAt: Date = Date()) {
        self.id = UUID()
        self.image = image
        self.scannedAt = scannedAt
        self.extractedText = nil
    }
}
