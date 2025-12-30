import Vision
import UIKit

/// Service for performing OCR on scanned document images
actor OCRService {
    
    /// Performs OCR on a single image and returns extracted text
    /// - Parameter image: The image to process
    /// - Returns: Extracted text from the image
    /// - Throws: OCR processing errors
    func recognizeText(from image: UIImage) async throws -> String {
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
                    continuation.resume(returning: "")
                    return
                }
                
                // Extract text from all observations
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
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
    /// - Returns: Array of extracted text for each page
    func recognizeText(from pages: [Page]) async throws -> [String] {
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            // Submit OCR tasks for each page
            for (index, page) in pages.enumerated() {
                group.addTask {
                    let text = try await self.recognizeText(from: page.image)
                    return (index, text)
                }
            }
            
            // Collect results in order
            var results: [(Int, String)] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort by original index and extract text
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}
