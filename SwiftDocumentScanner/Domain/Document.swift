import Foundation

/// Represents a complete scanned document with multiple pages
struct Document: Identifiable, Sendable {
    let id: UUID
    var pages: [Page]
    let createdAt: Date
    
    /// Combined text from all pages (for smart filename generation)
    var fullText: String {
        pages.compactMap(\.extractedText).joined(separator: "\n")
    }
    
    /// Number of pages in the document
    var pageCount: Int {
        pages.count
    }
    
    init(pages: [Page] = [], createdAt: Date = Date()) {
        self.id = UUID()
        self.pages = pages
        self.createdAt = createdAt
    }
    
    /// Add a new page to the document
    mutating func addPage(_ page: Page) {
        pages.append(page)
    }
    
    /// Update OCR result for a specific page
    mutating func updatePageOCR(at index: Int, result: OCRResult) {
        guard pages.indices.contains(index) else { return }
        pages[index].ocrResult = result
    }

    /// Update OCR text for a specific page (backwards compatibility)
    mutating func updatePageText(at index: Int, text: String) {
        guard pages.indices.contains(index) else { return }
        // Create a simple OCR result with no bounding boxes
        pages[index].ocrResult = OCRResult(recognizedTexts: [
            RecognizedText(text: text, boundingBox: .zero, confidence: 1.0)
        ])
    }
}
