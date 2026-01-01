import SwiftUI

/// Step 1: Welcome screen with scan button
struct WelcomeView: View {
    let onScanTapped: () -> Void
    @State private var navigateToHistory = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        List {
            Section {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: dynamicTypeSize.isAccessibilitySize ? 30 : 60)

                    // App Icon
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 60 : 80, weight: .thin))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityHidden(true)

                    Spacer()
                        .frame(height: dynamicTypeSize.isAccessibilitySize ? 16 : 32)

                    // Title
                    Text("Document Scanner")
                        .font(DesignSystem.Typography.screenTitleLarge)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()
                        .frame(height: 12)

                    // Subtitle
                    Text("Scan documents and save as\nsearchable PDFs")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                        .frame(height: dynamicTypeSize.isAccessibilitySize ? 24 : 48)

                    // Primary Action
                    Button {
                        onScanTapped()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Scan Document")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44) // Minimum touch target
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityLabel("Scan Document")
                    .accessibilityHint("Opens the camera to scan a new document")

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
                        .frame(minHeight: 44) // Minimum touch target
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityLabel("View Past Scans")
                    .accessibilityHint("Shows your previously scanned documents")

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
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    WelcomeView(onScanTapped: {})
}
