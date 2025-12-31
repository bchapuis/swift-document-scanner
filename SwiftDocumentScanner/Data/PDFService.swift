import PDFKit
import UIKit
import CoreText

/// Service for generating PDF documents with embedded text layers
actor PDFService {
    
    /// Generates a PDF document from pages with embedded OCR text
    /// - Parameters:
    ///   - pages: Array of scanned pages
    ///   - ocrResults: Array of OCR results corresponding to each page
    /// - Returns: PDF document data
    /// - Throws: PDF generation errors
    func generatePDF(from pages: [Page], withOCRResults ocrResults: [OCRResult]) async throws -> Data {
        let pdfDocument = PDFDocument()

        for (index, page) in pages.enumerated() {
            guard let pdfPage = createPDFPage(from: page.image, withOCRResult: ocrResults[safe: index]) else {
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
    private func createPDFPage(from image: UIImage, withOCRResult ocrResult: OCRResult?) -> PDFPage? {
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

        // If we have OCR results, embed positioned text as selectable layers
        if let ocrResult = ocrResult, !ocrResult.recognizedTexts.isEmpty {
            drawPositionedText(ocrResult.recognizedTexts, in: context, pageRect: pageRect)
        }

        UIGraphicsEndPDFContext()

        // Create PDFPage from the generated data
        guard let pdfDocument = PDFDocument(data: pdfData as Data),
              let page = pdfDocument.page(at: 0) else {
            return nil
        }

        return page
    }

    /// Draws positioned text elements at their exact Vision-detected locations
    /// - Parameters:
    ///   - recognizedTexts: Array of recognized text with bounding boxes
    ///   - context: PDF graphics context
    ///   - pageRect: Page dimensions
    private func drawPositionedText(_ recognizedTexts: [RecognizedText], in context: CGContext, pageRect: CGRect) {
        context.saveGState()

        // Vision uses bottom-left origin with normalized coordinates (0-1)
        // Need to flip Y coordinate for PDF drawing context
        for recognizedText in recognizedTexts {
            // Convert normalized bounding box to page coordinates
            let bbox = recognizedText.boundingBox
            let textRect = CGRect(
                x: bbox.origin.x * pageRect.width,
                y: pageRect.height - (bbox.origin.y + bbox.height) * pageRect.height, // Flip Y
                width: bbox.width * pageRect.width,
                height: bbox.height * pageRect.height
            )

            // Calculate font size to fit the bounding box height
            let fontSize = textRect.height * 0.85

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.clear // Invisible but selectable
            ]

            let attributedString = NSAttributedString(string: recognizedText.text, attributes: attributes)

            // Draw the text in its bounding box
            // Note: We don't need to flip coordinates because both Vision and PDF use bottom-left origin
            attributedString.draw(in: textRect)
        }

        context.restoreGState()
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
