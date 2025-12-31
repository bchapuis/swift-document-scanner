import Vision
import UIKit

/// Represents a piece of recognized text with its position
struct RecognizedText: Sendable {
    let text: String
    /// Bounding box in normalized coordinates (0.0 to 1.0)
    /// Origin is bottom-left (Vision coordinate system)
    let boundingBox: CGRect
    let confidence: Float
}

/// OCR result for a page containing all recognized text elements
struct OCRResult: Sendable {
    let recognizedTexts: [RecognizedText]

    /// Full text content joined with newlines (for backwards compatibility)
    var fullText: String {
        recognizedTexts.map { $0.text }.joined(separator: "\n")
    }
}

/// Service for performing OCR on scanned document images
actor OCRService {
    
    /// Performs OCR on a single image and returns positioned text observations
    /// - Parameter image: The image to process
    /// - Returns: OCR result with text and bounding boxes
    /// - Throws: OCR processing errors
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "OCRService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to convert UIImage to CGImage"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(recognizedTexts: []))
                    return
                }

                // Extract text with bounding boxes from all observations
                let recognizedTexts = observations.compactMap { observation -> RecognizedText? in
                    guard let candidate = observation.topCandidates(1).first else {
                        return nil
                    }

                    return RecognizedText(
                        text: candidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: candidate.confidence
                    )
                }

                continuation.resume(returning: OCRResult(recognizedTexts: recognizedTexts))
            }

            // Configure for accurate recognition with multiple language support
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "es-ES", "fr-FR"]

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Performs OCR on multiple pages concurrently
    /// - Parameter pages: Array of pages to process
    /// - Returns: Array of OCR results for each page
    func recognizeText(from pages: [Page]) async throws -> [OCRResult] {
        try await withThrowingTaskGroup(of: (Int, OCRResult).self) { group in
            // Submit OCR tasks for each page
            for (index, page) in pages.enumerated() {
                group.addTask {
                    let result = try await self.recognizeText(from: page.image)
                    return (index, result)
                }
            }

            // Collect results in order
            var results: [(Int, OCRResult)] = []
            for try await result in group {
                results.append(result)
            }

            // Sort by original index and extract OCR results
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}
