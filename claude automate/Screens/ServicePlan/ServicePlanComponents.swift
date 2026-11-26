import SwiftUI

// MARK: - Design Tokens

enum ServicePlanPalette {
    static var bg: Color { Color.theme.background }
    static var cardBg: Color { Color.theme.card }

    static var teal: Color { Color.theme.brand }
    static var tealDeep: Color { Color.theme.brandDeep }
    static var tealBright: Color { Color.theme.brand }
    static var tealTintChip: Color { Color.theme.brand.opacity(0.10) }
    static var tealTintBtn: Color { Color.theme.brand.opacity(0.11) }

    static var chipSage: Color { Color.theme.success.opacity(0.45) }

    static var greenTint: Color { Color.theme.success.opacity(0.15) }
    static var greenText: Color { Color.theme.success }
    static var replaceTint: Color { Color.theme.brand.opacity(0.18) }

    static var neutralChipBg: Color { Color.theme.surfaceAlt }
    static var neutralChipTxt: Color { Color.theme.mutedText }

    static var borderLight: Color { Color.theme.border }
    static var borderDefault: Color { Color.theme.border }
    static var borderSoft: Color { Color.theme.borderStrong }
    static var borderCheckbox: Color { Color.theme.borderStrong }
    static var dotColor: Color { Color.theme.faintText }

    static var textPrimary: Color { Color.theme.ink }
    static var textSecondary: Color { Color.theme.ink.opacity(0.85) }
    static var textMuted: Color { Color.theme.mutedText }
    static var textBody: Color { Color.theme.mutedText }
    static var textFaint: Color { Color.theme.faintText }
    static var textItem: Color { Color.theme.ink }
    static var actionNeutral: Color { Color.theme.mutedText }
    static var itemCircle: Color { Color.theme.faintText }

    /// Action tags in the Log Service sheet (Figma "Log Service Modal").
    /// No palette token matches these, so they're fixed design colors.
    static let replaceTag = Color(hex: "FF6C64")
    static let inspectTag = Color(hex: "DFB200")
    /// Perform / rotate / clean / adjust tags: the brand teal, so "do it"
    /// items read differently from replacements and inspections.
    static var serviceTag: Color { Color.theme.brand }
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

// MARK: - Action Label

/// Plain monospaced caps label ("REPLACE", "INSPECT") — Figma V2 ledger rows
/// use colored text only, no chip background.
struct ActionLabel: View {
    let action: ServiceAction

    private var fg: Color {
        switch action {
        case .replace, .adjust, .clean, .rotate: return ServicePlanPalette.teal
        case .perform:              return ServicePlanPalette.greenText
        case .inspect, .check:      return ServicePlanPalette.actionNeutral
        }
    }

    var body: some View {
        Text(action.displayText)
            .font(.custom("Menlo-Regular", size: 11))
            .kerning(0.4)
            .foregroundStyle(fg)
    }
}

// MARK: - Service Item Row

struct ServiceItemRow: View {
    let item: ServicePlanItem
    @State private var checked = false

    var body: some View {
        Button { checked.toggle() } label: {
            HStack(spacing: 10) {
                // 13pt outlined circle (Figma 317:104); fills teal when ticked.
                ZStack {
                    Circle()
                        .fill(checked ? ServicePlanPalette.teal : Color.clear)
                    Circle()
                        .strokeBorder(checked ? ServicePlanPalette.teal : ServicePlanPalette.itemCircle,
                                      lineWidth: 1.08)
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(checked ? 1 : 0)
                }
                .frame(width: 13, height: 13)
                .padding(1)

                ServiceItemIconView(name: item.name, category: item.category)

                Text(item.name)
                    .font(.quicksand(.medium, size: 12))
                    .foregroundStyle(ServicePlanPalette.textItem)
                    .strikethrough(checked, color: ServicePlanPalette.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)
                ActionLabel(action: item.action).fixedSize()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .frame(minHeight: 27)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item icon

/// 16pt monochrome icon shown beside each service item. Uses a line-art asset
/// when one exists for the part, otherwise a generic wrench.
struct ServiceItemIconView: View {
    let name: String
    let category: String

    var body: some View {
        Group {
            if let asset = ServiceItemIcon.asset(name: name, category: category) {
                Image(asset)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "wrench.adjustable")
                    .resizable()
                    .scaledToFit()
                    .padding(1.5)
            }
        }
        .foregroundStyle(ServicePlanPalette.textBody)
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}

// MARK: - Category → icon mapping

enum ServiceItemIcon {
    /// Line-art asset for an item, matched on the item name first (categories
    /// from Perplexity are broad — "fluids" covers brake fluid and diff fluid)
    /// then on category. Nil means no dedicated icon yet → generic fallback.
    static func asset(name: String, category: String) -> String? {
        let n = name.lowercased()
        let c = category.lowercased().replacingOccurrences(of: "ai-", with: "")
        if n.contains("oil") && !n.contains("differential") && !n.contains("transmission") {
            return "icon-oil-can"
        }
        if n.contains("tire") || n.contains("tyre") || c == "tires" { return "Tire" }
        if n.contains("transmission") || n.contains("differential") || n.contains("transfer case")
            || c == "transmission" {
            return "Transmission"
        }
        if c == "oil" { return "icon-oil-can" }
        return nil
    }

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
                    // Mileage
                    Text(milestone.mileage.formatted())
                        .font(.quicksand(.semibold, size: 18))
                        .foregroundStyle(ServicePlanPalette.textPrimary)

                    Spacer()

                    // Item summary + chevron
                    HStack(spacing: 12) {
                        Text("\(milestone.replaceCount) replace · \(milestone.items.count) items")
                            .font(.quicksand(.medium, size: 11))
                            .foregroundStyle(ServicePlanPalette.textSecondary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
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

                    Spacer(minLength: 8)

                    Text("\(milestone.replaceCount) replace · \(milestone.items.count) items")
                        .font(.quicksand(.medium, size: 11))
                        .foregroundStyle(ServicePlanPalette.textSecondary)

                    if loggedCount > 0 {
                        Text("\(loggedCount)/\(requiredCount)")
                            .font(Font.custom("Menlo", size: 11).weight(.medium))
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
                .font(Font.custom("Menlo", size: 11).weight(.regular))
                .tracking(0.40)
                .foregroundStyle(actionColor)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(minHeight: 27)
    }
}
