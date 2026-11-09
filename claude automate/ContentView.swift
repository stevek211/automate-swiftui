import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Demo banner — persistent across all tabs
            DemoBanner()

            selectedTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "F5F6F7"))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AutomateBottomNav(selectedTab: $state.selectedTab)
        }
        .sheet(isPresented: $state.showQuickLog) {
            QuickLogView()
        }
        .sheet(isPresented: $state.showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $state.showAddVehicle) {
            AddVehicleFlowView()
        }
        .sheet(isPresented: $state.showMileageUpdater) {
            MileageUpdaterSheet()
        }
        .sheet(isPresented: $state.showServiceAlerts) {
            ServiceAlertListSheet()
        }
        .alert("Demo Mode", isPresented: $state.showDemoWriteAlert) {
            Button("Exit Demo") {
                appState.isDemo = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You're exploring demo data. Exit demo mode to add your own vehicles and service history.")
        }
    }

    @ViewBuilder
    private var selectedTabView: some View {
        switch appState.selectedTab {
        case .home:
            NavigationStack {
                HomeView()
            }
        case .diagnose:
            NavigationStack {
                DiagnoseView()
            }
        case .learn:
            NavigationStack {
                LearnView()
            }
        case .garage:
            NavigationStack {
                GarageView()
                    .navigationDestination(for: Vehicle.self) { vehicle in
                        VehicleDetailView(vehicle: vehicle)
                    }
            }
        }
    }
}

private struct AutomateBottomNav: View {
    @Binding var selectedTab: AppTab

    private let activeColor = Color(hex: "539DF3")
    private let inactiveColor = Color(hex: "484C52")

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                HStack(alignment: .top, spacing: 0) {
                    navItem(.home)
                    navItem(.diagnose)
                    navItem(.learn)
                    navItem(.garage)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                selectionIndicator
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(TopRoundedRectangle(radius: 24))
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .accessibilityElement(children: .contain)
    }

    private var selectionIndicator: some View {
        GeometryReader { proxy in
            let tabs = AppTab.allCases
            let index = tabs.firstIndex(of: selectedTab) ?? 0
            let segmentWidth = proxy.size.width / CGFloat(max(tabs.count, 1))
            let xOffset = segmentWidth * CGFloat(index) + (segmentWidth - 56) / 2

            Rectangle()
                .fill(activeColor)
                .frame(width: 56, height: 2)
                .offset(x: xOffset)
                .animation(.easeInOut(duration: 0.18), value: selectedTab)
        }
        .frame(height: 2)
        .padding(.horizontal, 12)
    }

    private func navItem(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        let color = isSelected ? activeColor : inactiveColor

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: tab.bottomNavSymbol)
                    .font(.system(size: tab == .diagnose ? 24 : 23, weight: .regular))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)

                Text(tab.rawValue)
                    .font(.poppins(isSelected ? .medium : .regular, size: 12))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(height: 16)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TopRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(radius, rect.width / 2, rect.height / 2)

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

private extension AppTab {
    var bottomNavSymbol: String {
        switch self {
        case .home:
            return "house"
        case .diagnose:
            return "stethoscope"
        case .learn:
            return "book.pages"
        case .garage:
            return "car"
        }
    }
}

private struct ContentViewPreviewHost: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your garage")
                    .font(.quicksand(.bold, size: 28))
                    .foregroundStyle(Color.agForeground)
                Text("Preview shell")
                    .font(.quicksand(.regular, size: 14))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }
        .background(Color(hex: "F5F6F7"))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AutomateBottomNav(selectedTab: $selectedTab)
        }
    }
}

#Preview("ContentView Shell") {
    ContentViewPreviewHost()
}

#Preview("Full ContentView") {
    ContentView()
        .environment(AppState())
}
