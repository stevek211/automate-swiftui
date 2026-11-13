import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var bottomNavHeight: CGFloat = 0

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Demo banner — persistent across all tabs
            DemoBanner()

            selectedTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // The nav's safe-area inset doesn't reach scroll views inside the
                // NavigationStacks, so the last cards ended up hidden behind it.
                // Give every tab's scroll content room to clear the nav.
                .contentMargins(.bottom, bottomNavHeight, for: .scrollContent)
        }
        .appBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AutomateBottomNav(selectedTab: $state.selectedTab)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                    bottomNavHeight = $0
                }
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
        .sheet(isPresented: $state.showEditVehicle) {
            EditVehicleSheet()
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

    /// All tabs stay alive and cross-fade, so switching doesn't rebuild the
    /// screen (no layout jump, no car photos reloading, scroll position kept).
    private var selectedTabView: some View {
        ZStack {
            tabPage(.home) {
                NavigationStack { HomeView() }
            }
            tabPage(.learn) {
                NavigationStack { LearnView() }
            }
            tabPage(.garage) {
                NavigationStack {
                    GarageView()
                        .navigationDestination(for: Vehicle.self) { vehicle in
                            VehicleDetailView(vehicle: vehicle)
                        }
                }
            }
        }
    }

    private func tabPage<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        let isActive = appState.selectedTab == tab
        return content()
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
            .accessibilityHidden(!isActive)
            .animation(.easeInOut(duration: 0.22), value: isActive)
    }
}

/// Floating Liquid Glass tab bar (iOS 26 `glassEffect`). Content scrolls
/// underneath it; the selected tab sits on a glass pill that slides between tabs.
private struct AutomateBottomNav: View {
    @Binding var selectedTab: AppTab
    @Namespace private var glassNamespace

    private let activeColor = Color.garageTitle   // navy, matches "My Garage"
    private let inactiveColor = Color(hex: "484C52")

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    navItem(tab)
                }
            }
            .padding(6)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .accessibilityElement(children: .contain)
    }

    private func navItem(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        let color = isSelected ? activeColor : inactiveColor

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.bottomNavSymbol)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 26)

                Text(tab.rawValue)
                    .font(.quicksand(isSelected ? .bold : .medium, size: 11))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    // Cream from the page gradient, not the blue accent.
                    Capsule()
                        .fill(Color.garageGradientEnd.opacity(0.7))
                        .glassEffect(.regular.tint(Color.garageGradientEnd.opacity(0.5)), in: .capsule)
                        .matchedGeometryEffect(id: "selection", in: glassNamespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension AppTab {
    var bottomNavSymbol: String {
        switch self {
        case .home:
            return "house"
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
