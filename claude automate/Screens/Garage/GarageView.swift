import SwiftUI

struct GarageView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("My Garage")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.agForeground)
                    Spacer()
                    Button { appState.showAddVehicle = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add Vehicle")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color.agPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.agPrimary10)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // Vehicle Cards — or empty state
                if appState.vehicles.isEmpty {
                    garageEmptyState
                } else {
                    ForEach(appState.vehicles) { vehicle in
                        GarageVehicleCard(vehicle: vehicle)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color.agBackground)
    }

    // MARK: - Empty State

    var garageEmptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.agMutedForeground.opacity(0.3))

            Text("No vehicles yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.agForeground)

            Text("Add your first car to get personalized maintenance tracking, service history, and more.")
                .font(.system(size: 14))
                .foregroundStyle(Color.agMutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button {
                appState.showAddVehicle = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Your Car")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.agPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())

            // Explore demo — opt-in only
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
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color.agMutedForeground)
                }
                .buttonStyle(.plain)
            }

            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: – Garage Vehicle Card
struct GarageVehicleCard: View {
    @Environment(AppState.self) private var appState
    let vehicle: Vehicle

    var overdueCount: Int {
        appState.maintenanceItems(for: vehicle.id).filter { $0.status == .overdue }.count
    }
    var dueSoonCount: Int {
        appState.maintenanceItems(for: vehicle.id).filter { $0.status == .dueSoon }.count
    }

    var body: some View {
        NavigationLink(value: vehicle) {
            HStack(spacing: 12) {
                // Vehicle image from IMAGIN.studio CDN
                VehicleImageView(vehicle: vehicle, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.fullDisplayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.agForeground)
                    HStack(spacing: 6) {
                        Text("\(vehicle.mileage.formatted()) mi")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                        if overdueCount > 0 {
                            Text("· \(overdueCount) overdue")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.agDestructive)
                        } else if dueSoonCount > 0 {
                            Text("· \(dueSoonCount) due soon")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.agWarning)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    // Health score
                    Text("\(vehicle.healthScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(vehicle.healthScore >= 90 ? Color.agSuccess : vehicle.healthScore >= 70 ? Color.agWarning : Color.agDestructive)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.agMutedForeground.opacity(0.5))
                }
            }
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

// MARK: – Maintenance Item Row
struct MaintenanceItemRow: View {
    let item: MaintenanceItem

    var statusColor: Color { Color.statusColor(item.status) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.agForeground)
                Spacer()
                Text(item.status.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(item.description)
                .font(.system(size: 12))
                .foregroundStyle(Color.agMutedForeground)
                .lineLimit(1)

            HStack(spacing: 12) {
                if let dueDate = item.dueDate {
                    Label(dueDate.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.agMutedForeground)
                }
                if let dueMileage = item.dueMileage {
                    Label("\(dueMileage.formatted()) mi", systemImage: "speedometer")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.agMutedForeground)
                }
                Spacer()
                Text(item.estimatedCostDisplay)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.agMutedForeground)
            }
        }
        .padding(16)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.agBorder, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        GarageView()
    }
    .environment(AppState())
}
