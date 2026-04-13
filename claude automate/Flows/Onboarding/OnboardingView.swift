import SwiftUI

struct OnboardingView: View {
    @Environment(AuthState.self) private var authState
    @Environment(AppState.self) private var appState
    let onComplete: () -> Void

    @State private var showAddVehicle = false
    @State private var showSignUp = false
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0
    @State private var logoScale: Double = 0.7
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        ZStack {
            if showSplash {
                splashScreen
                    .opacity(splashOpacity)
                    .onAppear {
                        // Pop the logo in
                        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                            logoScale = 1.0
                            logoOpacity = 1.0
                        }
                        // Then fade out after a pause
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                splashOpacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showSplash = false
                            }
                        }
                    }
            } else if showAddVehicle {
                OnboardingAddVehicleView {
                    onComplete()
                }
                .transition(.move(edge: .trailing))
            } else {
                ZStack {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.98, green: 0.97, blue: 0.96), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.94, green: 0.92, blue: 0.89), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                    .ignoresSafeArea()

                    authPage
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showAddVehicle)
    }

    // MARK: - Splash Screen

    private var splashScreen: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 0.98, green: 0.97, blue: 0.96), location: 0.00),
                Gradient.Stop(color: Color(red: 0.94, green: 0.92, blue: 0.89), location: 1.00),
            ],
            startPoint: UnitPoint(x: 0.5, y: 0),
            endPoint: UnitPoint(x: 0.5, y: 1)
        )
        .ignoresSafeArea()
            .overlay(
                Image("app-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
            )
    }

    // MARK: - Auth Landing Screen (Get Started/Login)

    private var authPage: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo
                Image("app-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .padding(.top, 10)

                authLandingView

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(
                    onSignedUp: {
                        showSignUp = false
                        withAnimation { showAddVehicle = true }
                    },
                    onBack: {
                        showSignUp = false
                    }
                )
                .environment(authState)
            }
        }
    }

    private var authLandingView: some View {
        VStack(spacing: 0) {
            // Illustration area with floating car parts
            ZStack {
                // Row 1
                Image("engine-block")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -120, y: -170)

                Image("car-hood")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(5))
                    .offset(x: 0, y: -170)

                Image("brake-caliper")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(10))
                    .offset(x: 120, y: -170)

                // Row 2
                Image("speedometer")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 105, height: 105)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -120, y: -50)

                Image("service-invoice")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(4))
                    .offset(x: 0, y: -50)

                Image("wrench")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 105, height: 105)
                    .rotationEffect(.degrees(-10))
                    .offset(x: 120, y: -50)

                // Row 3
                Image("car-battery")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(7))
                    .offset(x: -110, y: 60)

                Image("license-plate")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 105, height: 105)
                    .rotationEffect(.degrees(-5))
                    .offset(x: 10, y: 60)

                Image("jack-stand")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(8))
                    .offset(x: 120, y: 60)

                // Row 4
                Image("car-lift")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -120, y: 165)

                Image("fuel-nozzle")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-7))
                    .offset(x: 0, y: 170)

                Image("tool-box")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(8))
                    .offset(x: 120, y: 165)
            }
            .frame(height: UIScreen.main.bounds.height * 0.50)

            Spacer(minLength: 0)

            // Bottom CTA area
            VStack(spacing: 8) {
                Text("Welcome to AutoMate")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundStyle(Color(hex: "1F1A17"))

                Text("Know your car")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundStyle(Color.agOnboardingSubtext)
                    .padding(.bottom, 4)

                VStack(spacing: 10) {
                    Button {
                        showSignUp = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(hex: "101828"))
                                .frame(width: 20, height: 20)
                            Text("Get Started")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundStyle(Color(hex: "101828"))
                                .tracking(-0.15)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "E8E2DA"))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color(hex: "C8BFB5"), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                    }
                    .buttonStyle(OnboardingScaleStyle())

                    Button {
                        showSignUp = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(hex: "101828"))
                                .frame(width: 20, height: 20)
                            Text("Log in")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundStyle(Color(hex: "101828"))
                                .tracking(-0.15)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "E8E2DA"))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color(hex: "C8BFB5"), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                    }
                    .buttonStyle(OnboardingScaleStyle())
                }

                Text("By signing up you agree to our ")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundStyle(Color.agOnboardingMuted) +
                Text("Terms")
                    .font(.custom("Poppins-Medium", size: 11))
                    .foregroundStyle(Color.agOnboardingBrown) +
                Text(" and ")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundStyle(Color.agOnboardingMuted) +
                Text("Privacy Policy")
                    .font(.custom("Poppins-Medium", size: 11))
                    .foregroundStyle(Color.agOnboardingBrown)
            }
            .padding(.bottom, 32)
        }
        .transition(.opacity)
    }

}

// MARK: - Scale Style

private struct OnboardingScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environment(AuthState())
        .environment(AppState())
}
