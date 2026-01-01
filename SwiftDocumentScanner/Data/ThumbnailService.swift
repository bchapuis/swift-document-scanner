import PDFKit
import UIKit

/// Service for generating and caching PDF thumbnails
actor ThumbnailService {
    private let fileManager = FileManager.default

    /// Directory for storing thumbnail images
    private var thumbnailsDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbnailsDir = documentsDirectory.appendingPathComponent("Thumbnails", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: thumbnailsDir.path) {
            try? fileManager.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)
        }

        return thumbnailsDir
    }

    /// Generate and save a thumbnail for a PDF document
    /// - Parameters:
    ///   - pdfURL: URL to the PDF file
    ///   - documentID: Unique identifier for the document
    /// - Returns: URL to the saved thumbnail image
    func generateAndSaveThumbnail(for pdfURL: URL, documentID: UUID) async throws -> URL {
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let firstPage = pdfDocument.page(at: 0) else {
            throw ThumbnailError.failedToLoadPDF
        }

        let thumbnail = await generateThumbnail(from: firstPage)
        let thumbnailURL = thumbnailURL(for: documentID)

        guard let imageData = thumbnail.pngData() else {
            throw ThumbnailError.failedToGenerateImage
        }

        try imageData.write(to: thumbnailURL)
        return thumbnailURL
    }

    /// Load a cached thumbnail for a document
    /// - Parameter documentID: Unique identifier for the document
    /// - Returns: The cached thumbnail image, or nil if not found
    func loadThumbnail(for documentID: UUID) async -> UIImage? {
        let url = thumbnailURL(for: documentID)

        guard fileManager.fileExists(atPath: url.path),
              let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData) else {
            return nil
        }

        return image
    }

    /// Delete a cached thumbnail
    /// - Parameter documentID: Unique identifier for the document
    func deleteThumbnail(for documentID: UUID) throws {
        let url = thumbnailURL(for: documentID)

        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    /// Check if a thumbnail exists for a document
    /// - Parameter documentID: Unique identifier for the document
    /// - Returns: true if thumbnail exists, false otherwise
    func thumbnailExists(for documentID: UUID) -> Bool {
        let url = thumbnailURL(for: documentID)
        return fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Private Methods

    /// Get the URL for a thumbnail file
    private func thumbnailURL(for documentID: UUID) -> URL {
        return thumbnailsDirectory.appendingPathComponent("\(documentID.uuidString).png")
    }

    /// Generate a thumbnail image from a PDF page
    /// - Parameter page: The PDF page to thumbnail
    /// - Returns: A UIImage thumbnail
    private func generateThumbnail(from page: PDFPage) async -> UIImage {
        await Task.detached(priority: .userInitiated) {
            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 396 / max(pageRect.width, pageRect.height) // 132pt * 3 for @3x
            let thumbnailSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            let thumbnailImage = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(origin: .zero, size: thumbnailSize))

                context.cgContext.translateBy(x: 0, y: thumbnailSize.height)
                context.cgContext.scaleBy(x: scale, y: -scale)

                page.draw(with: .mediaBox, to: context.cgContext)
            }

            return thumbnailImage
        }.value
    }
}

// MARK: - Errors

enum ThumbnailError: Error {
    case failedToLoadPDF
    case failedToGenerateImage
}
