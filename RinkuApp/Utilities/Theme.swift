import SwiftUI

struct Theme {
    // MARK: - Colors
    struct Colors {
        static let primary = Color(hex: "3A86FF")
        static let primaryDark = Color(hex: "2F6ED0")
        static let primaryLight = Color(hex: "E7F0FF")

        static let success = Color(hex: "00B894")
        static let warning = Color(hex: "FFB703")
        static let danger = Color(hex: "E63946")

        static let textPrimary = Color(hex: "0B1221")
        static let textSecondary = Color(hex: "4A5568")

        static let border = Color(hex: "E5E7EB")
        static let background = Color.white

        static let successLight = Color.green.opacity(0.1)
        static let warningLight = Color.yellow.opacity(0.1)
        static let dangerLight = Color.red.opacity(0.1)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 24
        static let pill: CGFloat = 100
    }

    // MARK: - Font Sizes
    struct FontSize {
        static let caption: CGFloat = 13
        static let body: CGFloat = 16
        static let h2: CGFloat = 20
        static let h1: CGFloat = 28
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
