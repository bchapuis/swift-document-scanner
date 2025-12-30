import Foundation

/// Represents a saved scanned document with metadata
struct SavedDocument: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let internalFilename: String  // Timestamp-based filename (e.g., "20241229-143052.pdf")
    var displayName: String        // User-friendly name (editable)
    let fileURL: URL
    let createdAt: Date
    let pageCount: Int

    init(id: UUID = UUID(), internalFilename: String, displayName: String, fileURL: URL, createdAt: Date = Date(), pageCount: Int) {
        self.id = id
        self.internalFilename = internalFilename
        self.displayName = displayName
        self.fileURL = fileURL
        self.createdAt = createdAt
        self.pageCount = pageCount
    }

    // Implement Hashable based on ID for collection stability
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Include displayName in equality for SwiftUI updates
    static func == (lhs: SavedDocument, rhs: SavedDocument) -> Bool {
        lhs.id == rhs.id && lhs.displayName == rhs.displayName
    }

    // Suppress automatic Codable synthesis for hash consistency
    enum CodingKeys: String, CodingKey {
        case id, internalFilename, displayName, fileURL, createdAt, pageCount
    }
}
