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
        applyNavigationBarFonts()
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

    /// System navigation bar titles and bar buttons ("Done") are drawn by UIKit and ignore
    /// SwiftUI `.font`, so set Quicksand on them here. Only the text attributes are touched,
    /// so the bars keep their default (Liquid Glass) backgrounds.
    private func applyNavigationBarFonts() {
        func quicksand(_ name: String, _ size: CGFloat, _ style: UIFont.TextStyle) -> UIFont {
            let base = UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
            return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
        }
        let bar = UINavigationBar.appearance()
        bar.titleTextAttributes = [.font: quicksand("Quicksand-SemiBold", 17, .headline)]
        bar.largeTitleTextAttributes = [.font: quicksand("Quicksand-Bold", 34, .largeTitle)]
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [.font: quicksand("Quicksand-SemiBold", 17, .body)], for: .normal)
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
                            .font(.quicksandScaled(.medium, size: 14))
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
                    // Rebuild the screens when the palette changes, in case a view cached a color.
                    .id(ThemeStore.shared.palette.id)
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
            // `-showOnboarding`: open the onboarding/auth screens even when signed in (UI checks only).
            if ProcessInfo.processInfo.arguments.contains("-showOnboarding") {
                showOnboarding = true
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
