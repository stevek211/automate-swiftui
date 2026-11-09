import SwiftUI
import Supabase
import CoreText

@main
struct AutoGuardApp: App {
    @State private var appState = AppState()
    @State private var authState = AuthState()

    init() {
        registerBundleFonts()
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
    }
}
