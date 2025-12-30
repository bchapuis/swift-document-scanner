import Foundation

/// Tracks the state of an active scanning session
enum ScanSessionState: Sendable, Equatable {
    case idle
    case scanning
    case processing
    case completed(Document)
    case failed(ScanError)

    static func == (lhs: ScanSessionState, rhs: ScanSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning), (.processing, .processing):
            return true
        case (.completed, .completed), (.failed, .failed):
            return true
        default:
            return false
        }
    }

    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

/// Errors that can occur during scanning
enum ScanError: LocalizedError, Sendable {
    case cameraPermissionDenied
    case cameraUnavailable
    case scanCancelled
    case ocrFailed(underlying: Error?)
    case pdfGenerationFailed(underlying: Error?)
    case saveFailed(underlying: Error?)
    case unknown(underlying: Error?)
    
    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Camera access is required to scan documents. Please enable it in Settings."
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .scanCancelled:
            return "Scan was cancelled."
        case .ocrFailed(let error):
            return "Text recognition failed\(error.map { ": \($0.localizedDescription)" } ?? "")."
        case .pdfGenerationFailed(let error):
            return "PDF generation failed\(error.map { ": \($0.localizedDescription)" } ?? "")."
        case .saveFailed(let error):
            return "Failed to save document\(error.map { ": \($0.localizedDescription)" } ?? "")."
        case .unknown(let error):
            return "An unexpected error occurred\(error.map { ": \($0.localizedDescription)" } ?? "")."
        }
    }
}
