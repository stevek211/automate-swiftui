import SwiftUI

extension Color {
    // All tokens below are computed from the active palette (Theme/Palette.swift),
    // so switching palettes recolors every screen. Names are kept so views don't change.

    // Brand (teal in the Current palette)
    static var agPrimary: Color { theme.brand }
    static var agPrimary5: Color { theme.brand.opacity(0.05) }
    static var agPrimary10: Color { theme.brand.opacity(0.10) }
    static var agPrimary15: Color { theme.brand.opacity(0.15) }
    static var agPrimary20: Color { theme.brand.opacity(0.20) }
    static var agPrimary30: Color { theme.brand.opacity(0.30) }

    // Accent (golden in the Current palette)
    static var agAccent: Color { theme.accent }
    static var agAccent5: Color { theme.accent.opacity(0.05) }
    static var agAccent10: Color { theme.accent.opacity(0.10) }
    static var agAccent15: Color { theme.accent.opacity(0.15) }

    // Status
    static var agSuccess: Color { theme.success }
    static var agSuccess8: Color { theme.success.opacity(0.08) }
    static var agWarning: Color { theme.warning }
    static var agWarning10: Color { theme.warning.opacity(0.10) }
    static var agWarning15: Color { theme.warning.opacity(0.15) }
    static var agWarning25: Color { theme.warning.opacity(0.25) }
    static var agDestructive: Color { theme.danger }
    static var agDestructive5: Color { theme.danger.opacity(0.05) }
    static var agDestructive10: Color { theme.danger.opacity(0.10) }
    static var agDestructive15: Color { theme.danger.opacity(0.15) }
    static var agDestructive20: Color { theme.danger.opacity(0.20) }

    // Surfaces and text
    static var agBackground: Color { theme.background }
    static var agCard: Color { theme.card }
    static var agForeground: Color { theme.ink }
    static var agMuted: Color { theme.surfaceAlt }
    static var agMutedForeground: Color { theme.mutedText }
    static var agSecondary: Color { theme.surfaceAlt }
    static var agBorder: Color { theme.border }

    // Warm secondary (terracotta in the Current palette)
    static var agTerracotta: Color { theme.secondary }
    static var agTerracottaTint: Color { theme.secondary.opacity(0.12) }
    static var agSageTint: Color { theme.success.opacity(0.25) }
    static var agCream: Color { theme.surfaceAlt }

    // Onboarding
    static var agOnboardingBrown: Color { theme.secondary }
    static var agOnboardingBorder: Color { theme.borderStrong }
    static var agOnboardingText: Color { theme.ink }
    static var agOnboardingSubtext: Color { theme.mutedText }
    static var agOnboardingMuted: Color { theme.faintText }

    // Garage
    static var garageInk: Color { theme.ink }
    static var garageTitle: Color { theme.heading }
    static var garageDot: Color { theme.secondary.opacity(0.5) }
    static var garageMuted: Color { theme.mutedText }
    static var garageHairline: Color { theme.hairline }
    static var garageCardFill: Color { theme.card }
    static var garageCardBorderPrimary: Color { theme.mutedText.opacity(0.6) }
    static var garageCardBorder: Color { theme.borderStrong }
    static var garageGradientTop: Color { theme.background }
    static var garageGradientEnd: Color { theme.surfaceAlt }
    static var garageButtonFill: Color { theme.surfaceAlt }

    // Settings
    static var settingsMuted: Color { theme.mutedText }
    static var settingsAccentDot: Color { theme.brand }
    static var settingsAvatarFill: Color { theme.surfaceAlt }
    static var settingsChipFill: Color { theme.surfaceAlt }
    static var settingsBackBorder: Color { theme.border }
    static var settingsLabel: Color { theme.mutedText }
    static var settingsRowDivider: Color { theme.hairline }

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
