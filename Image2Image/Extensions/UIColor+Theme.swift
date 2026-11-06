import UIKit

extension UIColor {
    static let appBackground = UIColor.fromHex("#0f0f23")
    static let cardBackground = UIColor.fromHex("#1a1a2e")
    static let inputBackground = UIColor.fromHex("#16213e")
    static let primary = UIColor.fromHex("#7b2ff7")
    static let secondary = UIColor.fromHex("#3b82f6")
    static let accent = UIColor.fromHex("#f472b6")
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor.fromHex("#9ca3af")
    static let borderColor = UIColor.fromHex("#2d3748")
    static let success = UIColor.fromHex("#10b981")
    static let errorColor = UIColor.fromHex("#ef4444")
    static let warning = UIColor.fromHex("#f59e0b")

    static let darkBackground = appBackground
    static let darkSecondary = cardBackground
    static let darkPrimaryText = textPrimary
    static let darkSecondaryText = textSecondary
    static let darkBorder = borderColor
    static let darkAccent = primary

    convenience init(hex: String) {
        self.init(cgColor: UIColor.fromHex(hex).cgColor)
    }

    static func fromHex(_ hex: String) -> UIColor {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        var a: UInt64 = 255
        var r: UInt64 = 0
        var g: UInt64 = 0
        var b: UInt64 = 0

        if hex.count == 3 {
            r = (int >> 8) * 17
            g = (int >> 4 & 0xF) * 17
            b = (int & 0xF) * 17
        } else if hex.count == 6 {
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF
        } else if hex.count == 8 {
            a = int >> 24
            r = int >> 16 & 0xFF
            g = int >> 8 & 0xFF
            b = int & 0xFF
        }

        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0
        let alpha = CGFloat(a) / 255.0

        return UIColor(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

struct Spacing {
    static let none: CGFloat = 0
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

struct CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

struct GradientColors {
    static let primaryGradient: [UIColor] = [UIColor.primary, UIColor.secondary]
    static let accentGradient: [UIColor] = [UIColor.accent, UIColor.primary]
    static let backgroundGradient: [UIColor] = [UIColor.appBackground, UIColor.cardBackground]
}
