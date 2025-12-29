import SwiftUI

/// Step 1: Welcome screen with scan button
struct WelcomeView: View {
    let onScanTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon/Logo
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Document Scanner")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Scan documents and save as searchable PDFs")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

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

            Spacer()
        }
    }
}

#Preview {
    WelcomeView(onScanTapped: {})
}
