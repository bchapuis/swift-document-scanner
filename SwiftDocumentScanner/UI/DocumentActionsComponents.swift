import SwiftUI

/// Shared UI components for document actions screens

// MARK: - Document Info Header
struct DocumentInfoHeader: View {
    let filename: String
    let pageCount: Int
    let createdAt: Date?
    let fileSize: String?

    init(filename: String, pageCount: Int, createdAt: Date? = nil, fileSize: String? = nil) {
        self.filename = filename
        self.pageCount = pageCount
        self.createdAt = createdAt
        self.fileSize = fileSize
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DesignSystem.IconSize.header))
                .foregroundStyle(DesignSystem.Colors.success)
                .symbolRenderingMode(.hierarchical)

            // Document info
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(filename)
                    .font(DesignSystem.Typography.screenTitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Metadata line
                HStack(spacing: 4) {
                    if let createdAt = createdAt {
                        Text(createdAt, format: .relative(presentation: .named))
                        Text("•")
                    }
                    Text("\(pageCount) page\(pageCount == 1 ? "" : "s")")
                    if let fileSize = fileSize {
                        Text("•")
                        Text(fileSize)
                    }
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Primary Action Button
struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .primaryButtonStyle()
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}

// MARK: - Secondary Action Button
struct SecondaryActionButton<Destination: View>: View {
    let title: String
    let icon: String
    let destination: Destination
    let onTap: (() -> Void)?
    let isDisabled: Bool

    init(
        title: String,
        icon: String,
        destination: Destination,
        onTap: (() -> Void)? = nil,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.destination = destination
        self.onTap = onTap
        self.isDisabled = isDisabled
    }

    var body: some View {
        NavigationLink(destination: destination) {
            Label(title, systemImage: icon)
                .secondaryButtonStyle()
        }
        .disabled(isDisabled)
        .simultaneousGesture(TapGesture().onEnded {
            onTap?()
        })
        .accessibilityLabel(title)
        .accessibilityHint(isDisabled ? "This action is currently unavailable" : "Double tap to \(title.lowercased())")
    }
}

// MARK: - Secondary Plain Button (non-navigation)
struct SecondaryPlainButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .secondaryButtonStyle()
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}
