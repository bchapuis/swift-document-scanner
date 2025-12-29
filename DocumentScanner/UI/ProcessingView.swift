import SwiftUI

/// Step 2: Processing screen with progress indicator
struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated processing icon
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text("Processing Document")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Performing OCR and generating PDF")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

#Preview {
    ProcessingView()
}
