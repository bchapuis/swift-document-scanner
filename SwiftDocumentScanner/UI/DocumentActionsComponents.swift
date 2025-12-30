import SwiftUI

/// Shared UI components for document actions screens

// MARK: - Document Info Header
struct DocumentInfoHeader: View {
    let filename: String
    let pageCount: Int

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DesignSystem.IconSize.header))
                .foregroundStyle(DesignSystem.Colors.success)
                .accessibilityLabel("Document ready")

            // Document info
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(filename)
                    .font(DesignSystem.Typography.screenTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Document name: \(filename)")

                Text("\(pageCount) page\(pageCount == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(pageCount) page\(pageCount == 1 ? "" : "s")")
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
