import SwiftUI

// MARK: - Palette (Figma "Vehicle detail" frame, 559:5455)

extension Color {
    static var vdPage: Color { theme.background }          // page background
    static var vdHeroTop: Color { theme.surfaceAlt.opacity(0.6) }
    static var vdInk: Color { theme.ink }                  // headings, values
    static var vdMuted: Color { theme.mutedText }          // labels, secondary text
    static var vdBorder: Color { theme.border }            // card borders, hairlines
    static var vdSurface: Color { theme.card }             // cards, buttons
    static var vdTrack: Color { theme.surfaceAlt }         // segmented track, chips
    static var vdAccent: Color { theme.brand }             // selected tab, links
}

struct VehicleDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle

    enum Section: String, CaseIterable, Identifiable {
        case maintenance = "Maintenance"
        case specs = "Vehicle Specs"
        var id: String { rawValue }
    }

    enum MaintenanceView: String, CaseIterable, Identifiable {
        case documents = "Documents"
        case cost = "Cost"
        case conditions = "Conditions"
        var id: String { rawValue }
    }

    @State private var section: Section = .maintenance
    @State private var maintenanceView: MaintenanceView
    /// Set when another screen links straight to a tab (e.g. Home → Car documents);
    /// the page then scrolls down to the tabs on open.
    private let linkedView: MaintenanceView?

    init(vehicle: Vehicle, openTo linkedView: MaintenanceView? = nil) {
        self.vehicle = vehicle
        self.linkedView = linkedView
        _maintenanceView = State(initialValue: linkedView ?? .cost)
    }
    @State private var costRange: CostRange = .allTime
    @State private var showServicePlan = false

    /// The latest copy from app state, so edits (mileage, trim) show up here.
    private var current: Vehicle {
        appState.vehicles.first { $0.id == vehicle.id } ?? vehicle
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 0) {
                hero
                actionRow
                    .padding(.horizontal, 16)
                    .padding(.top, 5)

                VStack(spacing: 16) {
                    sectionTabs
                        .id(Self.tabsAnchor)
                    switch section {
                    case .maintenance: maintenanceContent
                    case .specs: specsContent
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            guard linkedView != nil else { return }
            // Wait a beat so the push animation finishes before scrolling.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.snappy) { proxy.scrollTo(Self.tabsAnchor, anchor: .top) }
            }
        }
        }
        .background(Color.vdPage.ignoresSafeArea())
        .overlay(alignment: .top) { topBar }
        .toolbar(.hidden, for: .navigationBar)
    }

    private static let tabsAnchor = "vehicle-detail-tabs"

    // MARK: - Top bar (fixed, glass circles)

    private var topBar: some View {
        HStack {
            BackButton()

            Spacer()

            circleButton(label: "Settings") {
                appState.selectedVehicleId = current.id
                appState.showEditVehicle = true
            } icon: {
                Image("vehicle-icon-settings")
                    .renderingMode(.template)
                    .foregroundStyle(Color.vdInk)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func circleButton<Icon: View>(
        label: String,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button(action: action) {
            icon()
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        // Same glass circle as BackButton, which sits opposite it.
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }

    // MARK: - Hero: name, car, odometer

    private var hero: some View {
        VStack(spacing: 0) {
            // Trim and color live in Vehicle Specs, so the hero shows the name only.
            Text(current.displayName)
                .font(.quicksandScaled(.bold, size: 18))
                .foregroundStyle(Color.vdInk)
                .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            VehicleImageView(vehicle: current, size: 224)
                .frame(width: 224, height: 144)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 10)
                // The stock photo has empty sky above the car; pull it up under the name.
                .padding(.top, -24)

            OdometerView(mileage: current.mileage)
                .frame(minHeight: 73.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.bottom, 64)
        .background(
            LinearGradient(colors: [.vdHeroTop, .vdPage], startPoint: .top, endPoint: .bottom)
                // Scroll content can't extend under the status bar, so paint the
                // gradient's top color upward to fill it (and the pull-down bounce).
                .overlay(alignment: .top) {
                    Color.vdHeroTop
                        .frame(height: 600)
                        .offset(y: -600)
                }
        )
        .padding(.bottom, -64)  // the action row sits in the gradient's tail
    }

    // MARK: - Quick actions

    private var actionRow: some View {
        HStack(spacing: 8) {
            actionButton(icon: "vehicle-icon-log-service", label: "Log Service") {
                appState.selectedVehicleId = current.id
                appState.showQuickLog = true
            }
            actionButton(icon: "home-icon-calendar", label: "Service Plan") {
                showServicePlan = true
            }
        }
        .fullScreenCover(isPresented: $showServicePlan) {
            NavigationStack {
                let items = appState.oemSchedule(for: current.id) ?? ServicePlanBuilder.demoItems
                let logs = appState.serviceLogs(for: current.id)
                ServicePlanView(
                    vehicle: current,
                    oemItems: items,
                    sources: appState.oemSources(for: current.id),
                    serviceLogs: logs,
                    serviceLogCount: logs.count
                )
            }
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(icon)
                    .renderingMode(.template)
                    .foregroundStyle(Color.vdInk)
                    .frame(width: 21.99, height: 21.99)
                Text(label)
                    .font(.quicksandScaled(.medium, size: 13))
                    .foregroundStyle(Color.vdInk)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12.625)
            .background(Color.vdSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.vdBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Maintenance / Vehicle Specs tabs (underline)

    private var sectionTabs: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { tab in
                let selected = section == tab
                Button {
                    withAnimation(.snappy(duration: 0.2)) { section = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.quicksandScaled(.medium, size: 13))
                        .foregroundStyle(selected ? Color.vdAccent : Color.vdMuted)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(selected ? Color.vdAccent : .clear)
                                .frame(height: 1.875)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.vdBorder).frame(height: 0.625).offset(y: 0.625)
        }
    }

    // MARK: - Maintenance

    private var maintenanceContent: some View {
        VStack(spacing: 16) {
            maintenanceSegments
            switch maintenanceView {
            case .conditions:
                placeholder(title: "Conditions", message: "Wear and condition tracking is coming soon.")
            case .cost:
                VehicleCostPanel(
                    // Baseline estimates aren't real spending; leaving them out
                    // keeps the "No service costs yet" state until a real log.
                    logs: appState.serviceLogs(for: current.id).filter { !$0.isBaselineEstimate },
                    range: $costRange
                ) {
                    appState.selectedVehicleId = current.id
                    appState.showQuickLog = true
                }
            case .documents:
                VehicleDocumentsPanel(vehicle: current)
            }
        }
    }

    private var maintenanceSegments: some View {
        HStack(spacing: 4) {
            ForEach(MaintenanceView.allCases) { tab in
                let selected = maintenanceView == tab
                Button {
                    withAnimation(.snappy(duration: 0.2)) { maintenanceView = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.quicksandScaled(.semibold, size: 13))
                        .foregroundStyle(selected ? Color.vdInk : Color.vdMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .frame(minHeight: 36)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.vdSurface)
                                    .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.vdTrack, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Vehicle Specs (Figma 582:294)

    private var specsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle identity")
                .font(.quicksandScaled(.semibold, size: 15))
                .foregroundStyle(Color.vdInk)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                specRow("Year", "\(current.year)", first: true)
                specRow("Make", current.make)
                specRow("Model", current.model)
                specRow("Trim", nonEmpty(current.trim))
                specRow("Body style", nonEmpty(current.bodyStyle))
                specRow("Color", nonEmpty(current.color))
                specRow("VIN", nonEmpty(current.vin))
            }
        }
        .padding(.top, 8)
    }

    /// Label left, value right; wraps to stacked rows at accessibility text sizes.
    private func specRow(_ label: String, _ value: String, first: Bool = false) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                specLabel(label)
                Spacer(minLength: 0)
                specValue(value)
            }
            VStack(alignment: .leading, spacing: 2) {
                specLabel(label)
                specValue(value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(Color.vdBorder).frame(height: 0.625) }
        }
        .accessibilityElement(children: .combine)
    }

    private func specLabel(_ text: String) -> some View {
        Text(text)
            .font(.quicksandScaled(.regular, size: 13))
            .foregroundStyle(Color.vdMuted)
    }

    private func specValue(_ text: String) -> some View {
        Text(text)
            .font(.quicksandScaled(.medium, size: 14))
            .monospacedDigit()
            .foregroundStyle(text == "Not added" ? Color.vdMuted : Color.vdInk)
            .multilineTextAlignment(.trailing)
            .textSelection(.enabled)
    }

    private func nonEmpty(_ value: String?) -> String {
        guard let value, !value.trimmingCharacters(in: .whitespaces).isEmpty else { return "Not added" }
        return value
    }

    private func placeholder(title: String, message: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.quicksandScaled(.semibold, size: 15))
                .foregroundStyle(Color.vdInk)
            Text(message)
                .font(.quicksandScaled(.regular, size: 13))
                .foregroundStyle(Color.vdMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Odometer

private struct OdometerView: View {
    let mileage: Int
    @ScaledMetric(relativeTo: .callout) private var digitWidth: CGFloat = 15
    @ScaledMetric(relativeTo: .callout) private var digitHeight: CGFloat = 22

    private var digits: [Character] {
        let clamped = min(max(mileage, 0), 999_999)
        return Array(String(format: "%06d", clamped))
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(Array(digits.enumerated()), id: \.offset) { index, digit in
                    Text(String(digit))
                        .font(.quicksandScaled(.medium, size: 16))
                        .foregroundStyle(.black)
                        .frame(width: digitWidth, height: digitHeight)
                        .overlay(alignment: .trailing) {
                            if index < digits.count - 1 {
                                Rectangle()
                                    .fill(Color.vdPage.opacity(0.2))
                                    .frame(width: 0.625)
                            }
                        }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                // inset 0 2 4 rgba(0,0,0,0.05)
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.05), lineWidth: 4)
                    .blur(radius: 2)
                    .offset(y: 2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black, lineWidth: 1))

            Text("Odometer · mi")
                .font(.quicksandScaled(.medium, size: 11))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.vdMuted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Odometer \(mileage.formatted()) miles")
    }
}

#Preview {
    NavigationStack {
        VehicleDetailView(vehicle: DemoData.vehicles[0])
    }
    .environment(AppState())
}
