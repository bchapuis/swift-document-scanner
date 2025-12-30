import PDFKit
import UIKit
import CoreText

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

        // If we have OCR text, embed it as selectable text layer
        if let text = text, !text.isEmpty {
            drawSelectableText(text, in: context, pageRect: pageRect)
        }

        UIGraphicsEndPDFContext()

        // Create PDFPage from the generated data
        guard let pdfDocument = PDFDocument(data: pdfData as Data),
              let page = pdfDocument.page(at: 0) else {
            return nil
        }

        return page
    }

    /// Draws text in the PDF context in a way that makes it selectable but invisible
    private func drawSelectableText(_ text: String, in context: CGContext, pageRect: CGRect) {
        context.saveGState()

        // Create attributed string with transparent text
        let fontSize: CGFloat = 12.0
        let font = UIFont.systemFont(ofSize: fontSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.clear // Invisible but selectable
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)

        // Create a text frame using Core Text
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)

        // Create a path for the text frame (covering the entire page with margins)
        let textRect = CGRect(
            x: 20,
            y: 20,
            width: pageRect.width - 40,
            height: pageRect.height - 40
        )
        let path = CGPath(rect: textRect, transform: nil)

        // Create the frame
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attributedString.length), path, nil)

        // Flip the coordinate system for Core Text (iOS uses different coordinate system)
        context.textMatrix = .identity
        context.translateBy(x: 0, y: pageRect.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // Draw the text frame
        CTFrameDraw(frame, context)

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
