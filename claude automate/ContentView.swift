import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Demo banner — persistent across all tabs
            DemoBanner()

            TabView(selection: $state.selectedTab) {
                Tab("Home", systemImage: "house.fill", value: .home) {
                    NavigationStack {
                        HomeView()
                    }
                }

                Tab("Diagnose", systemImage: "exclamationmark.triangle.fill", value: .diagnose) {
                    NavigationStack {
                        DiagnoseView()
                    }
                }

                Tab("Learn", systemImage: "book.fill", value: .learn) {
                    NavigationStack {
                        LearnView()
                    }
                }

                Tab("Garage", systemImage: "car.fill", value: .garage) {
                    NavigationStack {
                        GarageView()
                            .navigationDestination(for: Vehicle.self) { vehicle in
                                VehicleDetailView(vehicle: vehicle)
                            }
                            .navigationDestination(for: String.self) { dest in
                                if dest == "quoteValidator" {
                                    QuoteValidatorView()
                                }
                            }
                    }
                }
            }
            .tint(Color.agPrimary)
        }
        .sheet(isPresented: $state.showQuickLog) {
            QuickLogView()
        }
        .sheet(isPresented: $state.showChat) {
            ChatView()
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
}

#Preview {
    ContentView()
        .environment(AppState())
}
