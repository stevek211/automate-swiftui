import SwiftUI

// MARK: - Home palette (Figma "Automate" › Main, node 437:335)

private extension Color {
    static var homeInk: Color { theme.heading }              // headings, values
    static var homeInkSoft: Color { theme.heading.opacity(0.8) }
    static var homeSubtitle: Color { theme.mutedText }
    static var homeLabel: Color { theme.mutedText }
    static var homeHairline: Color { theme.heading.opacity(0.08) }
    static var homeStatsFill: Color { theme.card }
    static var homeStatsBorder: Color { theme.hairline }
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthState.self) private var authState
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
        .appBackground()
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
                HomeHeroCarousel()
            }
            .padding(.top, 17)

            statsCard(summary, vehicle: vehicle)

            servicesGrid
                .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
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
        .overlay(alignment: .topTrailing) {
            Button { appState.showEditVehicle = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Edit")
                        .font(.quicksand(.semibold, size: 13))
                }
                .foregroundStyle(Color.homeInk.opacity(0.7))
                .padding(.horizontal, 12)
                .frame(height: 32)
                .homeGlassCapsule()
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Edit vehicle details")
        }
    }

    static func subtitle(for vehicle: Vehicle) -> String {
        [String(vehicle.year), vehicle.trim]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: " · ")
    }

    // MARK: - Stats

    private func statsCard(_ summary: HomeVehicleSummary, vehicle: Vehicle) -> some View {
        VStack(spacing: 14) {
            statColumns(summary)

            Rectangle()
                .fill(Color.homeHairline)
                .frame(height: 0.77)
                .padding(.horizontal, 12)

            mileageFreshnessRow(summary, vehicle: vehicle)
                .padding(.horizontal, 12)
        }
        .padding(.horizontal, 4.77)
        .padding(.top, 20.77)
        .padding(.bottom, 14)
        .background(Color.homeStatsFill, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.homeStatsBorder, lineWidth: 1))
    }

    /// Fresh: "Odometer updated 3 weeks ago · Update". After 28 days: a one-tap check-in.
    @ViewBuilder
    private func mileageFreshnessRow(_ summary: HomeVehicleSummary, vehicle: Vehicle) -> some View {
        if summary.mileageIsStale {
            mileageCheckInPrompt(summary, vehicle: vehicle)
        } else {
            Button { appState.showMileageUpdater = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .medium))
                    Text(summary.mileageUpdatedText)
                        .font(.quicksand(.medium, size: 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 8)
                    Text("Update")
                        .font(.quicksand(.bold, size: 12))
                        .foregroundStyle(Color.homeInk)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.homeInk)
                }
                .foregroundStyle(Color.homeLabel)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(summary.mileageUpdatedText). Update odometer")
        }
    }

    /// "Is your odometer about 48,100 mi?" with Yes / Enter exact (GoodRx/Noom-style confirm).
    private func mileageCheckInPrompt(_ summary: HomeVehicleSummary, vehicle: Vehicle) -> some View {
        let estimate = summary.estimatedMileage
        let question = estimate.map { "Is your odometer about \($0.formatted()) mi?" }
            ?? "Is \(summary.mileage.formatted()) mi still right?"
        let hint = estimate != nil
            ? "Based on ~\(summary.annualMiles.formatted()) mi a year. Check your dashboard to be exact."
            : "Check your dashboard. Keeping it current keeps your service plan accurate."

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "gauge.with.needle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.agWarning)
                Text(question)
                    .font(.quicksand(.bold, size: 14))
                    .foregroundStyle(Color.homeInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Button {
                    confirmMileage(estimate, vehicle: vehicle)
                } label: {
                    Text(estimate != nil ? "Yes, about right" : "Yes, still right")
                        .font(.quicksand(.semibold, size: 13))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.homeInk, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())

                Button { appState.showMileageUpdater = true } label: {
                    Text("Enter exact")
                        .font(.quicksand(.semibold, size: 13))
                        .foregroundStyle(Color.homeInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.homeHairline, lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Text(hint)
                .font(.quicksand(.medium, size: 11))
                .foregroundStyle(Color.homeLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func confirmMileage(_ estimate: Int?, vehicle: Vehicle) {
        if let estimate {
            appState.updateMileage(estimate, for: vehicle.id)
        } else {
            appState.confirmMileage(for: vehicle.id)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if !appState.isDemo,
           let userId = authState.currentUser?.id,
           let saved = appState.vehicles.first(where: { $0.id == vehicle.id }) {
            Task { await SupabaseManager.upsertVehicle(saved, userId: userId) }
        }
    }

    private func statColumns(_ summary: HomeVehicleSummary) -> some View {
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
                ) { appState.selectedTab = .learn }
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
    let mileageUpdatedText: String
    /// True after MileageReminder.staleAfterDays (28) without an update, or when unknown.
    let mileageIsStale: Bool
    /// Likely current odometer from the yearly-miles choice; nil if we don't know when it was read.
    let estimatedMileage: Int?
    let annualMiles: Int

    init(vehicle: Vehicle, appState: AppState, now: Date = .now) {
        // Estimated mileage = the odometer entered when the car was added
        // (updated via the mileage sheet).
        mileage = vehicle.mileage
        mileageIsStale = MileageReminder.isStale(vehicle, now: now)
        estimatedMileage = MileageReminder.estimatedMileage(for: vehicle, now: now)
        annualMiles = MileageReminder.annualMiles(for: vehicle)

        if let updated = vehicle.mileageUpdatedAt {
            if Calendar.current.isDate(updated, inSameDayAs: now) {
                mileageUpdatedText = "Odometer updated today"
            } else {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                mileageUpdatedText = "Odometer updated \(formatter.localizedString(for: updated, relativeTo: now))"
            }
        } else {
            mileageUpdatedText = "Odometer not confirmed yet"
        }

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

    /// Next milestone from the same plan the Service Logbook shows, so Home and the
    /// logbook always agree.
    private static func nextServiceMileage(vehicle: Vehicle, appState: AppState) -> Int? {
        let current = vehicle.mileage
        if let schedule = appState.oemSchedule(for: vehicle.id), !schedule.isEmpty {
            let plan = ServicePlanBuilder.build(items: schedule, currentMileage: current)
            if let next = plan.upcomingMilestones.first?.mileage { return next }
        }
        return appState.maintenanceItems(for: vehicle.id)
            .compactMap(\.dueMileage)
            .filter { $0 > current }
            .min()
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
            angle: "28",
            tightCrop: true,
            width: 1200
        )
    }

    /// IMAGIN returns a 1.6:1 canvas with a fixed ground line: the bottom ~23% is
    /// always empty below the car's shadow. Show only the top 78% so the stats card
    /// sits right under the car regardless of body style.
    private static let imageAspect: CGFloat = 1.6
    private static let visibleFraction: CGFloat = 0.78
    /// Width ÷ height of the visible photo band.
    static let bandAspect: CGFloat = imageAspect / visibleFraction

    var body: some View {
        Color.clear
            .aspectRatio(Self.bandAspect, contentMode: .fit)
            .overlay(alignment: .top) {
                AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.25))) { phase in
                    switch phase {
                    case .success(let image):
                        // Full width; height overflows the band and the empty strip is clipped off.
                        image
                            .resizable()
                            .aspectRatio(Self.imageAspect, contentMode: .fill)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .clipped()
            .accessibilityLabel("\(vehicle.color) \(vehicle.make) \(vehicle.model)")
    }
}

// MARK: - Hero carousel (swipe between cars)

private struct HomeHeroCarousel: View {
    @Environment(AppState.self) private var appState

    private var selection: Binding<UUID?> {
        Binding(
            get: { appState.selectedVehicleId ?? appState.vehicles.first?.id },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.2)) { appState.selectedVehicleId = newValue }
            }
        )
    }

    var body: some View {
        let vehicles = appState.vehicles

        VStack(spacing: 10) {
            Group {
                if vehicles.count > 1 {
                    TabView(selection: selection) {
                        ForEach(vehicles) { vehicle in
                            HomeHeroCarImage(vehicle: vehicle)
                                .tag(Optional(vehicle.id))
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .aspectRatio(HomeHeroCarImage.bandAspect, contentMode: .fit)
                } else if let vehicle = vehicles.first {
                    HomeHeroCarImage(vehicle: vehicle)
                }
            }
            // Bleed slightly past the 24pt gutters like the design (438pt image in a 390pt column).
            .padding(.horizontal, -12)

            if vehicles.count > 1 {
                pageDots(vehicles)
            }
        }
    }

    /// Mercedes-style dots so a second car is discoverable without opening the switcher menu.
    private func pageDots(_ vehicles: [Vehicle]) -> some View {
        let current = selection.wrappedValue
        return HStack(spacing: 6) {
            ForEach(vehicles) { vehicle in
                let isCurrent = vehicle.id == current
                Capsule()
                    .fill(isCurrent ? Color.homeInk : Color.homeInk.opacity(0.18))
                    .frame(width: isCurrent ? 18 : 6, height: 6)
                    .padding(.vertical, 8) // larger tap target
                    .contentShape(Rectangle())
                    .onTapGesture { selection.wrappedValue = vehicle.id }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .accessibilityElement()
        .accessibilityLabel("Car \((vehicles.firstIndex { $0.id == current } ?? 0) + 1) of \(vehicles.count)")
        .accessibilityHint("Swipe the car photo to switch cars")
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
            if !appState.vehicles.isEmpty {
                Divider()
                Button {
                    appState.showEditVehicle = true
                } label: {
                    Label("Edit vehicle details", systemImage: "pencil")
                }
            }
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
                .minimumScaleFactor(0.75)
                .padding(.top, 4)
        }
        // Keep labels off the divider hairlines; long labels shrink instead of touching them.
        .padding(.horizontal, 8)
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
    .environment(AuthState())
}
