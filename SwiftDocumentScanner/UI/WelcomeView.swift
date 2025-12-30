import SwiftUI

/// Step 1: Welcome screen with scan button
struct WelcomeView: View {
    let onScanTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon/Logo
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .accessibilityLabel("Document Scanner app icon")

            VStack(spacing: 8) {
                Text("Document Scanner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                Text("Scan documents and save as searchable PDFs")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Scan Button
            Button {
                onScanTapped()
            } label: {
                Label("Scan Document", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .accessibilityLabel("Scan Document")
            .accessibilityHint("Double tap to start scanning a new document with your camera")

            // View Past Scans Button
            NavigationLink(destination: HistoryView()) {
                Label("View Past Scans", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .accessibilityLabel("View Past Scans")
            .accessibilityHint("Double tap to view your previously scanned documents")

            Spacer()
        }
    }
}

#Preview {
    WelcomeView(onScanTapped: {})
}
