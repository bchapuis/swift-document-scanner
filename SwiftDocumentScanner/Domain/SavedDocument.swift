import Foundation
import SwiftData

/// Represents a saved scanned document with metadata
@Model
final class SavedDocument {
    @Attribute(.unique) var id: UUID
    var internalFilename: String  // Timestamp-based filename (e.g., "20241229-143052.pdf")
    var displayName: String        // User-friendly name (editable)
    var fileURL: URL
    var createdAt: Date
    var pageCount: Int

    init(id: UUID = UUID(), internalFilename: String, displayName: String, fileURL: URL, createdAt: Date = Date(), pageCount: Int) {
        self.id = id
        self.internalFilename = internalFilename
        self.displayName = displayName
        self.fileURL = fileURL
        self.createdAt = createdAt
        self.pageCount = pageCount
    }
}
