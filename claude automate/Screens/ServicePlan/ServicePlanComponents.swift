import SwiftUI

// MARK: - Design Tokens

enum ServicePlanPalette {
    static let bg          = Color(red: 0.98, green: 0.97, blue: 0.96)
    static let cardBg      = Color(red: 0.99, green: 0.99, blue: 0.99)

    static let teal        = Color(red: 0, green: 0.47, blue: 0.44)
    static let tealDeep    = Color(hex: "295350")
    static let tealBright  = Color(hex: "007970")
    static let tealTintChip = Color(hex: "E8EFEE")
    static let tealTintBtn  = Color(hex: "E6EFED")

    static let chipSage    = Color(red: 0.80, green: 0.84, blue: 0.68)

    static let greenTint   = Color(hex: "DCFCE7")
    static let greenText   = Color(hex: "008236")
    static let replaceTint = Color(hex: "CBFBF1")

    static let neutralChipBg  = Color(hex: "F3F4F6")
    static let neutralChipTxt = Color(hex: "4A5565")

    static let borderLight    = Color(red: 0.90, green: 0.91, blue: 0.92)
    static let borderDefault  = Color(hex: "E5E7EB")
    static let borderSoft     = Color(hex: "C8C8C8")
    static let borderCheckbox = Color(hex: "D1D5DC")
    static let dotColor       = Color(red: 0.60, green: 0.63, blue: 0.69)

    static let textPrimary   = Color(red: 0.06, green: 0.09, blue: 0.16)
    static let textSecondary = Color(red: 0.21, green: 0.25, blue: 0.33)
    static let textMuted     = Color(red: 0.29, green: 0.33, blue: 0.40)
    static let textBody      = Color(hex: "4A5565")
    static let textFaint     = Color(red: 0.60, green: 0.63, blue: 0.69)
}

// MARK: - Circular Miles Gauge

struct MilesGauge: View {
    let milesUntilNext: Int
    /// 0–1, how far we are through the current interval.
    let progress: Double

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(ServicePlanPalette.borderLight, lineWidth: 9)

            // Progress arc
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    ServicePlanPalette.teal,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text(milesUntilNext.formatted())
                    .font(.quicksand(.semibold, size: 22))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                    .monospacedDigit()
                Text("mi to next")
                    .font(.quicksand(.regular, size: 11))
                    .tracking(1.28)
                    .foregroundStyle(ServicePlanPalette.textMuted)
            }
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Log Service Button

struct LogServiceButton: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            Text("Log this service")
                .font(.quicksand(.semibold, size: 11))
                .tracking(0.28)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(ServicePlanPalette.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Action Pill

struct ActionPill: View {
    let action: ServiceAction

    private var bg: Color {
        switch action {
        case .replace:              return ServicePlanPalette.replaceTint
        case .adjust, .clean:       return ServicePlanPalette.tealTintChip
        case .perform:              return ServicePlanPalette.greenTint
        case .rotate:               return ServicePlanPalette.tealTintChip
        case .inspect, .check:      return ServicePlanPalette.neutralChipBg
        }
    }

    private var fg: Color {
        switch action {
        case .replace, .adjust, .clean, .rotate: return ServicePlanPalette.teal
        case .perform:              return ServicePlanPalette.greenText
        case .inspect, .check:      return ServicePlanPalette.neutralChipTxt
        }
    }

    var body: some View {
        Text(action.displayText)
            .font(.quicksand(.semibold, size: 9))
            .kerning(0.2)
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Service Item Row

struct ServiceItemRow: View {
    let item: ServicePlanItem
    @State private var checked = false

    var body: some View {
        Button { checked.toggle() } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(ServicePlanPalette.borderCheckbox, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(checked ? ServicePlanPalette.teal : Color.white)
                    )
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(checked ? 1 : 0)
                    )

                if let asset = ServiceItemIcon.customAsset(for: item.category) {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: ServiceItemIcon.sfSymbol(for: item.category, action: item.action))
                        .font(.system(size: 11))
                        .foregroundStyle(ServicePlanPalette.textBody)
                        .frame(width: 14, height: 14)
                }

                Text(item.name)
                    .font(.quicksand(.medium, size: 12))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                    .strikethrough(checked, color: ServicePlanPalette.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)
                ActionPill(action: item.action).fixedSize()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category → icon mapping

enum ServiceItemIcon {
    static func customAsset(for category: String) -> String? {
        switch category.lowercased() {
        case "oil": return "icon-oil-can"
        default:    return nil
        }
    }

    static func sfSymbol(for category: String, action: ServiceAction) -> String {
        switch category.lowercased() {
        case "oil":          return "drop.fill"
        case "tires":        return "arrow.triangle.2.circlepath"
        case "brakes":       return "car.side"
        case "filters":      return "wind"
        case "battery":      return "bolt.fill"
        case "transmission": return "gearshape.2.fill"
        case "cooling":      return "thermometer"
        case "fluids":       return "drop"
        case "belts":        return "arrow.triangle.2.circlepath.circle"
        case "ignition":     return "bolt.circle.fill"
        case "suspension":   return "car.rear"
        case "engine":       return "engine.combustion.fill"
        case "exhaust":      return "smoke.fill"
        case "electrical":   return "bolt"
        default:
            switch action {
            case .inspect: return "magnifyingglass"
            case .replace: return "wrench.fill"
            case .rotate:  return "arrow.triangle.2.circlepath"
            default:       return "wrench.and.screwdriver"
            }
        }
    }
}

// MARK: - Compact Upcoming Row

struct CompactMilestoneRow: View {
    let milestone: ServicePlanMilestone
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(alignment: .bottom, spacing: 0) {
                    // Mileage + months
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(milestone.mileage.formatted())
                            .font(.quicksand(.semibold, size: 18))
                            .foregroundStyle(ServicePlanPalette.textPrimary)
                        if let months = milestone.months {
                            Text("\(months) mo")
                                .font(.quicksand(.medium, size: 10))
                                .foregroundStyle(ServicePlanPalette.textMuted)
                        }
                    }

                    Spacer()

                    // Item summary + chevron
                    HStack(spacing: 12) {
                        Text("\(milestone.replaceCount) replace · \(milestone.items.count) items")
                            .font(.quicksand(.medium, size: 10))
                            .foregroundStyle(ServicePlanPalette.textSecondary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ServicePlanPalette.dotColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(milestone.items) { item in
                        ServiceItemRow(item: item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.15))
                .frame(height: 0.75)
        }
    }
}

// MARK: - Completed Milestone Row

struct CompletedMilestoneRow: View {
    let milestone: ServicePlanMilestone
    let loggedCount: Int
    let requiredCount: Int
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(milestone.mileage.formatted())
                        .font(.quicksand(.semibold, size: 18))
                        .foregroundStyle(ServicePlanPalette.textPrimary)

                    if let months = milestone.months {
                        Text("\(months) mo")
                            .font(.quicksand(.medium, size: 10))
                            .foregroundStyle(ServicePlanPalette.textMuted)
                    }

                    Spacer(minLength: 8)

                    Text("\(milestone.replaceCount) replace · \(milestone.items.count) items")
                        .font(.quicksand(.medium, size: 10))
                        .foregroundStyle(ServicePlanPalette.textSecondary)

                    if loggedCount > 0 {
                        Text("\(loggedCount)/\(requiredCount)")
                            .font(Font.custom("Menlo", size: 9).weight(.medium))
                            .foregroundStyle(ServicePlanPalette.teal)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(ServicePlanPalette.dotColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(milestone.items) { item in
                        CompletedServiceItemRow(item: item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Read-only item row for completed milestones

struct CompletedServiceItemRow: View {
    let item: ServicePlanItem

    private var actionLabel: String { item.action.rawValue.lowercased() }

    private var actionColor: Color {
        item.action.group == .replacements ? ServicePlanPalette.teal : ServicePlanPalette.textMuted
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .stroke(ServicePlanPalette.borderLight, lineWidth: 1)
                .frame(width: 13, height: 13)

            Text(item.name)
                .font(.quicksand(.medium, size: 12))
                .foregroundStyle(ServicePlanPalette.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(actionLabel)
                .font(Font.custom("Menlo", size: 8).weight(.regular))
                .tracking(0.40)
                .foregroundStyle(actionColor)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(minHeight: 27)
    }
}
