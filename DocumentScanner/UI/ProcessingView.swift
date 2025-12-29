import SwiftUI

/// Step 2: Processing screen with progress indicator
struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)

            VStack(spacing: 12) {
                Text("Processing document...")
                    .font(.headline)

                Text("Performing OCR and generating PDF")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressView()
                    .padding(.top, 8)
            }

            Spacer()
        }
    }
}

#Preview {
    ProcessingView()
}
