import Foundation

/// Repository for persisting and retrieving saved documents
actor DocumentRepository {
    private let fileManager = FileManager.default
    private let metadataKey = "SavedDocuments"

    /// Documents directory for storing PDFs
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Save a PDF document with metadata
    /// - Parameters:
    ///   - pdfData: The PDF file data
    ///   - displayName: The user-facing filename (including .pdf extension)
    ///   - pageCount: Number of pages in the document
    /// - Returns: The saved document metadata
    func save(pdfData: Data, displayName: String, pageCount: Int) throws -> SavedDocument {
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

        // Update metadata list
        var documents = fetchAllMetadata()
        documents.append(savedDocument)
        saveMetadata(documents)

        return savedDocument
    }

    /// Update the display name of a saved document
    /// - Parameters:
    ///   - id: The document ID
    ///   - newDisplayName: The new user-facing filename
    func updateDisplayName(id: UUID, newDisplayName: String) throws {
        var documents = fetchAllMetadata()

        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "DocumentRepository", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Document not found"
            ])
        }

        documents[index].displayName = newDisplayName
        saveMetadata(documents)
    }

    /// Fetch all saved documents, sorted by date (newest first)
    func fetchAll() -> [SavedDocument] {
        let metadata = fetchAllMetadata()

        // Filter out documents whose files no longer exist
        return metadata.filter { fileManager.fileExists(atPath: $0.fileURL.path) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Delete a saved document
    /// - Parameter id: The document ID
    func delete(id: UUID) throws {
        var documents = fetchAllMetadata()

        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            return
        }

        let document = documents[index]

        // Remove file from disk
        if fileManager.fileExists(atPath: document.fileURL.path) {
            try fileManager.removeItem(at: document.fileURL)
        }

        // Remove from metadata
        documents.remove(at: index)
        saveMetadata(documents)
    }

    // MARK: - Private Helpers

    private func fetchAllMetadata() -> [SavedDocument] {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let documents = try? JSONDecoder().decode([SavedDocument].self, from: data) else {
            return []
        }
        return documents
    }

    private func saveMetadata(_ documents: [SavedDocument]) {
        guard let data = try? JSONEncoder().encode(documents) else {
            return
        }
        UserDefaults.standard.set(data, forKey: metadataKey)
    }
}
