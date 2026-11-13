import SwiftUI

extension Color {
    // HSL color system matching the React app's CSS variables

    // Primary: HSL 175 55% 30% → teal
    static let agPrimary = Color(hue: 175/360, saturation: 0.55, brightness: 0.48)
    // Primary lighter variants
    static let agPrimary5 = agPrimary.opacity(0.05)
    static let agPrimary10 = agPrimary.opacity(0.10)
    static let agPrimary15 = agPrimary.opacity(0.15)
    static let agPrimary20 = agPrimary.opacity(0.20)
    static let agPrimary30 = agPrimary.opacity(0.30)

    // Accent: HSL 35 90% 52% → golden/orange
    static let agAccent = Color(hue: 35/360, saturation: 0.90, brightness: 0.80)
    static let agAccent5 = agAccent.opacity(0.05)
    static let agAccent10 = agAccent.opacity(0.10)
    static let agAccent15 = agAccent.opacity(0.15)

    // Success: HSL 152 55% 38% → green
    static let agSuccess = Color(hue: 152/360, saturation: 0.55, brightness: 0.52)
    static let agSuccess8 = agSuccess.opacity(0.08)

    // Warning: HSL 35 90% 52% (same as accent)
    static let agWarning = agAccent
    static let agWarning10 = agAccent.opacity(0.10)
    static let agWarning15 = agAccent.opacity(0.15)
    static let agWarning25 = agAccent.opacity(0.25)

    // Destructive: HSL 0 72% 51% → red
    static let agDestructive = Color(hue: 0, saturation: 0.72, brightness: 0.78)
    static let agDestructive5 = agDestructive.opacity(0.05)
    static let agDestructive10 = agDestructive.opacity(0.10)
    static let agDestructive15 = agDestructive.opacity(0.15)
    static let agDestructive20 = agDestructive.opacity(0.20)

    // Background: white
    static let agBackground = Color.white

    // Card: white
    static let agCard = Color.white

    // Foreground: HSL 220 20% 15% → dark charcoal
    static let agForeground = Color(hue: 220/360, saturation: 0.20, brightness: 0.22)

    // Muted: HSL 40 15% 93%
    static let agMuted = Color(hue: 40/360, saturation: 0.06, brightness: 0.93)

    // Muted Foreground: HSL 220 10% 50%
    static let agMutedForeground = Color(hue: 220/360, saturation: 0.10, brightness: 0.55)

    // Secondary: HSL 40 20% 93%
    static let agSecondary = Color(hue: 40/360, saturation: 0.08, brightness: 0.93)

    // Border: HSL 40 15% 88%
    static let agBorder = Color(hue: 40/360, saturation: 0.06, brightness: 0.88)

    // Terracotta — #B8735A, used for health score / primary accent on detail screens
    static let agTerracotta = Color(hex: "B8735A")
    static let agTerracottaTint = Color(hex: "B8735A").opacity(0.12)

    // Sage — #D4E5B8 tint background, agSuccess for icon fill
    static let agSageTint = Color(hex: "D4E5B8")

    // Cream — pill container background for segmented controls
    static let agCream = Color(hex: "F5F0E8")

    // Onboarding palette (from React Onboarding.tsx)
    static let agOnboardingBrown = Color(hex: "B86D50")     // warm brown CTA
    static let agOnboardingBorder = Color(hex: "C7BCB2")    // light tan border
    static let agOnboardingText = Color(hex: "3A332C")      // dark brown text
    static let agOnboardingSubtext = Color(hex: "746B62")    // medium brown
    static let agOnboardingMuted = Color(hex: "8A8178")      // muted brown

    // Garage palette (Figma "My Garage", nodes 500:2 / 496:2339)
    static let garageInk = Color(hex: "262D43")              // card text, icons
    static let garageTitle = Color(hex: "1F154E")            // "My Garage" heading
    static let garageDot = Color(hex: "D5BDAF")              // heading full stop
    static let garageMuted = Color(hex: "62748E")            // eyebrow, vehicle count
    static let garageHairline = Color(hex: "E2E8F0")
    static let garageCardFill = Color(hex: "F9F7F7")
    static let garageCardBorderPrimary = Color(hex: "919791") // first card
    static let garageCardBorder = Color(hex: "B5BDB5")        // stacked cards
    static let garageGradientTop = Color(hex: "F4F4F4")
    static let garageGradientEnd = Color(hex: "ECE2D3")
    static let garageButtonFill = Color(hex: "F1F5F9")

    // Settings palette (Figma "Settings", node 526:4677)
    static let settingsMuted = Color(hex: "636978")          // captions, section numbers
    static let settingsAccentDot = Color(hex: "7B9C81")      // heading full stop
    static let settingsAvatarFill = Color(hex: "EEE9DF")     // avatar, export card
    static let settingsChipFill = Color(hex: "EAE7E2")       // mileage picker
    static let settingsBackBorder = Color(hex: "E4E2DE")
    static let settingsLabel = Color(hex: "665F58")           // account row labels
    static let settingsRowDivider = Color(hex: "E3DDD5")

    // Severity colors
    static func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .low: return .agSuccess
        case .medium: return .agWarning
        case .high: return .agDestructive
        case .critical: return .agDestructive
        }
    }

    // Maintenance status colors
    static func statusColor(_ status: MaintenanceStatus) -> Color {
        switch status {
        case .overdue: return .agDestructive
        case .dueSoon: return .agWarning
        case .onTrack: return .agSuccess
        case .completed: return .agMutedForeground
        }
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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
