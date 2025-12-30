import SwiftUI

/// Step 1: Welcome screen with scan button
struct WelcomeView: View {
    let onScanTapped: () -> Void
    @State private var navigateToHistory = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    // App Icon
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .symbolRenderingMode(.hierarchical)

                    Spacer()
                        .frame(height: 32)

                    // Title
                    Text("Document Scanner")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .tracking(-0.5)

                    Spacer()
                        .frame(height: 12)

                    // Subtitle
                    Text("Scan documents and save as\nsearchable PDFs")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                        .frame(height: 48)

                    // Primary Action
                    Button {
                        onScanTapped()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Scan Document")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Spacer()
                        .frame(height: 12)

                    // Secondary Action
                    Button {
                        navigateToHistory = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                            Text("View Past Scans")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(isPresented: $navigateToHistory) {
            HistoryView()
        }
    }
}

#Preview {
    WelcomeView(onScanTapped: {})
}
