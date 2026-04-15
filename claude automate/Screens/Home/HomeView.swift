import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var totalAlerts: Int {
        appState.vehicles.reduce(0) { sum, v in
            sum + appState.maintenanceItems(for: v.id)
                .filter { $0.status == .overdue || $0.status == .dueSoon }
                .count
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Header ──────────────────────────────────────
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hey Steve")
                            .font(.poppins(.regular, size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                        Text("Your garage")
                            .font(.poppins(.bold, size: 20))
                            .foregroundStyle(Color.agForeground)
                    }
                    Spacer()
                    Button { appState.showSettings = true } label: {
                        ZStack {
                            Circle()
                                .fill(Color.agPrimary10)
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.agPrimary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // ── Cross-Car Alert Banner ───────────────────────
                if totalAlerts > 0 {
                    Button { appState.showServiceAlerts = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.agWarning)
                            Text("\(totalAlerts) items need attention across your vehicles")
                                .font(.poppins(.semibold, size: 12))
                                .foregroundStyle(Color.agForeground)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.agWarning)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.agWarning15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.agWarning25, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // ── Vehicle Cards ────────────────────────────────
                if appState.vehicles.isEmpty {
                    homeEmptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(appState.vehicles) { vehicle in
                            HomeDashboardVehicleCard(
                                vehicle: vehicle,
                                isPrimary: vehicle.id == appState.selectedVehicleId,
                                appState: appState
                            )
                        }
                    }
                }

                // ── Something Wrong? ─────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("Something wrong?")
                        .font(.poppins(.semibold, size: 14))

                    HStack(spacing: 10) {
                        DiagnoseQuickCard(
                            icon: "hazard-light",
                            isCustomImage: true,
                            title: "Dashboard",
                            subtitle: "Light?",
                            bgColor: Color.agWarning10
                        ) {
                            appState.selectedTab = .diagnose
                        }
                        DiagnoseQuickCard(
                            icon: "car.side.fill",
                            title: "Strange",
                            subtitle: "Noise?",
                            bgColor: Color.agDestructive10
                        ) {
                            appState.selectedTab = .diagnose
                        }
                    }
                }

                // ── Ask My Manual ────────────────────────────────
                Button { appState.showChat = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.agPrimary15)
                                .frame(width: 40, height: 40)
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.agPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ask My Manual")
                                .font(.poppins(.bold, size: 14))
                                .foregroundStyle(Color.agForeground)
                            Text("Get plain-English answers about your \(appState.selectedVehicle?.displayName ?? "vehicle")")
                                .font(.poppins(.regular, size: 11))
                                .foregroundStyle(Color.agMutedForeground)
                                .lineLimit(2)
                        }

                        Spacer()

                        HStack(spacing: 2) {
                            Text("Ask")
                                .font(.poppins(.medium, size: 12))
                                .foregroundStyle(Color.agPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.agPrimary)
                        }
                    }
                    .padding(16)
                    .background(Color.agPrimary5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.agPrimary15, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())

                // ── Log Service Invoice ──────────────────────────
                Button { appState.showQuickLog = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.agAccent15)
                                .frame(width: 40, height: 40)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.agAccent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Log Service Invoice")
                                .font(.poppins(.bold, size: 14))
                                .foregroundStyle(Color.agForeground)
                            Text("Scan or manually log a service")
                                .font(.poppins(.regular, size: 11))
                                .foregroundStyle(Color.agMutedForeground)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agAccent)
                    }
                    .padding(16)
                    .background(Color.agAccent5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.agAccent15, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color.agBackground)
    }

    // MARK: - Empty State

    var homeEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "car.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.agMutedForeground.opacity(0.3))

            Text("Welcome to AutoMate")
                .font(.poppins(.bold, size: 16))
                .foregroundStyle(Color.agForeground)

            Text("Add your car to get started with maintenance tracking and diagnostics.")
                .font(.poppins(.regular, size: 13))
                .foregroundStyle(Color.agMutedForeground)
                .multilineTextAlignment(.center)

            Button {
                appState.showAddVehicle = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Your Car")
                        .font(.poppins(.bold, size: 14))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.agPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())

            if !appState.isDemo {
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        appState.isDemo = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                        Text("Explore demo")
                            .font(.poppins(.medium, size: 13))
                    }
                    .foregroundStyle(Color.agMutedForeground)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 24)
    }
}

// MARK: – Vehicle Dashboard Card (matches React HomeDashboard vehicle card)
struct HomeDashboardVehicleCard: View {
    let vehicle: Vehicle
    let isPrimary: Bool
    let appState: AppState

    @State private var showServicePlan = false

    var alertCount: Int {
        appState.maintenanceItems(for: vehicle.id)
            .filter { $0.status == .overdue || $0.status == .dueSoon }
            .count
    }

    var overdueCount: Int {
        appState.maintenanceItems(for: vehicle.id).filter { $0.status == .overdue }.count
    }

    var dueSoonCount: Int {
        appState.maintenanceItems(for: vehicle.id).filter { $0.status == .dueSoon }.count
    }

    var onTrackCount: Int {
        appState.maintenanceItems(for: vehicle.id).filter { $0.status == .onTrack }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Name + Primary badge
            HStack {
                Text(vehicle.fullDisplayName)
                    .font(.poppins(.semibold, size: 14))
                    .foregroundStyle(Color.agForeground)
                Spacer()
                if isPrimary {
                    Text("Primary")
                        .font(.poppins(.semibold, size: 10))
                        .foregroundStyle(Color.agPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.agPrimary10)
                        .clipShape(Capsule())
                }
            }

            // Mileage
            Text("\(vehicle.mileage.formatted()) mi · Updated today")
                .font(.poppins(.regular, size: 12))
                .foregroundStyle(Color.agMutedForeground)

            // Status rows
            if onTrackCount > 0 {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.agSuccess)
                        .frame(width: 10, height: 10)
                    Text("\(onTrackCount) on track")
                        .font(.poppins(.medium, size: 12))
                        .foregroundStyle(Color.agForeground)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.agSuccess8)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if dueSoonCount > 0 {
                Button { appState.showServiceAlerts = true } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.agWarning)
                            .frame(width: 10, height: 10)
                        Text("\(dueSoonCount) coming soon")
                            .font(.poppins(.medium, size: 12))
                            .foregroundStyle(Color.agForeground)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.agWarning10)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            if overdueCount > 0 {
                Button { appState.showServiceAlerts = true } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.agDestructive)
                            .frame(width: 10, height: 10)
                        Text("\(overdueCount) need attention")
                            .font(.poppins(.medium, size: 12))
                            .foregroundStyle(Color.agForeground)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.agDestructive10)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Info tooltip
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text("How is this calculated?")
                    .font(.poppins(.regular, size: 10))
            }
            .foregroundStyle(Color.agMutedForeground.opacity(0.6))
            .padding(.leading, 4)

            // Odometer widget
            Button { appState.showMileageUpdater = true } label: {
                HStack(spacing: 8) {
                    Image("hazard-light")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Color.agPrimary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Odometer")
                            .font(.poppins(.regular, size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text("\(vehicle.mileage.formatted())")
                                .font(.poppins(.bold, size: 14))
                                .foregroundStyle(Color.agForeground)
                            Text("mi")
                                .font(.poppins(.regular, size: 12))
                                .foregroundStyle(Color.agMutedForeground)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.agPrimary5)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.agPrimary15, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())

            // View service plan
            Button { showServicePlan = true } label: {
                HStack(spacing: 2) {
                    Spacer()
                    Text("View service plan")
                        .font(.poppins(.medium, size: 12))
                        .foregroundStyle(Color.agPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.agPrimary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.agBorder, lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showServicePlan) {
            NavigationStack {
                // Prefer the AI-researched schedule persisted at signup/add-vehicle;
                // fall back to demo items so previews and legacy vehicles still render.
                let items = appState.oemSchedule(for: vehicle.id) ?? ServicePlanBuilder.demoItems
                let sources = appState.oemSources(for: vehicle.id)
                ServicePlanView(vehicle: vehicle, oemItems: items, sources: sources)
            }
        }
    }
}

// MARK: – Diagnose Quick Card
struct DiagnoseQuickCard: View {
    let icon: String
    var isCustomImage: Bool = false
    let title: String
    let subtitle: String
    var bgColor: Color = Color.agMuted
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bgColor)
                        .frame(width: 40, height: 40)
                    if isCustomImage {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(Color.agForeground)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(Color.agForeground)
                    }
                }
                VStack(spacing: 2) {
                    Text(title)
                        .font(.poppins(.semibold, size: 14))
                        .foregroundStyle(Color.agForeground)
                    Text(subtitle)
                        .font(.poppins(.regular, size: 12))
                        .foregroundStyle(Color.agMutedForeground)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: – Scale Button Style (matches active:scale-[0.98])
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppState())
}
