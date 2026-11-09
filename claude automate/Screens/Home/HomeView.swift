import SwiftUI

// MARK: - Home palette (Figma "Automate" › Main, node 437:335)

private extension Color {
    static let homeInk = Color(hex: "1E1A4D")             // headings, values
    static let homeInkSoft = Color(hex: "1E1A4D").opacity(0.8)
    static let homeSubtitle = Color(hex: "5E5C66")
    static let homeLabel = Color(hex: "737373")
    static let homeHairline = Color(hex: "1E1A4D").opacity(0.08)
    static let homeStatsFill = Color(hex: "FCFCFC")
    static let homeStatsBorder = Color(hex: "F0EFF4")
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showServiceHistory = false

    var body: some View {
        ScrollView {
            if let vehicle = appState.selectedVehicle ?? appState.vehicles.first {
                content(for: vehicle)
            } else {
                VStack(spacing: 0) {
                    header(vehicle: nil)
                    homeEmptyState
                }
                .padding(.horizontal, 24)
            }
        }
        .scrollIndicators(.hidden)
        .background(homeBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showServiceHistory) {
            if let vehicle = appState.selectedVehicle {
                VehicleDetailView(vehicle: vehicle)
            }
        }
    }

    // MARK: - Layout

    private func content(for vehicle: Vehicle) -> some View {
        let summary = HomeVehicleSummary(vehicle: vehicle, appState: appState)

        return VStack(alignment: .leading, spacing: 10) {
            header(vehicle: vehicle)

            VStack(spacing: 4) {
                titleBlock(vehicle)
                HomeHeroCarImage(vehicle: vehicle)
            }
            .padding(.top, 17)

            statsCard(summary)

            servicesGrid
                .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private var homeBackground: some View {
        // CSS: linear-gradient(9.59deg, white@0.2 → rgb(151,141,141)@0.2) over white.
        ZStack {
            Color.white
            LinearGradient(
                colors: [Color.white.opacity(0.2), Color(red: 151/255, green: 141/255, blue: 141/255).opacity(0.2)],
                startPoint: UnitPoint(x: 0.42, y: 1),
                endPoint: UnitPoint(x: 0.58, y: 0)
            )
        }
    }

    // MARK: - Header

    private func header(vehicle: Vehicle?) -> some View {
        HStack {
            VehicleSwitcherButton()
            Spacer()
            Button { appState.showServiceAlerts = true } label: {
                Image("home-icon-bell")
                    .frame(width: 44, height: 44)
                    .homeGlassCircle()
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Notifications")
        }
        .padding(.top, 8)
    }

    // MARK: - Title

    private func titleBlock(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(vehicle.make)
                .font(.quicksand(.medium, size: 18))
                .tracking(-0.234)
                .foregroundStyle(Color.homeInkSoft)
                .frame(height: 22.5)

            Text(vehicle.model)
                .font(.quicksand(.bold, size: 42))
                .tracking(-1.2)
                .foregroundStyle(Color.homeInk)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: 46)

            Text(Self.subtitle(for: vehicle))
                .font(.quicksand(.medium, size: 16))
                .tracking(0.45)
                .foregroundStyle(Color.homeSubtitle)
                .padding(.top, 7.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static func subtitle(for vehicle: Vehicle) -> String {
        [String(vehicle.year), vehicle.trim]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: " · ")
    }

    // MARK: - Stats

    private func statsCard(_ summary: HomeVehicleSummary) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Button { appState.showMileageUpdater = true } label: {
                HomeStatColumn(
                    icon: "home-icon-speedometer",
                    value: summary.mileage.formatted(),
                    unit: "mi",
                    label: "Estimated Mileage"
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Edit odometer, currently \(summary.mileage.formatted()) miles")

            divider

            Button { appState.showServiceAlerts = true } label: {
                HomeStatColumn(
                    icon: "home-icon-calendar",
                    value: summary.statusText,
                    unit: nil,
                    label: "Maintenance status"
                )
            }
            .buttonStyle(ScaleButtonStyle())

            divider

            HomeStatColumn(
                icon: "home-icon-wrench",
                value: summary.nextServiceMileage?.formatted() ?? "—",
                unit: summary.nextServiceMileage == nil ? nil : "mi",
                label: "Next service"
            )
        }
        .padding(.horizontal, 4.77)
        .padding(.vertical, 20.77)
        .background(Color.homeStatsFill, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.homeStatsBorder, lineWidth: 1))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.homeHairline)
            .frame(width: 0.77)
            .frame(maxHeight: 79)
    }

    // MARK: - Services grid

    private var servicesGrid: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 12) {
                serviceHistoryCard
                carDocumentsCard
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                HomeServiceTile(
                    image: "home-log-service",
                    imageSize: CGSize(width: 100, height: 74.43),
                    imageOffset: CGPoint(x: -20, y: -14),
                    title: "Log service",
                    subtitle: "Record maintenance done"
                ) { appState.showQuickLog = true }

                HomeServiceTile(
                    image: "home-diagnose",
                    imageSize: CGSize(width: 84, height: 62.53),
                    imageOffset: CGPoint(x: -14, y: -5),
                    title: "Diagnose",
                    subtitle: "Dashboard lights and noises"
                ) { appState.selectedTab = .diagnose }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var serviceHistoryCard: some View {
        Button { showServiceHistory = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("Service\nhistory")
                    .font(.quicksand(.bold, size: 21))
                    .tracking(-0.258)
                    .lineSpacing(0)
                    .foregroundStyle(Color.homeInk)
                    .multilineTextAlignment(.leading)
                    .fixedSize()

                Image("home-service-history")
                    .resizable()
                    .frame(width: 105, height: 166.75)
                    .offset(y: -36)
                    .frame(width: 105, height: 94, alignment: .top)
                    .clipped()
                    .padding(.leading, -1)

                HStack(alignment: .center) {
                    Text("View maintenance\nlog")
                        .font(.quicksand(.regular, size: 11))
                        .foregroundStyle(Color.homeLabel)
                        .lineSpacing(1.5)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Image("home-icon-chevron-right")
                }
                .frame(maxWidth: 128)
                .padding(.top, -6)
            }
            .padding(.top, 18)
            .padding(.leading, 18.77)
            .padding(.trailing, 14)
            .padding(.bottom, 18.77)
            .frame(maxWidth: .infinity, minHeight: 208, alignment: .topLeading)
            .homeCard(cornerRadius: 24)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var carDocumentsCard: some View {
        Button {
            // TODO: Car documents screen (registration, insurance, etc.)
        } label: {
            HStack(spacing: 0) {
                Text("Car documents")
                    .font(.quicksand(.bold, size: 12))
                    .foregroundStyle(Color.homeInk)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image("home-car-documents")
                    .resizable()
                    .frame(width: 43, height: 24)
                    .frame(width: 44, height: 32, alignment: .trailing)
            }
            .padding(.horizontal, 14.77)
            .padding(.vertical, 12.77)
            .frame(maxWidth: .infinity, minHeight: 57.5)
            .homeCard(cornerRadius: 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Empty State

    var homeEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "car.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.agMutedForeground.opacity(0.3))

            Text("Welcome to AutoMate")
                .font(.quicksand(.bold, size: 16))
                .foregroundStyle(Color.homeInk)

            Text("Add your car to get started with maintenance tracking and diagnostics.")
                .font(.quicksand(.regular, size: 13))
                .foregroundStyle(Color.agMutedForeground)
                .multilineTextAlignment(.center)

            Button {
                appState.showAddVehicle = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Your Car")
                        .font(.quicksand(.bold, size: 14))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.homeInk)
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
                            .font(.quicksand(.medium, size: 13))
                    }
                    .foregroundStyle(Color.agMutedForeground)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 48)
    }
}

// MARK: - Vehicle summary
//
// Placeholder derivations so nothing on Home is hard-coded. The real
// maintenance-status / next-service logic will be refined later.

struct HomeVehicleSummary {
    let mileage: Int
    let statusText: String
    let nextServiceMileage: Int?

    init(vehicle: Vehicle, appState: AppState) {
        // Estimated mileage = the odometer entered when the car was added
        // (updated via the mileage sheet).
        mileage = vehicle.mileage

        let overdue = appState.overdueItems(for: vehicle.id).count
        let dueSoon = appState.dueSoonItems(for: vehicle.id).count
        if overdue > 0 {
            statusText = overdue == 1 ? "1 overdue" : "\(overdue) overdue"
        } else if dueSoon > 0 {
            statusText = "Due soon"
        } else {
            statusText = "All good"
        }

        nextServiceMileage = Self.nextServiceMileage(vehicle: vehicle, appState: appState)
    }

    private static func nextServiceMileage(vehicle: Vehicle, appState: AppState) -> Int? {
        let current = vehicle.mileage
        var candidates: [Int] = []

        for item in appState.oemSchedule(for: vehicle.id) ?? [] where !item.severeOnly {
            switch item.type {
            case .recurring:
                if let interval = item.intervalMiles, interval > 0 {
                    candidates.append((current / interval + 1) * interval)
                }
            case .oneTime:
                if let first = item.firstDueMiles, first > current {
                    candidates.append(first)
                }
            case .recurringAfterFirst:
                guard let first = item.firstDueMiles else { continue }
                if first > current {
                    candidates.append(first)
                } else if let interval = item.subsequentIntervalMiles ?? item.intervalMiles, interval > 0 {
                    candidates.append(first + ((current - first) / interval + 1) * interval)
                }
            }
        }

        if candidates.isEmpty {
            candidates = appState.maintenanceItems(for: vehicle.id)
                .compactMap(\.dueMileage)
                .filter { $0 > current }
        }
        return candidates.min()
    }
}

// MARK: - Hero car image (IMAGIN.studio side profile)

private struct HomeHeroCarImage: View {
    let vehicle: Vehicle

    private var url: URL? {
        VehicleImageService.vehicleImageURL(
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            color: vehicle.color,
            angle: "21",
            tightCrop: true,
            width: 1200
        )
    }

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.25))) { phase in
            switch phase {
            case .success(let image):
                // Fit (not fill) so tall bodies like SUVs/trucks never get their roof cropped.
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            default:
                Image("car-illustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(24)
                    .opacity(0.6)
            }
        }
        // Bleed slightly past the 24pt gutters like the design (438pt image in a 390pt column).
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .padding(.horizontal, -12)
        .accessibilityLabel("\(vehicle.color) \(vehicle.make) \(vehicle.model)")
    }
}

// MARK: - Vehicle switcher

private struct VehicleSwitcherButton: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Menu {
            ForEach(appState.vehicles) { vehicle in
                Button {
                    appState.selectedVehicleId = vehicle.id
                } label: {
                    if vehicle.id == appState.selectedVehicleId {
                        Label(vehicle.displayName, systemImage: "checkmark")
                    } else {
                        Text(vehicle.displayName)
                    }
                }
            }
            if !appState.vehicles.isEmpty { Divider() }
            Button {
                appState.showAddVehicle = true
            } label: {
                Label("Add vehicle", systemImage: "plus")
            }
        } label: {
            HStack(spacing: 5) {
                Image("home-icon-car")
                    .frame(width: 24, height: 24)
                Image("home-icon-chevron-down")
                    .frame(width: 10, height: 10)
            }
            .frame(width: 62, height: 44)
            .homeGlassCapsule()
        }
        .accessibilityLabel("Switch car")
    }
}

// MARK: - Stat column

private struct HomeStatColumn: View {
    let icon: String
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(spacing: 0) {
            Image(icon)
                .frame(width: 24, height: 24)
                .padding(.bottom, 7)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.quicksand(.bold, size: 18))
                    .tracking(-0.432)
                    .foregroundStyle(Color.homeInk)
                if let unit {
                    Text(unit)
                        .font(.quicksand(.medium, size: 12))
                        .tracking(0.117)
                        .foregroundStyle(Color.homeLabel)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(height: 28)

            Text(label)
                .font(.quicksand(.medium, size: 12))
                .tracking(0.117)
                .foregroundStyle(Color.homeLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

// MARK: - Service tile (Log service / Diagnose)

private struct HomeServiceTile: View {
    let image: String
    let imageSize: CGSize
    let imageOffset: CGPoint
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(image)
                    .resizable()
                    .frame(width: imageSize.width, height: imageSize.height)
                    .offset(x: imageOffset.x, y: imageOffset.y)
                    .frame(width: 58, height: 52, alignment: .topLeading)
                    .clipped()
                    .padding(.leading, -1)

                Spacer(minLength: 10)

                Text(title)
                    .font(.quicksand(.bold, size: 15))
                    .tracking(-0.234)
                    .foregroundStyle(Color.homeInk)
                    .frame(height: 22.5)

                Text(subtitle)
                    .font(.quicksand(.regular, size: 11))
                    .tracking(0.065)
                    .foregroundStyle(Color.homeLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 4)
            }
            .padding(.top, 12.76)
            .padding(.leading, 16.77)
            .padding(.trailing, 12)
            .padding(.bottom, 15.77)
            .frame(maxWidth: .infinity, minHeight: 133.4, alignment: .topLeading)
            .homeCard(cornerRadius: 24)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Surfaces

private extension View {
    func homeCard(cornerRadius: CGFloat) -> some View {
        self
            .background(Color.white, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Color.homeHairline, lineWidth: 1))
            .shadow(color: Color.homeInk.opacity(0.02), radius: 2, y: 2)
            .shadow(color: Color.homeInk.opacity(0.02), radius: 9, y: 6)
    }

    func homeGlassCircle() -> some View {
        self
            .background(Color.white.opacity(0.88), in: Circle())
            .overlay(Circle().strokeBorder(Color.homeInk.opacity(0.035), lineWidth: 1))
            .shadow(color: .black.opacity(0.1), radius: 1.5, y: 1)
            .shadow(color: .black.opacity(0.04), radius: 0.5, y: 1)
    }

    func homeGlassCapsule() -> some View {
        self
            .background(Color.white.opacity(0.88), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.homeInk.opacity(0.04), lineWidth: 1))
            .shadow(color: .black.opacity(0.1), radius: 1.5, y: 1)
            .shadow(color: .black.opacity(0.04), radius: 0.5, y: 1)
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
    let state = AppState()
    state.isDemo = true
    return NavigationStack {
        HomeView()
    }
    .environment(state)
}
