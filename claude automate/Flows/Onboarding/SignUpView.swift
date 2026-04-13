import SwiftUI

struct SignUpView: View {
    @Environment(AuthState.self) private var authState
    let onSignedUp: () -> Void
    let onBack: () -> Void

    @State private var showEmailForm = false
    @State private var socialAuthError = ""

    var body: some View {
        ZStack {
            // Subtle dot decorations
            dotsBackground

            VStack(spacing: 0) {
                Spacer()

                // Logo + title block
                VStack(spacing: 12) {
                    Image("app-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                        .shadow(color: Color(hex: "00BBA7").opacity(0.2), radius: 25, x: 0, y: 15)

                    Text("AutoMate")
                      .font(Font.custom("Poppins", size: 36))
                      .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))


                    Text("Create an account for free")
                      .font(
                        Font.custom("Poppins", size: 14)
                          .weight(.light)
                      )
                      .foregroundColor(Color(red: 0.33, green: 0.35, blue: 0.39))
                }
                .padding(.top, 5)

                Spacer().frame(height: 40)

                // Auth buttons
                VStack(spacing: 12) {
                    // Apple
                    authButton(
                        icon: { appleIcon },
                        label: "Continue with Apple"
                    ) {
                        Task {
                            let result = await authState.signInWithApple()
                            if result.success {
                                onSignedUp()
                            } else if let error = result.error {
                                socialAuthError = error
                            }
                        }
                    }

                    // Google
                    authButton(
                        icon: { googleIcon },
                        label: "Continue with Google"
                    ) {
                        Task {
                            let result = await authState.signInWithGoogle()
                            if result.success {
                                onSignedUp()
                            } else if let error = result.error {
                                socialAuthError = error
                            }
                        }
                    }

                    // Email
                    authButton(
                        icon: { emailIcon },
                        label: "Sign in with email"
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showEmailForm = true
                        }
                    }

                    #if DEBUG
                    // Dev bypass — skip auth entirely
                    authButton(
                        icon: { Image(systemName: "hammer.fill").foregroundStyle(.orange) },
                        label: "Dev Bypass (skip auth)"
                    ) {
                        authState.devBypass()
                        onSignedUp()
                    }
                    #endif
                }
                .padding(.horizontal, 24)

                Spacer()

                // Legal
                VStack(spacing: 4) {
                    Text("By continuing, you agree to the ")
                        .font(.custom("Poppins-Light", size: 12))
                        .foregroundStyle(Color(hex: "6A7282"))
                    + Text("Terms of service")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(Color(hex: "99A1AF"))
                        .underline()

                    Text("and ")
                        .font(.custom("Poppins-Light", size: 12))
                        .foregroundStyle(Color(hex: "6A7282"))
                    + Text("Privacy policy")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(Color(hex: "99A1AF"))
                        .underline()
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
            }
        }
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.98, green: 0.97, blue: 0.96), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.94, green: 0.92, blue: 0.89), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "101828"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "EBE8E3"))
                        .clipShape(Circle())
                }
            }
        }
        .sheet(isPresented: $showEmailForm) {
            EmailSignUpSheet(
                onComplete: { onSignedUp() }
            )
            .environment(authState)
        }
    }

    // MARK: - Auth Button

    private func authButton<I: View>(
        icon: () -> I,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon()
                    .frame(width: 20, height: 20)
                Text(label)
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
        .buttonStyle(OnboardingScaleStylePublic())
    }

    // MARK: - Icons

    private var appleIcon: some View {
        Image(systemName: "apple.logo")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Color(hex: "101828"))
    }

    private var googleIcon: some View {
        // Multi-color Google "G" from official SVG (48×48 viewBox)
        Canvas { context, size in
            let sx = size.width / 48
            let sy = size.height / 48

            // Yellow arc
            var yellow = Path()
            yellow.move(to: CGPoint(x: 43.611 * sx, y: 20.083 * sy))
            yellow.addLine(to: CGPoint(x: 42 * sx, y: 20 * sy))
            yellow.addLine(to: CGPoint(x: 24 * sx, y: 20 * sy))
            yellow.addLine(to: CGPoint(x: 24 * sx, y: 28 * sy))
            yellow.addLine(to: CGPoint(x: 35.303 * sx, y: 28 * sy))
            yellow.addCurve(to: CGPoint(x: 24 * sx, y: 36 * sy),
                            control1: CGPoint(x: 33.654 * sx, y: 32.657 * sy),
                            control2: CGPoint(x: 29.223 * sx, y: 36 * sy))
            yellow.addCurve(to: CGPoint(x: 12 * sx, y: 24 * sy),
                            control1: CGPoint(x: 17.373 * sx, y: 36 * sy),
                            control2: CGPoint(x: 12 * sx, y: 30.627 * sy))
            yellow.addCurve(to: CGPoint(x: 24 * sx, y: 12 * sy),
                            control1: CGPoint(x: 12 * sx, y: 17.373 * sy),
                            control2: CGPoint(x: 17.373 * sx, y: 12 * sy))
            yellow.addCurve(to: CGPoint(x: 31.961 * sx, y: 15.039 * sy),
                            control1: CGPoint(x: 27.059 * sx, y: 12 * sy),
                            control2: CGPoint(x: 29.842 * sx, y: 13.154 * sy))
            yellow.addLine(to: CGPoint(x: 37.618 * sx, y: 9.382 * sy))
            yellow.addCurve(to: CGPoint(x: 24 * sx, y: 4 * sy),
                            control1: CGPoint(x: 34.046 * sx, y: 6.053 * sy),
                            control2: CGPoint(x: 29.268 * sx, y: 4 * sy))
            yellow.addCurve(to: CGPoint(x: 4 * sx, y: 24 * sy),
                            control1: CGPoint(x: 12.955 * sx, y: 4 * sy),
                            control2: CGPoint(x: 4 * sx, y: 12.955 * sy))
            yellow.addCurve(to: CGPoint(x: 24 * sx, y: 44 * sy),
                            control1: CGPoint(x: 4 * sx, y: 35.045 * sy),
                            control2: CGPoint(x: 12.955 * sx, y: 44 * sy))
            yellow.addCurve(to: CGPoint(x: 44 * sx, y: 24 * sy),
                            control1: CGPoint(x: 35.045 * sx, y: 44 * sy),
                            control2: CGPoint(x: 44 * sx, y: 35.045 * sy))
            yellow.addCurve(to: CGPoint(x: 43.611 * sx, y: 20.083 * sy),
                            control1: CGPoint(x: 44 * sx, y: 22.659 * sy),
                            control2: CGPoint(x: 43.862 * sx, y: 21.35 * sy))
            yellow.closeSubpath()
            context.fill(yellow, with: .color(Color(hex: "FFC107")))

            // Red arc
            var red = Path()
            red.move(to: CGPoint(x: 6.306 * sx, y: 14.691 * sy))
            red.addLine(to: CGPoint(x: 12.877 * sx, y: 19.51 * sy))
            red.addCurve(to: CGPoint(x: 24 * sx, y: 12 * sy),
                         control1: CGPoint(x: 14.655 * sx, y: 15.108 * sy),
                         control2: CGPoint(x: 18.961 * sx, y: 12 * sy))
            red.addCurve(to: CGPoint(x: 31.961 * sx, y: 15.039 * sy),
                         control1: CGPoint(x: 27.059 * sx, y: 12 * sy),
                         control2: CGPoint(x: 29.842 * sx, y: 13.154 * sy))
            red.addLine(to: CGPoint(x: 37.618 * sx, y: 9.382 * sy))
            red.addCurve(to: CGPoint(x: 24 * sx, y: 4 * sy),
                         control1: CGPoint(x: 34.046 * sx, y: 6.053 * sy),
                         control2: CGPoint(x: 29.268 * sx, y: 4 * sy))
            red.addCurve(to: CGPoint(x: 6.306 * sx, y: 14.691 * sy),
                         control1: CGPoint(x: 16.318 * sx, y: 4 * sy),
                         control2: CGPoint(x: 9.656 * sx, y: 8.337 * sy))
            red.closeSubpath()
            context.fill(red, with: .color(Color(hex: "FF3D00")))

            // Green arc
            var green = Path()
            green.move(to: CGPoint(x: 24 * sx, y: 44 * sy))
            green.addCurve(to: CGPoint(x: 37.409 * sx, y: 38.808 * sy),
                           control1: CGPoint(x: 29.166 * sx, y: 44 * sy),
                           control2: CGPoint(x: 33.86 * sx, y: 42.023 * sy))
            green.addLine(to: CGPoint(x: 31.219 * sx, y: 33.57 * sy))
            green.addCurve(to: CGPoint(x: 24 * sx, y: 36 * sy),
                           control1: CGPoint(x: 29.211 * sx, y: 35.091 * sy),
                           control2: CGPoint(x: 26.715 * sx, y: 36 * sy))
            green.addCurve(to: CGPoint(x: 12.717 * sx, y: 28.054 * sy),
                           control1: CGPoint(x: 18.798 * sx, y: 36 * sy),
                           control2: CGPoint(x: 14.381 * sx, y: 32.683 * sy))
            green.addLine(to: CGPoint(x: 6.195 * sx, y: 33.079 * sy))
            green.addCurve(to: CGPoint(x: 24 * sx, y: 44 * sy),
                           control1: CGPoint(x: 9.505 * sx, y: 39.556 * sy),
                           control2: CGPoint(x: 16.227 * sx, y: 44 * sy))
            green.closeSubpath()
            context.fill(green, with: .color(Color(hex: "4CAF50")))

            // Blue arc
            var blue = Path()
            blue.move(to: CGPoint(x: 43.611 * sx, y: 20.083 * sy))
            blue.addLine(to: CGPoint(x: 42 * sx, y: 20 * sy))
            blue.addLine(to: CGPoint(x: 24 * sx, y: 20 * sy))
            blue.addLine(to: CGPoint(x: 24 * sx, y: 28 * sy))
            blue.addLine(to: CGPoint(x: 35.303 * sx, y: 28 * sy))
            blue.addCurve(to: CGPoint(x: 31.216 * sx, y: 33.571 * sy),
                          control1: CGPoint(x: 34.511 * sx, y: 30.237 * sy),
                          control2: CGPoint(x: 33.072 * sx, y: 32.166 * sy))
            blue.addLine(to: CGPoint(x: 37.406 * sx, y: 38.809 * sy))  // via l6.19,5.238
            blue.addCurve(to: CGPoint(x: 44 * sx, y: 24 * sy),
                          control1: CGPoint(x: 36.971 * sx, y: 39.205 * sy),
                          control2: CGPoint(x: 44 * sx, y: 34 * sy))
            blue.addCurve(to: CGPoint(x: 43.611 * sx, y: 20.083 * sy),
                          control1: CGPoint(x: 44 * sx, y: 22.659 * sy),
                          control2: CGPoint(x: 43.862 * sx, y: 21.35 * sy))
            blue.closeSubpath()
            context.fill(blue, with: .color(Color(hex: "1976D2")))
        }
    }

    private var emailIcon: some View {
        Image(systemName: "envelope")
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(Color(hex: "101828"))
    }

    // MARK: - Background dots

    private var dotsBackground: some View {
        GeometryReader { geo in
            let dots: [(CGFloat, CGFloat, CGFloat)] = [
                (0.15, 0.10, 4), (0.80, 0.20, 4), (0.25, 0.30, 2),
                (0.70, 0.40, 4), (0.10, 0.50, 2), (0.85, 0.60, 4),
                (0.40, 0.70, 2), (0.60, 0.80, 4), (0.50, 0.15, 2),
                (0.20, 0.85, 4),
            ]
            ForEach(dots.indices, id: \.self) { i in
                let (x, y, size) = dots[i]
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size, height: size)
                    .position(x: geo.size.width * x, y: geo.size.height * y)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Email Sign Up Sheet

struct EmailSignUpSheet: View {
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    @State private var isLogin = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var error = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Mode toggle
                HStack {
                    Button { withAnimation { isLogin = false } } label: {
                        Text("Sign Up")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundStyle(isLogin ? Color(hex: "99A1AF") : Color(hex: "101828"))
                            .padding(.bottom, 4)
                            .overlay(alignment: .bottom) {
                                if !isLogin {
                                    Rectangle().fill(Color(hex: "B8735A")).frame(height: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)

                    Text("·").foregroundStyle(Color(hex: "99A1AF")).padding(.horizontal, 8)

                    Button { withAnimation { isLogin = true } } label: {
                        Text("Log In")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundStyle(isLogin ? Color(hex: "101828") : Color(hex: "99A1AF"))
                            .padding(.bottom, 4)
                            .overlay(alignment: .bottom) {
                                if isLogin {
                                    Rectangle().fill(Color(hex: "B8735A")).frame(height: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    if !isLogin {
                        poppinsField(icon: "person", placeholder: "Your name", text: $name)
                    }
                    poppinsField(icon: "envelope", placeholder: "Email address", text: $email, keyboard: .emailAddress)

                    // Password
                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "535964"))
                            .frame(width: 20)
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .font(.custom("Poppins-Regular", size: 14))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "535964"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color(hex: "EBE8E3"))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color(hex: "535964"), lineWidth: 0.75))
                }

                if !error.isEmpty {
                    Text(error)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(Color.agDestructive)
                        .transition(.opacity)
                }

                Button(action: submit) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        } else {
                            Text(isLogin ? "Log In" : "Create Account")
                                .font(.custom("Poppins-SemiBold", size: 16))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(Color(hex: "B8735A"))
                    .clipShape(Capsule())
                }
                .buttonStyle(OnboardingScaleStylePublic())
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1)

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle(isLogin ? "Welcome Back" : "Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(Color(hex: "535964"))
                }
            }
        }
    }

    private func poppinsField(icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "535964"))
                .frame(width: 20)
            TextField(placeholder, text: text)
                .font(.custom("Poppins-Regular", size: 14))
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(hex: "EBE8E3"))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color(hex: "535964"), lineWidth: 0.75))
    }

    private func submit() {
        withAnimation { error = "" }
        if !isLogin && name.trimmingCharacters(in: .whitespaces).isEmpty {
            withAnimation { error = "Please enter your name" }; return
        }
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            withAnimation { error = "Please enter your email" }; return
        }
        if password.count < 6 {
            withAnimation { error = "Password must be at least 6 characters" }; return
        }
        isLoading = true
        Task {
            let result = isLogin
                ? await authState.logIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
                : await authState.signUp(name: name.trimmingCharacters(in: .whitespaces), email: email.trimmingCharacters(in: .whitespaces), password: password)
            isLoading = false
            if result.success {
                onComplete()
            } else {
                withAnimation { error = result.error ?? "Something went wrong" }
            }
        }
    }
}

// Public version of OnboardingScaleStyle for use outside OnboardingView
struct OnboardingScaleStylePublic: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    SignUpView(
        onSignedUp: {},
        onBack: {}
    )
    .environment(AuthState())
}
