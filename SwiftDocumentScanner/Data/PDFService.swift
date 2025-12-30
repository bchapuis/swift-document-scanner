import PDFKit
import UIKit

/// Service for generating PDF documents with embedded text layers
actor PDFService {
    
    /// Generates a PDF document from pages with embedded OCR text
    /// - Parameters:
    ///   - pages: Array of scanned pages
    ///   - ocrTexts: Array of OCR text corresponding to each page
    /// - Returns: PDF document data
    /// - Throws: PDF generation errors
    func generatePDF(from pages: [Page], withOCRTexts ocrTexts: [String]) async throws -> Data {
        let pdfDocument = PDFDocument()
        
        for (index, page) in pages.enumerated() {
            guard let pdfPage = createPDFPage(from: page.image, withText: ocrTexts[safe: index]) else {
                throw NSError(domain: "PDFService", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create PDF page at index \(index)"
                ])
            }
            
            pdfDocument.insert(pdfPage, at: index)
        }
        
        guard let pdfData = pdfDocument.dataRepresentation() else {
            throw NSError(domain: "PDFService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to generate PDF data"
            ])
        }
        
        return pdfData
    }
    
    /// Creates a PDF page from an image with embedded text layer
    private func createPDFPage(from image: UIImage, withText text: String?) -> PDFPage? {
        // Use the image's actual pixel dimensions for the PDF page
        let imageScale = image.scale
        let pixelWidth = image.size.width * imageScale
        let pixelHeight = image.size.height * imageScale

        // Create page rect in points (72 points = 1 inch)
        let pageRect = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)

        // Create PDF data using UIGraphics
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        UIGraphicsBeginPDFPage()

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return nil
        }

        // Draw the image filling the entire page
        image.draw(in: pageRect)

        // If we have OCR text, add it as invisible text layer for searchability
        if let text = text, !text.isEmpty {
            // Save the graphics state
            context.saveGState()

            // Set text to invisible mode for searchability
            context.setTextDrawingMode(.invisible)

            // Draw the text in a small font at the top-left
            // This makes the PDF searchable without affecting appearance
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 1.0),
                .foregroundColor: UIColor.clear
            ]

            let textRect = CGRect(x: 0, y: 0, width: pageRect.width, height: pageRect.height)
            (text as NSString).draw(in: textRect, withAttributes: textAttributes)

            // Restore the graphics state
            context.restoreGState()
        }

        UIGraphicsEndPDFContext()

        // Create PDFPage from the generated data
        guard let pdfDocument = PDFDocument(data: pdfData as Data),
              let page = pdfDocument.page(at: 0) else {
            return nil
        }

        return page
    }
    
    /// Generates a smart filename for the PDF based on OCR text
    /// - Parameter ocrText: Combined OCR text from all pages
    /// - Returns: Filename in format "YYYY-MM-DD [Smart Name].pdf"
    func generateSmartFilename(from ocrText: String) async -> String {
        let smartFilenameService = SmartFilenameService()
        let baseName = await smartFilenameService.generateFilename(from: ocrText)
        return "\(baseName).pdf"
    }

    /// Generates a fallback date-based filename for the PDF
    /// - Returns: Filename in format "YYYY-MM-DD Scan.pdf"
    func generateDateBasedFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "\(dateString) Scan.pdf"
    }
}

// Safe array subscript extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
