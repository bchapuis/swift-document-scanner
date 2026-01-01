import SwiftUI

/// Centralized design system for consistent UI/UX patterns across the app
enum DesignSystem {

    // MARK: - Spacing

    /// Standard spacing scale for consistent layouts
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32

        /// Spacing for action button groups
        static let buttonGroup: CGFloat = 12

        /// Spacing for secondary action buttons within a group
        static let secondaryButtons: CGFloat = 6
    }

    // MARK: - Corner Radius

    /// Standard corner radius values for UI elements
    enum CornerRadius {
        /// Standard radius for buttons and cards
        static let standard: CGFloat = 12

        /// Smaller radius for compact elements
        static let compact: CGFloat = 8
    }

    // MARK: - Typography

    /// Standard typography styles with semantic naming
    /// All fonts support Dynamic Type for accessibility
    enum Typography {
        /// Large screen title (e.g., Welcome screen) - scales with Dynamic Type
        static let screenTitleLarge: Font = .largeTitle.weight(.bold)

        /// Standard screen title (e.g., Processing, Actions screens) - scales with Dynamic Type
        static let screenTitle: Font = .title2.weight(.semibold)

        /// Primary action button text - scales with Dynamic Type
        static let primaryButton: Font = .headline

        /// Secondary action button text - scales with Dynamic Type
        static let secondaryButton: Font = .subheadline

        /// Body text for descriptions - scales with Dynamic Type
        static let body: Font = .body

        /// Caption text for metadata - scales with Dynamic Type
        static let caption: Font = .caption

        /// Subheadline text - scales with Dynamic Type
        static let subheadline: Font = .subheadline

        /// Title text - scales with Dynamic Type
        static let title: Font = .title

        /// Title 3 text - scales with Dynamic Type
        static let title3: Font = .title3
    }

    // MARK: - Icon Sizes

    /// Standard icon sizes
    enum IconSize {
        /// Large icon for screen headers (e.g., success, processing states)
        static let header: CGFloat = 64

        /// Medium icon for list items
        static let listItem: CGFloat = 40

        /// Standard icon for buttons
        static let button: CGFloat = 24
    }

    // MARK: - Colors

    /// Semantic color palette
    enum Colors {
        /// Primary brand color (actions, links)
        static let primary: Color = .blue

        /// Success state color
        static let success: Color = .green

        /// Processing/loading state color
        static let processing: Color = .orange

        /// Destructive action color
        static let destructive: Color = .red

        /// Secondary UI element background
        static let secondaryBackground: Color = Color.secondary.opacity(0.15)
    }

    // MARK: - Button Styles

    /// Primary button style (blue background, white text)
    struct PrimaryButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(Typography.primaryButton)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Colors.primary)
                .foregroundStyle(.white)
                .cornerRadius(CornerRadius.standard)
        }
    }

    /// Secondary button style (gray background, primary text)
    struct SecondaryButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(Typography.secondaryButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .padding(.horizontal)
                .background(Colors.secondaryBackground)
                .foregroundStyle(.primary)
                .cornerRadius(CornerRadius.standard)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply primary button styling
    func primaryButtonStyle() -> some View {
        modifier(DesignSystem.PrimaryButtonStyle())
    }

    /// Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        modifier(DesignSystem.SecondaryButtonStyle())
    }
}
