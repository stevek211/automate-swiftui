import SwiftUI
import Supabase

// Figma "My Garage" — 500:2 (one car) and 496:2339 (multiple cars).
struct GarageView: View {
    @Environment(AppState.self) private var appState
    @State private var vehicleToDelete: Vehicle? = nil

    /// Cards overlap like a stacked deck (Figma mb-[-48.4px]).
    private let cardOverlap: CGFloat = 48.4

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                if appState.vehicles.isEmpty {
                    garageEmptyState
                        .padding(.horizontal, 24)
                } else {
                    cardStack
                        .padding(.horizontal, 14)

                    if appState.vehicles.count == 1 {
                        addAnotherCarButton
                            .padding(.top, 16)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            "Delete \(vehicleToDelete?.fullDisplayName ?? "Vehicle")?",
            isPresented: Binding(
                get: { vehicleToDelete != nil },
                set: { if !$0 { vehicleToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let vehicle = vehicleToDelete {
                    confirmDelete(vehicle)
                }
            }
            Button("Cancel", role: .cancel) {
                vehicleToDelete = nil
            }
        } message: {
            Text("This will permanently remove the vehicle and all its service history.")
        }
    }

    private func confirmDelete(_ vehicle: Vehicle) {
        vehicleToDelete = nil
        appState.removeVehicle(vehicle)
        Task { await SupabaseManager.softDeleteVehicle(id: vehicle.id) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("YOUR COLLECTION")
                    .font(.quicksand(.regular, size: 12))
                    .foregroundStyle(Color.garageMuted)
                    .frame(height: 13.5)

                Text("\(Text("My Garage"))\(Text(".").foregroundStyle(Color.garageDot))")
                    .font(.quicksand(.bold, size: 36))
                    .foregroundStyle(Color.garageTitle)
                    .frame(height: 45)
                    .padding(.top, 8)

                if !appState.vehicles.isEmpty {
                    HStack(spacing: 0) {
                        Text(vehicleCountText)
                            .font(.quicksand(.medium, size: 16))
                            .foregroundStyle(Color.garageMuted)
                        Rectangle()
                            .fill(Color.garageHairline)
                            .frame(width: 38, height: 0.625)
                            .padding(.leading, 6)
                    }
                    .frame(height: 20)
                    .padding(.top, 8)
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: 4) {
                Button { appState.showSettings = true } label: {
                    Image("garage-icon-settings")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.garageTitle)
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                .opacity(0.7)
                .accessibilityLabel("Settings")

                if appState.vehicles.count > 1 {
                    Button { appState.showAddVehicle = true } label: {
                        Image("garage-icon-plus")
                            .renderingMode(.template)
                            .foregroundStyle(Color.garageTitle)
                            .frame(width: 36, height: 36)
                            .background(Color.garageButtonFill, in: Circle())
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.25), lineWidth: 1))
                            .shadow(color: .black.opacity(0.1), radius: 1.5, y: 1)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .opacity(0.5)
                    .accessibilityLabel("Add vehicle")
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 28)
    }

    private var vehicleCountText: String {
        let count = appState.vehicles.count
        return "\(count) \(count == 1 ? "vehicle" : "vehicles")"
    }

    // MARK: - Cards

    private var cardStack: some View {
        VStack(spacing: -cardOverlap) {
            ForEach(Array(appState.vehicles.enumerated()), id: \.element.id) { index, vehicle in
                GarageVehicleCard(
                    vehicle: vehicle,
                    index: index,
                    isLast: index == appState.vehicles.count - 1
                )
                .zIndex(Double(index))
                .contextMenu {
                    Button(role: .destructive) {
                        vehicleToDelete = vehicle
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var addAnotherCarButton: some View {
        GaragePillButton(title: "Add Another Car") {
            appState.showAddVehicle = true
        }
    }

    // MARK: - Empty State

    var garageEmptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 24)

            Image("garage-icon-car")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundStyle(Color.garageInk.opacity(0.3))

            Text("No vehicles yet")
                .font(.quicksand(.bold, size: 20))
                .foregroundStyle(Color.garageInk)

            Text("Add your first car to get personalized maintenance tracking, service history, and more.")
                .font(.quicksand(.medium, size: 14))
                .foregroundStyle(Color.garageMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            GaragePillButton(title: "Add Your Car") {
                appState.showAddVehicle = true
            }
            .padding(.top, 4)

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
                            .font(.quicksand(.medium, size: 13))
                    }
                    .foregroundStyle(Color.garageMuted)
                }
                .buttonStyle(.plain)
            }

            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: – Pill button ("Add Another Car")
/// Tan pill with a dark outline and a hard, unblurred drop shadow.
private struct GaragePillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.quicksand(.medium, size: 16))
                .foregroundStyle(Color.garageInk)
                .frame(width: 276, height: 44)
                .background(Color.garageGradientEnd, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.garageInk, lineWidth: 1))
                .background(Capsule().fill(Color.black).offset(x: 3, y: 4))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: – Garage Vehicle Card
struct GarageVehicleCard: View {
    @Environment(AppState.self) private var appState
    let vehicle: Vehicle
    var index: Int = 0
    var isLast: Bool = true

    private static let cornerRadius: CGFloat = 36

    private var attentionCount: Int {
        appState.maintenanceItems(for: vehicle.id)
            .filter { $0.status == .overdue || $0.status == .dueSoon }
            .count
    }

    private var statusText: String {
        switch attentionCount {
        case 0: return "All good"
        case 1: return "1 item"
        default: return "\(attentionCount) items"
        }
    }

    var body: some View {
        NavigationLink(value: vehicle) {
            VStack(alignment: .leading, spacing: 0) {
                topRow

                VStack(alignment: .leading, spacing: 2.5) {
                    Text(vehicle.make)
                        .font(.quicksand(.medium, size: 16))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    modelName
                }
                .foregroundStyle(Color.garageInk)
                .padding(.top, 10)

                bottomArea
                    .padding(.top, 2)
            }
            .padding(.top, 20)
            .padding(.horizontal, 22)
            .padding(.bottom, isLast ? 22.6 : 40.6)
            .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
            .background(Color.garageCardFill)
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .strokeBorder(index == 0 ? Color.garageCardBorderPrimary : Color.garageCardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -2)
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Self.cornerRadius))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(vehicle.year) \(vehicle.make) \(vehicle.model), \(statusText)")
    }

    /// Short models sit on one line beside the car roof, as in the design.
    /// A model that would run into the photo wraps (up to two lines, shrinking
    /// if needed) and leaves a gap so the photo starts below the text.
    private var modelName: some View {
        // Model name size (31pt).
        let text = Text(vehicle.model).font(.quicksand(.semibold, size: 31))
        return ViewThatFits(in: .horizontal) {
            text
                .lineLimit(1)
                .fixedSize()
                .padding(.trailing, 100)   // the roof of the photo starts ~100pt from the right

            VStack(alignment: .leading, spacing: 0) {
                text
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .lineSpacing(-4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(height: 34)
            }
        }
    }

    private var topRow: some View {
        HStack {
            HStack(spacing: 7) {
                Image(vehicle.garageIsTruck ? "garage-icon-truck" : "garage-icon-car")
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                Text(String(format: "NO. %02d", index + 1))
                    .font(.quicksand(.medium, size: 13))
                    .tracking(0.3)
            }

            Spacer()

            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.garageInk)
                        .frame(width: 5, height: 5)
                    Text(statusText)
                        .font(.quicksand(.semibold, size: 12))
                }
                Image("garage-icon-arrow")
                    .renderingMode(.template)
                    .frame(width: 15, height: 15)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().strokeBorder(Color.garageInk.opacity(0.25), lineWidth: 1))
            }
        }
        .foregroundStyle(Color.garageInk)
    }

    /// Dashed rule with the model year underneath; the car photo bleeds off the
    /// right edge from above the rule (Figma: right -129, top -66, 389×210).
    private var bottomArea: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 4.65) {
                Text(String(vehicle.year))
                    .font(.quicksand(.regular, size: 19))
                    .frame(height: 20.9)
                Text("MODEL YEAR")
                    .font(.quicksand(.regular, size: 8))
                    .opacity(0.6)
            }
            .foregroundStyle(Color.garageInk)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 108, maxHeight: 108, alignment: .bottomLeading)
        .overlay(alignment: .top) {
            DashedRule()
                .stroke(Color.garageInk.opacity(0.28), style: StrokeStyle(lineWidth: 0.625, dash: [3, 3]))
                .frame(height: 0.625)
        }
        .overlay(alignment: .topTrailing) {
            GarageCarImage(vehicle: vehicle)
                .frame(width: 290, height: 181)
                .offset(x: 85, y: -39)
                .allowsHitTesting(false)
        }
    }
}

private struct DashedRule: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

// MARK: – Car image (IMAGIN side profile, styled toward the sketch look)
private struct GarageCarImage: View {
    let vehicle: Vehicle

    private var url: URL? {
        VehicleImageService.vehicleImageURL(
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            color: vehicle.color,
            bodyStyle: vehicle.bodyStyle,
            angle: "21",          // left-facing side profile, front at left as in the design
            tightCrop: true,
            width: 1000
        )
    }

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.25))) { phase in
            if case .success(let image) = phase {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .saturation(0.15)
                    .contrast(0.85)
                    .brightness(0.06)
                    .colorMultiply(Color(hex: "DCE4F2"))
                    .blendMode(.multiply)
                    .rotationEffect(.degrees(-3))
            } else {
                Color.clear
            }
        }
    }
}

private extension Vehicle {
    /// Pickups get the truck glyph on their garage card.
    var garageIsTruck: Bool {
        let model = model.lowercased()
        let pickups = [
            "f-150", "f150", "f-250", "f250", "f-350", "silverado", "sierra", "ram",
            "tacoma", "tundra", "ranger", "colorado", "canyon", "frontier", "titan",
            "ridgeline", "gladiator", "maverick", "santa cruz", "cybertruck",
        ]
        return pickups.contains { model.contains($0) } || make.lowercased() == "ram"
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
                    .font(.quicksandScaled(.semibold, size: 14))
                    .foregroundStyle(Color.agForeground)
                Spacer()
                Text(item.status.rawValue)
                    .font(.quicksandScaled(.semibold, size: 10))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(item.description)
                .font(.quicksandScaled(.regular, size: 12))
                .foregroundStyle(Color.agMutedForeground)
                .lineLimit(1)

            HStack(spacing: 12) {
                if let dueDate = item.dueDate {
                    Label(dueDate.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
                        .font(.quicksandScaled(.regular, size: 11))
                        .foregroundStyle(Color.agMutedForeground)
                }
                if let dueMileage = item.dueMileage {
                    Label("\(dueMileage.formatted()) mi", systemImage: "speedometer")
                        .font(.quicksandScaled(.regular, size: 11))
                        .foregroundStyle(Color.agMutedForeground)
                }
                Spacer()
                Text(item.estimatedCostDisplay)
                    .font(.quicksandScaled(.regular, size: 11))
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
