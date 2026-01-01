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

// MARK: - Localization Helper

/// Utility for locale-aware formatting of dates, numbers, and file sizes
enum LocalizationHelper {

    // MARK: - Date Formatting

    /// Formats a date using the user's current locale
    /// - Parameters:
    ///   - date: The date to format
    ///   - style: The date style (default: .medium)
    /// - Returns: Localized date string
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    /// Formats a date and time using the user's current locale
    /// - Parameters:
    ///   - date: The date to format
    ///   - dateStyle: The date style (default: .medium)
    ///   - timeStyle: The time style (default: .short)
    /// - Returns: Localized date and time string
    static func formatDateTime(_ date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    /// Formats a date as a relative string (e.g., "2 days ago", "yesterday")
    /// - Parameter date: The date to format
    /// - Returns: Localized relative date string
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Number Formatting

    /// Formats a number using the user's current locale
    /// - Parameter number: The number to format
    /// - Returns: Localized number string
    static func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// Formats a decimal number using the user's current locale
    /// - Parameters:
    ///   - number: The decimal number to format
    ///   - minimumFractionDigits: Minimum number of fraction digits (default: 0)
    ///   - maximumFractionDigits: Maximum number of fraction digits (default: 2)
    /// - Returns: Localized decimal string
    static func formatDecimal(_ number: Double, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    // MARK: - File Size Formatting

    /// Formats a file size in bytes to a human-readable string using the user's locale
    /// - Parameter bytes: The file size in bytes
    /// - Returns: Localized file size string (e.g., "1.5 MB", "3.2 KB")
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true

        // Use the current locale's number format
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1

        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Pluralization

    /// Formats a page count with proper pluralization
    /// - Parameter count: The number of pages
    /// - Returns: Localized pluralized string (e.g., "1 page", "5 pages")
    static func formatPageCount(_ count: Int) -> String {
        // Use String(localized:) with pluralization support
        let format = String(localized: "%lld page", comment: "Number of pages")
        return String.localizedStringWithFormat(format, count)
    }

    /// Formats a character count with proper pluralization
    /// - Parameter count: The number of characters
    /// - Returns: Localized pluralized string (e.g., "1 character", "10 characters")
    static func formatCharacterCount(_ count: Int) -> String {
        let format = String(localized: "%lld characters", comment: "Number of characters")
        return String.localizedStringWithFormat(format, count)
    }

    // MARK: - Language and Region

    /// Returns the current locale identifier
    static var currentLocaleIdentifier: String {
        Locale.current.identifier
    }

    /// Returns the current language code (e.g., "en", "fr", "de")
    static var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Returns the current region code (e.g., "US", "FR", "DE")
    static var currentRegionCode: String? {
        Locale.current.region?.identifier
    }

    /// Checks if the current locale uses right-to-left layout
    static var isRightToLeft: Bool {
        Locale.current.language.characterDirection == .rightToLeft
    }
}
