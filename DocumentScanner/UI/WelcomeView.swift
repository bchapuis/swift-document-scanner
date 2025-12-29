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

            VStack(spacing: 8) {
                Text("Document Scanner")
                    .font(.largeTitle)
                    .fontWeight(.bold)

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

            Spacer()
        }
    }
}

#Preview {
    WelcomeView(onScanTapped: {})
}
