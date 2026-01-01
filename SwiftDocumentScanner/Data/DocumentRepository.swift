import Foundation
import SwiftData
import UIKit

/// Repository for persisting and retrieving saved documents
actor DocumentRepository {
    private let fileManager = FileManager.default
    private let modelContext: ModelContext
    private let thumbnailService = ThumbnailService()

    /// Documents directory for storing PDFs
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Save a PDF document with metadata
    /// - Parameters:
    ///   - pdfData: The PDF file data
    ///   - displayName: The user-facing filename (including .pdf extension)
    ///   - pageCount: Number of pages in the document
    /// - Returns: The saved document metadata
    func save(pdfData: Data, displayName: String, pageCount: Int) async throws -> SavedDocument {
        // Generate timestamp-based internal filename (YYYYMMdd-HHmmss.pdf)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let internalFilename = "\(timestamp).pdf"

        let fileURL = documentsDirectory.appendingPathComponent(internalFilename)

        // Write PDF to disk
        try pdfData.write(to: fileURL)

        // Create metadata
        let savedDocument = SavedDocument(
            internalFilename: internalFilename,
            displayName: displayName,
            fileURL: fileURL,
            pageCount: pageCount
        )

        // Insert into SwiftData
        modelContext.insert(savedDocument)
        try modelContext.save()

        // Generate and save thumbnail
        try? await thumbnailService.generateAndSaveThumbnail(for: fileURL, documentID: savedDocument.id)

        return savedDocument
    }

    /// Update the display name of a saved document
    /// - Parameters:
    ///   - id: The document ID
    ///   - newDisplayName: The new user-facing filename
    func updateDisplayName(id: UUID, newDisplayName: String) throws {
        let descriptor = FetchDescriptor<SavedDocument>(
            predicate: #Predicate { $0.id == id }
        )

        guard let document = try modelContext.fetch(descriptor).first else {
            throw NSError(domain: "DocumentRepository", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Document not found"
            ])
        }

        document.displayName = newDisplayName
        try modelContext.save()
    }

    /// Fetch all saved documents, sorted by date (newest first)
    func fetchAll() -> [SavedDocument] {
        let descriptor = FetchDescriptor<SavedDocument>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let documents = try? modelContext.fetch(descriptor) else {
            return []
        }

        // Filter out documents whose files no longer exist
        return documents.filter { fileManager.fileExists(atPath: $0.fileURL.path) }
    }

    /// Regenerate thumbnail for a saved document
    /// - Parameter id: The document ID
    func regenerateThumbnail(id: UUID) async throws {
        let descriptor = FetchDescriptor<SavedDocument>(
            predicate: #Predicate { $0.id == id }
        )

        guard let document = try modelContext.fetch(descriptor).first else {
            throw NSError(domain: "DocumentRepository", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Document not found"
            ])
        }

        try await thumbnailService.generateAndSaveThumbnail(for: document.fileURL, documentID: document.id)
    }

    /// Load thumbnail for a saved document
    /// - Parameter id: The document ID
    /// - Returns: The cached thumbnail image, or nil if not found
    func loadThumbnail(id: UUID) async -> UIImage? {
        return await thumbnailService.loadThumbnail(for: id)
    }

    /// Delete a saved document
    /// - Parameter id: The document ID
    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<SavedDocument>(
            predicate: #Predicate { $0.id == id }
        )

        guard let document = try modelContext.fetch(descriptor).first else {
            return
        }

        // Remove file from disk
        if fileManager.fileExists(atPath: document.fileURL.path) {
            try fileManager.removeItem(at: document.fileURL)
        }

        // Remove thumbnail
        try? await thumbnailService.deleteThumbnail(for: document.id)

        // Remove from SwiftData
        modelContext.delete(document)
        try modelContext.save()
    }
}
