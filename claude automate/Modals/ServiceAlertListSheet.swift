import SwiftUI

struct ServiceAlertListSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    var overdueItems: [MaintenanceItem] {
        guard let id = appState.selectedVehicleId else { return [] }
        return appState.overdueItems(for: id)
    }

    var dueSoonItems: [MaintenanceItem] {
        guard let id = appState.selectedVehicleId else { return [] }
        return appState.dueSoonItems(for: id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Vehicle back-link
                    if let vehicle {
                        Button { dismiss() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 12, weight: .medium))
                                Text(vehicle.fullDisplayName)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Color.agMutedForeground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.agMuted)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Needs Attention (Overdue) ──────────────────
                    if !overdueItems.isEmpty {
                        Text("Needs Attention")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.agForeground)

                        ForEach(overdueItems) { item in
                            MaintenanceAlertCard(item: item, style: .overdue, appState: appState)
                        }
                    }

                    // ── Coming Up Soon ──────────────────────────────
                    if !dueSoonItems.isEmpty {
                        Text("Coming Up Soon")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.agForeground)
                            .padding(.top, overdueItems.isEmpty ? 0 : 8)

                        ForEach(dueSoonItems) { item in
                            MaintenanceAlertCard(item: item, style: .dueSoon, appState: appState)
                        }
                    }

                    // ── Empty State ─────────────────────────────────
                    if overdueItems.isEmpty && dueSoonItems.isEmpty {
                        VStack(spacing: AGSpacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.agSuccess)
                            Text("All caught up!")
                                .font(.poppinsTitle3)
                            Text("No maintenance alerts at this time.")
                                .font(.poppinsBody)
                                .foregroundStyle(Color.agMutedForeground)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AGSpacing.xxxl)
                    }
                }
                .padding(AGSpacing.screenPadding)
            }
            .background(Color.agBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Maintenance Alert Card

struct MaintenanceAlertCard: View {
    let item: MaintenanceItem
    let style: CardStyle
    let appState: AppState

    enum CardStyle {
        case overdue, dueSoon

        var dotColor: Color {
            switch self {
            case .overdue: Color.agDestructive
            case .dueSoon: Color.agWarning
            }
        }

        var borderColor: Color {
            switch self {
            case .overdue: Color.agDestructive.opacity(0.25)
            case .dueSoon: Color.agWarning.opacity(0.25)
            }
        }

        var whyItMattersColor: Color {
            switch self {
            case .overdue: Color.agDestructive
            case .dueSoon: Color.agWarning
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status dot + title
            HStack(spacing: 8) {
                Circle()
                    .fill(style.dotColor)
                    .frame(width: 10, height: 10)
                Text(item.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.agForeground)
            }

            // Due mileage subtitle
            if let dueMileage = item.dueMileage {
                let remaining = dueMileage - (appState.selectedVehicle?.mileage ?? 0)
                if remaining > 0 {
                    Text("Due in ~\(remaining.formatted()) miles (≈ \(dueMileage.formatted()) mi)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.agMutedForeground)
                } else {
                    Text("Overdue by ~\(abs(remaining).formatted()) miles")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.agDestructive)
                }
            }

            // "WHY IT MATTERS" box
            VStack(alignment: .leading, spacing: 6) {
                Text("WHY IT MATTERS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(style.whyItMattersColor)

                Text(item.description)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.agMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(style.dotColor.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style.dotColor.opacity(0.12), lineWidth: 1)
            )

            // Cost estimate
            if item.estimatedCostLow > 0 || item.estimatedCostHigh > 0 {
                HStack(spacing: 4) {
                    Text("Typical cost:")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agMutedForeground)
                    Text("$\(Int(item.estimatedCostLow))–\(Int(item.estimatedCostHigh)) at a shop")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.agForeground)
                    if item.diyDifficulty <= 2 {
                        Text("· $\(Int(item.estimatedCostLow / 2))–\(Int(item.estimatedCostHigh / 2)) DIY")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    appState.selectedTab = .learn
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 12))
                        Text("Learn more")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.agPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    // Set reminder placeholder
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text("Set reminder")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color.agForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.agMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.agBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(16)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style.borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    ServiceAlertListSheet()
        .environment(AppState())
}
