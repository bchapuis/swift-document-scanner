import SwiftUI
import SwiftData

@main
struct SwiftDocumentScannerApp: App {
    var body: some Scene {
        WindowGroup {
            ScanFlowCoordinator()
        }
        .modelContainer(for: SavedDocument.self)
    }
}
