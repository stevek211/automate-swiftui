import SwiftUI

struct VehicleDetailView: View {
    @Environment(AppState.self) private var appState
    let vehicle: Vehicle

    @State private var selectedTab = 0
    @State private var showServicePlan = false
    private let tabs = ["Overview", "Maintenance"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Hero image area ─────────────────────────────────
                heroImageSection

                // ── Floating info card (overlaps hero) ──────────────
                vehicleInfoCard
                    .padding(.horizontal, 16)
                    .offset(y: -40)

                // ── Quick action buttons ────────────────────────────
                quickActionRow
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 16)

                // ── Vehicle Health card ─────────────────────────────
                healthCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // ── Segmented tab control ────────────────────────────
                tabSegment
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // ── Tab content ─────────────────────────────────────
                Group {
                    switch selectedTab {
                    case 0: overviewTab
                    case 1: maintenanceTab
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // settings action
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.agForeground)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .overlay(
                            Circle().strokeBorder(Color.black.opacity(0.05), lineWidth: 0.7)
                        )
                }
            }
        }
    }

    // MARK: - Hero Image (uses existing VehicleImageView, not modified)

    private var heroImageSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "ECECF0").opacity(0.6), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 272)

            VehicleImageView(vehicle: vehicle, size: 224)
                .frame(width: 224, height: 144)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .frame(height: 272)
    }

    // MARK: - Floating Vehicle Info Card

    private var vehicleInfoCard: some View {
        VStack(spacing: 0) {
            // Vehicle name
            Text(vehicle.fullDisplayName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "0A0A0A"))
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            // Trim · Color
            Text(vehicleSubtitle)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "717182"))
                .padding(.top, 2)

            // Divider
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 0.7)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Stats row: mileage, service count, next service
            HStack(spacing: 16) {
                // Mileage
                HStack(spacing: 6) {
                    Image(systemName: "gauge.medium")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "0A0A0A"))
                    Text("\(vehicle.mileage.formatted()) mi")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "0A0A0A"))
                }

                // Service count
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "0A0A0A"))
                    Text("\(vehicle.maintenanceCurrent)/\(vehicle.maintenanceTotal)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "0A0A0A"))
                }

                // Next service date
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "0A0A0A"))
                    Text(formattedNextService)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "0A0A0A"))
                }
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.7)
        )
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
    }

    // MARK: - Quick Action Row (4 buttons matching Figma)

    private var quickActionRow: some View {
        HStack(spacing: 8) {
            figmaActionButton(icon: "doc.text", label: "Log Service") {
                appState.selectedVehicleId = vehicle.id
                appState.showQuickLog = true
            }
            figmaActionButton(icon: "calendar.badge.clock", label: "Schedule") {
                // schedule action
            }
            figmaActionButton(icon: "list.bullet.clipboard", label: "Service Plan") {
                showServicePlan = true
            }
            figmaActionButton(icon: "brain.head.profile", label: "Ask AI") {
                appState.selectedTab = .diagnose
            }
        }
        .fullScreenCover(isPresented: $showServicePlan) {
            NavigationStack {
                let items = appState.oemSchedule(for: vehicle.id) ?? ServicePlanBuilder.demoItems
                let sources = appState.oemSources(for: vehicle.id)
                let logs = appState.serviceLogs(for: vehicle.id)
                ServicePlanView(vehicle: vehicle, oemItems: items, sources: sources, serviceLogs: logs, serviceLogCount: logs.count)
            }
        }
    }

    // MARK: - Vehicle Health Card (green gradient)

    private var healthCard: some View {
        let healthScore = vehicle.healthScore
        let healthColor = healthScoreColor(healthScore)
        let healthBgGradient = healthGradientColors(healthScore)
        let healthBarBg = healthBarBackground(healthScore)
        let healthBorder = healthBorderColor(healthScore)

        return VStack(alignment: .leading, spacing: 0) {
            // Header row: title + score
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vehicle Health")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "101828"))
                    Text("Based on recent diagnostics")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "4A5565"))
                }

                Spacer()

                Text("\(healthScore)")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(healthColor)
            }
            .padding(.bottom, 12)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(healthBarBg)
                        .frame(height: 8)
                    Capsule()
                        .fill(healthColor)
                        .frame(
                            width: geo.size.width * CGFloat(min(healthScore, 100)) / 100,
                            height: 8
                        )
                        .animation(.spring(duration: 0.6), value: healthScore)
                }
            }
            .frame(height: 8)
            .padding(.bottom, 8)

            // Status text
            Text(healthStatusText(healthScore))
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "4A5565"))
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: healthBgGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(healthBorder, lineWidth: 0.7)
        )
    }

    // MARK: - Segmented Tab Control (2 tabs: Overview, Maintenance)

    private var tabSegment: some View {
        HStack(spacing: 4) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(duration: 0.22)) { selectedTab = i }
                } label: {
                    Text(tabs[i])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedTab == i ? Color(hex: "0A0A0A") : Color(hex: "717182"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedTab == i {
                                    Color.white
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(hex: "ECECF0"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(spacing: 16) {
            vehicleDetailsCard
            whatsNextCard
        }
    }

    // MARK: - Vehicle Details Card

    private var vehicleDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle Details")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "0A0A0A"))

            VStack(spacing: 12) {
                detailRow(label: "VIN", value: vehicle.vin ?? "—")
                detailRow(label: "Last Service", value: formattedDate(vehicle.lastService))
                detailRow(label: "Next Service", value: formattedDate(vehicle.nextService))
                detailRow(label: "Purchase Date", value: "—") // placeholder
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.7)
        )
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    // MARK: - What's Next Card

    private var whatsNextCard: some View {
        let items = appState.maintenanceItems(for: vehicle.id)
            .filter { $0.status != .completed }
            .sorted { statusOrder($0.status) < statusOrder($1.status) }
            .prefix(3)

        return VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.agPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "F0FDFA"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("What's Next")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "0A0A0A"))
                    Text("Based on your service history & \(vehicle.mileage.formatted()) miles")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "717182"))
                }
            }

            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.agSuccess)
                    Text("You're all caught up!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "717182"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        whatsNextRow(item: item)
                        if index < items.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.7)
        )
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    // MARK: - Maintenance Tab

    private var maintenanceTab: some View {
        let logs = appState.serviceLogs(for: vehicle.id)

        return Group {
            if logs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.agMutedForeground.opacity(0.4))
                    VStack(spacing: 6) {
                        Text("No service history yet")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.agForeground)
                        Text("Log your first service to start tracking")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    Button {
                        appState.selectedVehicleId = vehicle.id
                        appState.showQuickLog = true
                    } label: {
                        Text("Log a service")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.agPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                VStack(spacing: 0) {
                    ForEach(logs) { log in
                        ServiceLogRow(log: log)
                        if log.id != logs.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.7)
                )
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }

    // MARK: - Sub-components

    private func figmaActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "0A0A0A"))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "0A0A0A"))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 13)
            .padding(.bottom, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.7)
            )
        }
        .buttonStyle(.plain)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "717182"))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "0A0A0A"))
        }
    }

    private func whatsNextRow(item: MaintenanceItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon(for: item.category))
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "717182"))
                .frame(width: 40, height: 40)
                .background(Color(hex: "ECECF0"))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "0A0A0A"))
                    Spacer()
                    Text(item.status.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(statusTextColor(item.status))
                }
                Text(item.description)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "717182"))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var vehicleSubtitle: String {
        let parts = [vehicle.trim, vehicle.color].compactMap { $0?.isEmpty == true ? nil : $0 }
        return parts.joined(separator: " · ")
    }

    private var formattedNextService: String {
        guard let date = vehicle.nextService else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yy"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter.string(from: date)
    }

    private func healthScoreColor(_ score: Int) -> Color {
        if score >= 80 { return Color(hex: "00A63E") }       // green
        if score >= 60 { return Color(hex: "D08700") }       // amber
        return Color(hex: "F54900")                            // red
    }

    private func healthGradientColors(_ score: Int) -> [Color] {
        if score >= 80 {
            return [Color(hex: "F0FDF4"), Color(hex: "ECFDF5")]  // green gradient
        }
        if score >= 60 {
            return [Color(hex: "FFFBEB"), Color(hex: "FEF3C7")]  // amber gradient
        }
        return [Color(hex: "FEF2F2"), Color(hex: "FEE2E2")]      // red gradient
    }

    private func healthBarBackground(_ score: Int) -> Color {
        if score >= 80 { return Color(hex: "B9F8CF") }
        if score >= 60 { return Color(hex: "FDE68A") }
        return Color(hex: "FECACA")
    }

    private func healthBorderColor(_ score: Int) -> Color {
        if score >= 80 { return Color(hex: "B9F8CF") }
        if score >= 60 { return Color(hex: "FDE68A") }
        return Color(hex: "FECACA")
    }

    private func healthStatusText(_ score: Int) -> String {
        if score >= 90 { return "Excellent condition • No immediate concerns" }
        if score >= 80 { return "Good condition • Minor attention needed" }
        if score >= 60 { return "Fair condition • Service recommended" }
        return "Needs attention • Service overdue"
    }

    private func statusTextColor(_ status: MaintenanceStatus) -> Color {
        switch status {
        case .overdue: return Color(hex: "F54900")
        case .dueSoon: return Color(hex: "D08700")
        case .onTrack: return Color(hex: "00A63E")
        case .completed: return Color.agMutedForeground
        }
    }

    private func statusOrder(_ status: MaintenanceStatus) -> Int {
        switch status {
        case .overdue: return 0
        case .dueSoon: return 1
        case .onTrack: return 2
        case .completed: return 3
        }
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "oil", "oil change": return "drop.fill"
        case "tires", "tire", "tire rotation": return "circle.dashed"
        case "brakes", "brake": return "exclamationmark.octagon"
        case "filter", "air filter", "engine air filter": return "wind"
        case "battery": return "battery.75percent"
        case "transmission": return "gearshape.2"
        case "engine": return "engine.combustion"
        case "coolant": return "thermometer.medium"
        default: return "wrench.and.screwdriver"
        }
    }
}

#Preview {
    NavigationStack {
        VehicleDetailView(vehicle: DemoData.vehicles[0])
    }
    .environment(AppState())
}
