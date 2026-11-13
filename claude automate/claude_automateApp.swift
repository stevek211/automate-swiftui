import SwiftUI
import Supabase
import CoreText
import UserNotifications

@main
struct AutoGuardApp: App {
    @State private var appState = AppState()
    @State private var authState = AuthState()

    init() {
        registerBundleFonts()
        // Route taps on "update your odometer" reminders back into the app.
        UNUserNotificationCenter.current().delegate = NotificationRouter.shared
        guard !PreviewSupport.isRunningForPreviews else { return }
        AnalyticsService.shared.track(.appLaunched)
    }

    private func registerBundleFonts() {
        let fontNames = [
            "Poppins-Light", "Poppins-Regular", "Poppins-Medium", "Poppins-SemiBold", "Poppins-Bold",
            "Quicksand-Light", "Quicksand-Regular", "Quicksand-Medium", "Quicksand-SemiBold", "Quicksand-Bold",
        ]
        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(authState)
                .onOpenURL { url in
                    Task {
                        try? await SupabaseManager.client.auth.session(from: url)
                    }
                }
        }
    }
}

struct RootView: View {
    @Environment(AuthState.self) private var authState
    @Environment(AppState.self) private var appState

    @State private var showOnboarding: Bool? = nil

    var body: some View {
        Group {
            if authState.isLoading || showOnboarding == nil {
                ZStack {
                    Color.agBackground.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
            } else if showOnboarding == true {
                OnboardingView {
                    withAnimation {
                        showOnboarding = false
                        appState.hasCompletedOnboarding = true
                    }
                }
            } else {
                ContentView()
            }
        }
        .onAppear {
            #if DEBUG
            // `-demoHome` launch argument: skip auth and land on Home with demo data (UI checks only).
            if ProcessInfo.processInfo.arguments.contains("-demoHome") {
                appState.isDemo = true
                appState.selectedVehicleId = appState.vehicles.first?.id
                showOnboarding = false
                return
            }
            // `-debugUser <uuid>`: open that account's locally saved data without signing in
            // (UI checks against real saved cars; nothing is sent to the server).
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "-debugUser"), index + 1 < args.count,
               let userId = UUID(uuidString: args[index + 1]) {
                appState.configure(for: userId)
                showOnboarding = false
                if args.contains("-refreshSchedule"), let id = appState.selectedVehicleId ?? appState.vehicles.first?.id {
                    Task { await appState.debugRefreshSchedule(for: id) }
                }
                return
            }
            #endif
            // On launch: if already authenticated, configure AppState for that user
            if let user = authState.currentUser {
                appState.configure(for: user.id)
                showOnboarding = !appState.hasCompletedOnboarding
            } else {
                showOnboarding = true
            }
        }
        .onChange(of: authState.currentUser) { oldUser, newUser in
            if let user = newUser {
                // Login or signup — load this user's scoped data
                appState.configure(for: user.id)
                showOnboarding = !appState.hasCompletedOnboarding
            } else {
                // Logout — clear all in-memory user data
                appState.clear()
                withAnimation {
                    showOnboarding = true
                }
            }
        }
        // Tapped an "update your odometer" reminder: open that car's mileage sheet on Home.
        .onChange(of: NotificationRouter.shared.pendingMileageVehicleId) { _, _ in
            openPendingMileagePrompt()
        }
        .onChange(of: showOnboarding) { _, _ in
            openPendingMileagePrompt() // cold launch from a notification tap
        }
    }

    private func openPendingMileagePrompt() {
        guard showOnboarding == false,
              let id = NotificationRouter.shared.pendingMileageVehicleId,
              appState.vehicles.contains(where: { $0.id == id })
        else { return }
        NotificationRouter.shared.pendingMileageVehicleId = nil
        appState.selectedVehicleId = id
        appState.selectedTab = .home
        appState.showMileageUpdater = true
    }
}
