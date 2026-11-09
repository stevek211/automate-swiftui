import SwiftUI

// MARK: - SignUpView (auth method selector)

struct SignUpView: View {
    @Environment(AuthState.self) private var authState
    let isLogin: Bool
    let onSignedUp: () -> Void
    let onBack: () -> Void

    @State private var showEmailForm = false
    @State private var emailFormIsLogin: Bool = false
    @State private var socialAuthError = ""

    init(isLogin: Bool = false, onSignedUp: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.isLogin = isLogin
        self.onSignedUp = onSignedUp
        self.onBack = onBack
        self._emailFormIsLogin = State(initialValue: isLogin)
    }

    var body: some View {
        ZStack {
            dotsBackground

            VStack(spacing: 0) {
                Spacer()

                // Logo
                Image("app-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 100)
                    .shadow(color: Color(red: 0, green: 0.73, blue: 0.65).opacity(0.20), radius: 50, x: 0, y: 25)

                Spacer().frame(height: 20)

                // Title
                Text(isLogin ? "Welcome back" : "Create an account")
                    .font(.custom("Quicksand-SemiBold", size: 28))
                    .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))

                Spacer().frame(height: 28)

                // Auth buttons
                VStack(spacing: 12) {
                    authButton(icon: { appleIcon }, label: "Continue with Apple") {
                        AnalyticsService.shared.track(.signUpMethodSelected(method: "apple"))
                        Task {
                            let result = await authState.signInWithApple()
                            if result.success { onSignedUp() }
                            else if let e = result.error { socialAuthError = e }
                        }
                    }

                    authButton(icon: { googleIcon }, label: "Continue with Google") {
                        AnalyticsService.shared.track(.signUpMethodSelected(method: "google"))
                        Task {
                            let result = await authState.signInWithGoogle()
                            if result.success { onSignedUp() }
                            else if let e = result.error { socialAuthError = e }
                        }
                    }

                    authButton(icon: { emailIcon }, label: "Sign up with email") {
                        AnalyticsService.shared.track(.signUpMethodSelected(method: "email"))
                        emailFormIsLogin = isLogin
                        showEmailForm = true
                    }

                    #if DEBUG
                    authButton(icon: { Image(systemName: "hammer.fill").foregroundStyle(.orange) }, label: "Dev Bypass (skip auth)") {
                        authState.devBypass()
                        onSignedUp()
                    }
                    #endif
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // "Already have an account? Log in" toggle
                Button {
                    emailFormIsLogin = !isLogin
                    showEmailForm = true
                } label: {
                    HStack(spacing: 0) {
                        Text(isLogin ? "New here? " : "Already have an account? ")
                            .font(.custom("Quicksand-Light", size: 12))
                            .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.51))
                        Text(isLogin ? "Create an account" : "Log in")
                            .font(.custom("Quicksand-Regular", size: 12))
                            .foregroundStyle(Color(red: 0.60, green: 0.63, blue: 0.69))
                            .underline()
                    }
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 24)

                legalFooter
                    .padding(.bottom, 40)
            }

            if !socialAuthError.isEmpty {
                VStack {
                    Spacer()
                    Text(socialAuthError)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.agDestructive)
                        .clipShape(Capsule())
                        .padding(.bottom, 100)
                        .onTapGesture { socialAuthError = "" }
                }
            }
        }
        .background(onboardingGradient.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "101828"))
                }
            }
        }
        .navigationDestination(isPresented: $showEmailForm) {
            EmailFormView(
                isLoginMode: emailFormIsLogin,
                onComplete: { onSignedUp() }
            )
            .environment(authState)
        }
    }

    // MARK: - Auth Button

    private func authButton<I: View>(icon: () -> I, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon().frame(width: 20, height: 20)
                Text(label)
                    .font(.custom("Quicksand-Medium", size: 14))
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.white)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color(red: 0.63, green: 0.63, blue: 0.63), lineWidth: 0.5))
        }
        .buttonStyle(OnboardingScaleStylePublic())
    }

    // MARK: - Icons

    private var appleIcon: some View {
        Image(systemName: "apple.logo")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Color(hex: "101828"))
    }

    private var googleIcon: some View { GoogleIconCanvas() }

    private var emailIcon: some View {
        Image(systemName: "envelope")
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(Color(hex: "101828"))
    }

    // MARK: - Background

    private var dotsBackground: some View {
        // Positions are offsets from center, matching Figma spec exactly
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let dots: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (-135.94, -339.05, 3.99, 0.30),
                ( 120.22, -253.79, 3.99, 0.20),
                ( -97.53, -169.53, 1.99, 0.40),
                (  80.80,  -83.28, 3.99, 0.25),
                (-156.65,    0.99, 1.99, 0.30),
                ( 139.92,   87.25, 3.99, 0.20),
                ( -38.42,  171.51, 1.99, 0.35),
                (  41.40,  257.77, 3.99, 0.30),
                (   0.99, -297.43, 1.99, 0.25),
                (-116.24,  300.40, 3.99, 0.20),
            ]
            ForEach(dots.indices, id: \.self) { i in
                let (dx, dy, size, opacity) = dots[i]
                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: size, height: size)
                    .position(x: cx + dx, y: cy + dy)
            }
        }
        .ignoresSafeArea()
    }

    private var legalFooter: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                Text("By continuing, you agree to the ")
                    .font(.custom("Quicksand-Light", size: 12))
                    .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.51))
                Text("Terms of service")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundStyle(Color(red: 0.60, green: 0.63, blue: 0.69))
                    .underline()
            }
            HStack(spacing: 0) {
                Text("and ")
                    .font(.custom("Quicksand-Light", size: 12))
                    .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.51))
                Text("Privacy policy")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundStyle(Color(red: 0.60, green: 0.63, blue: 0.69))
                    .underline()
            }
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - EmailFormView

struct EmailFormView: View {
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    @State private var isLoginMode: Bool
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var error = ""
    @State private var showForgotPassword = false

    init(isLoginMode: Bool = false, onComplete: @escaping () -> Void) {
        self._isLoginMode = State(initialValue: isLoginMode)
        self.onComplete = onComplete
    }

    private var isFormValid: Bool {
        if isLoginMode {
            return !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 8
        }
        return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= 8
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.97, green: 0.96, blue: 0.95).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header: title + subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isLoginMode ? "Welcome back" : "Welcome to AutoMate!")
                            .font(.custom("Quicksand-Bold", size: 24))
                            .tracking(0.07)
                            .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))

                        Text(isLoginMode
                            ? "Log in to access your garage and vehicle maintenance history."
                            : "Create an account to access managing your service history, maintenance schedules, and more.")
                            .font(.custom("Quicksand-Regular", size: 14))
                            .foregroundStyle(Color(red: 0.29, green: 0.33, blue: 0.40))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 24)

                    // Form fields
                    VStack(alignment: .leading, spacing: 16) {
                        if !isLoginMode {
                            labeledField(label: "First name*", text: $firstName)
                            labeledField(label: "Last name*", text: $lastName)
                        }
                        labeledField(label: "Email address*", text: $email, keyboard: .emailAddress)
                        labeledPasswordField

                        if isLoginMode {
                            Button { showForgotPassword = true } label: {
                                Text("Forgot password?")
                                    .font(.custom("Quicksand-Medium", size: 13))
                                    .foregroundStyle(Color(red: 0.08, green: 0.36, blue: 0.99))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 16)

                    // Error
                    if !error.isEmpty {
                        Text(error)
                            .font(.custom("Quicksand-Regular", size: 12))
                            .foregroundStyle(Color.agDestructive)
                            .padding(.bottom, 8)
                            .transition(.opacity)
                    }

                    // Legal text
                    legalText
                        .padding(.bottom, 16)

                    // Continue / Log in button
                    Button(action: submit) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Text(isLoginMode ? "Log in" : "Continue")
                                    .font(.custom("Quicksand-Bold", size: 16))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(.white)
                        .background(isFormValid ? Color(red: 0.08, green: 0.36, blue: 0.99) : Color(red: 0.82, green: 0.84, blue: 0.86))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(OnboardingScaleStylePublic())
                    .disabled(isLoading)
                    .animation(.easeInOut(duration: 0.2), value: isFormValid)

                    // OR divider
                    HStack(spacing: 16) {
                        Rectangle().fill(Color(red: 0.90, green: 0.91, blue: 0.92)).frame(height: 1)
                        Text("or")
                            .font(.custom("Quicksand-Regular", size: 14))
                            .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.51))
                        Rectangle().fill(Color(red: 0.90, green: 0.91, blue: 0.92)).frame(height: 1)
                    }
                    .padding(.vertical, 16)

                    // Social icons
                    HStack(spacing: 16) {
                        Spacer()

                        // Apple
                        Button {
                            Task {
                                let result = await authState.signInWithApple()
                                if result.success { onComplete() }
                                else if let e = result.error { withAnimation { error = e } }
                            }
                        } label: {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(.black)
                                .clipShape(Circle())
                        }
                        .buttonStyle(OnboardingScaleStylePublic())

                        // Facebook — UI placeholder
                        Circle()
                            .fill(Color(red: 0.08, green: 0.36, blue: 0.99))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text("f")
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                    .foregroundStyle(.white)
                            )
                            .opacity(0.4)

                        // Google
                        Button {
                            Task {
                                let result = await authState.signInWithGoogle()
                                if result.success { onComplete() }
                                else if let e = result.error { withAnimation { error = e } }
                            }
                        } label: {
                            GoogleIconCanvas()
                                .frame(width: 24, height: 24)
                                .frame(width: 48, height: 48)
                                .background(.white)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color(red: 0.82, green: 0.84, blue: 0.86), lineWidth: 0.37))
                        }
                        .buttonStyle(OnboardingScaleStylePublic())

                        Spacer()
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .background(.white)
            }
            .background(.white)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(red: 0.04, green: 0.04, blue: 0.04))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLoginMode.toggle()
                        error = ""
                    }
                } label: {
                    Text(isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Log in")
                        .font(.custom("Quicksand-Medium", size: 13))
                        .foregroundStyle(Color(red: 0.04, green: 0.04, blue: 0.04))
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environment(authState)
        }
        .onAppear {
            if !isLoginMode { AnalyticsService.shared.track(.emailSignUpStarted) }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoginMode)
    }

    // MARK: - Labeled Field

    private func labeledField(label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("Quicksand-Medium", size: 12))
                .foregroundStyle(Color(red: 0.29, green: 0.33, blue: 0.40))

            TextField("", text: text)
                .font(.custom("Quicksand-Regular", size: 14))
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(red: 0.82, green: 0.84, blue: 0.86), lineWidth: 0.75)
                )
        }
    }

    // MARK: - Labeled Password Field

    private var labeledPasswordField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Password (8+ characters)*")
                .font(.custom("Quicksand-Medium", size: 12))
                .foregroundStyle(Color(red: 0.29, green: 0.33, blue: 0.40))

            HStack {
                Group {
                    if showPassword {
                        TextField("", text: $password)
                    } else {
                        SecureField("", text: $password)
                    }
                }
                .font(.custom("Quicksand-Regular", size: 14))
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.29, green: 0.33, blue: 0.40))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(red: 0.82, green: 0.84, blue: 0.86), lineWidth: 0.75)
            )
        }
    }

    // MARK: - Legal Text

    private var legalText: some View {
        (Text("By continuing, you agree to AutoMates ")
            .font(.custom("Quicksand-Regular", size: 12))
            .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.40))
        + Text("Terms & Conditions")
            .font(.custom("Quicksand-Medium", size: 12))
            .foregroundColor(Color(red: 0.08, green: 0.36, blue: 0.99))
        + Text(" and ")
            .font(.custom("Quicksand-Regular", size: 12))
            .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.40))
        + Text("Privacy Policy")
            .font(.custom("Quicksand-Medium", size: 12))
            .foregroundColor(Color(red: 0.08, green: 0.36, blue: 0.99))
        + Text(".")
            .font(.custom("Quicksand-Regular", size: 12))
            .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.40))
        )
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Submit

    private func submit() {
        withAnimation { error = "" }
        if !isLoginMode {
            if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                withAnimation { error = "Please enter your first name" }; return
            }
            if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
                withAnimation { error = "Please enter your last name" }; return
            }
        }
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            withAnimation { error = "Please enter your email" }; return
        }
        if password.count < 8 {
            withAnimation { error = "Password must be at least 8 characters" }; return
        }
        isLoading = true
        Task {
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            let result: (success: Bool, error: String?)
            if isLoginMode {
                result = await authState.logIn(email: trimmedEmail, password: password)
            } else {
                let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"
                result = await authState.signUp(name: fullName, email: trimmedEmail, password: password)
            }
            isLoading = false
            if result.success {
                if !isLoginMode { AnalyticsService.shared.track(.emailSignUpCompleted) }
                onComplete()
            } else {
                let reason = result.error ?? "Something went wrong"
                if !isLoginMode { AnalyticsService.shared.track(.emailSignUpFailed(reason: reason)) }
                withAnimation { error = reason }
            }
        }
    }
}

// MARK: - ForgotPasswordView

struct ForgotPasswordView: View {
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var error = ""
    @State private var showCheckEmail = false

    private var isEmailFilled: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title + subtitle
            VStack(alignment: .leading, spacing: 8) {
                Text("Forgot password?")
                    .font(.custom("Quicksand-Bold", size: 24))
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))

                Text("No worries, we'll send you reset instructions.")
                    .font(.custom("Quicksand-Regular", size: 14))
                    .foregroundStyle(Color(red: 0.29, green: 0.33, blue: 0.40))
            }
            .padding(.bottom, 24)

            // Email field
            VStack(alignment: .leading, spacing: 4) {
                Text("Email address*")
                    .font(.custom("Quicksand-Medium", size: 12))
                    .foregroundStyle(Color(red: 0.29, green: 0.33, blue: 0.40))

                TextField("Enter your email", text: $email)
                    .font(.custom("Quicksand-Regular", size: 16))
                    .foregroundStyle(Color(red: 0.04, green: 0.04, blue: 0.04))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color(red: 0.82, green: 0.84, blue: 0.86), lineWidth: 0.75)
                    )
            }
            .padding(.bottom, 16)

            // Error
            if !error.isEmpty {
                Text(error)
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundStyle(Color.agDestructive)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }

            // Reset password button
            Button(action: submitReset) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Text("Reset password")
                            .font(.custom("Quicksand-SemiBold", size: 16))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(.white)
                .background(isEmailFilled ? Color(red: 0.08, green: 0.36, blue: 0.99) : Color(red: 0.82, green: 0.84, blue: 0.86))
                .clipShape(Capsule())
            }
            .buttonStyle(OnboardingScaleStylePublic())
            .disabled(isLoading)
            .animation(.easeInOut(duration: 0.2), value: isEmailFilled)
            .padding(.bottom, 16)

            // Back to login
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("Back to login")
                        .font(.custom("Quicksand-Medium", size: 14))
                }
                .foregroundStyle(Color(red: 0.29, green: 0.33, blue: 0.40))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(red: 0.04, green: 0.04, blue: 0.04))
                }
            }
        }
        .navigationDestination(isPresented: $showCheckEmail) {
            CheckYourEmailView(email: email)
        }
        .animation(.easeInOut(duration: 0.2), value: error)
    }

    private func submitReset() {
        withAnimation { error = "" }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { error = "Please enter your email" }; return
        }
        isLoading = true
        Task {
            let result = await authState.resetPassword(email: email)
            isLoading = false
            if result.success {
                showCheckEmail = true
            } else {
                withAnimation { error = result.error ?? "Something went wrong" }
            }
        }
    }
}

// MARK: - CheckYourEmailView

struct CheckYourEmailView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Light green checkmark circle
            ZStack {
                Circle()
                    .fill(Color(red: 0.86, green: 0.99, blue: 0.91))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            }
            .padding(.bottom, 24)

            Text("Check your email")
                .font(.custom("Quicksand-Bold", size: 24))
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                .padding(.bottom, 12)

            Text("We've sent a password reset link to \(email)")
                .font(.custom("Quicksand-Regular", size: 14))
                .foregroundStyle(Color(red: 0.29, green: 0.33, blue: 0.40))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

            Text("Didn't receive the email? Check your spam folder or try again.")
                .font(.custom("Quicksand-Regular", size: 12))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.51))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { dismiss() }
            } label: {
                Text("Back to login")
                    .font(.custom("Quicksand-SemiBold", size: 16))
                    .frame(width: 320, height: 56)
                    .foregroundStyle(.white)
                    .background(Color(red: 0.08, green: 0.36, blue: 0.99))
                    .clipShape(Capsule())
            }
            .buttonStyle(OnboardingScaleStylePublic())

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Shared Helpers

var onboardingGradient: LinearGradient {
    LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.98, green: 0.97, blue: 0.96), location: 0.00),
            Gradient.Stop(color: Color(red: 0.94, green: 0.92, blue: 0.89), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
}

struct GoogleIconCanvas: View {
    var body: some View {
        Canvas { context, size in
            let sx = size.width / 48
            let sy = size.height / 48

            var yellow = Path()
            yellow.move(to: CGPoint(x: 43.611 * sx, y: 20.083 * sy))
            yellow.addLine(to: CGPoint(x: 42 * sx, y: 20 * sy))
            yellow.addLine(to: CGPoint(x: 24 * sx, y: 20 * sy))
            yellow.addLine(to: CGPoint(x: 24 * sx, y: 28 * sy))
            yellow.addLine(to: CGPoint(x: 35.303 * sx, y: 28 * sy))
            yellow.addCurve(to: CGPoint(x: 24 * sx, y: 36 * sy), control1: CGPoint(x: 33.654 * sx, y: 32.657 * sy), control2: CGPoint(x: 29.223 * sx, y: 36 * sy))
            yellow.addCurve(to: CGPoint(x: 12 * sx, y: 24 * sy), control1: CGPoint(x: 17.373 * sx, y: 36 * sy), control2: CGPoint(x: 12 * sx, y: 30.627 * sy))
            yellow.addCurve(to: CGPoint(x: 24 * sx, y: 12 * sy), control1: CGPoint(x: 12 * sx, y: 17.373 * sy), control2: CGPoint(x: 17.373 * sx, y: 12 * sy))
            yellow.addCurve(to: CGPoint(x: 31.961 * sx, y: 15.039 * sy), control1: CGPoint(x: 27.059 * sx, y: 12 * sy), control2: CGPoint(x: 29.842 * sx, y: 13.154 * sy))
            yellow.addLine(to: CGPoint(x: 37.618 * sx, y: 9.382 * sy))
            yellow.addCurve(to: CGPoint(x: 24 * sx, y: 4 * sy), control1: CGPoint(x: 34.046 * sx, y: 6.053 * sy), control2: CGPoint(x: 29.268 * sx, y: 4 * sy))
            yellow.addCurve(to: CGPoint(x: 4 * sx, y: 24 * sy), control1: CGPoint(x: 12.955 * sx, y: 4 * sy), control2: CGPoint(x: 4 * sx, y: 12.955 * sy))
            yellow.addCurve(to: CGPoint(x: 24 * sx, y: 44 * sy), control1: CGPoint(x: 4 * sx, y: 35.045 * sy), control2: CGPoint(x: 12.955 * sx, y: 44 * sy))
            yellow.addCurve(to: CGPoint(x: 44 * sx, y: 24 * sy), control1: CGPoint(x: 35.045 * sx, y: 44 * sy), control2: CGPoint(x: 44 * sx, y: 35.045 * sy))
            yellow.addCurve(to: CGPoint(x: 43.611 * sx, y: 20.083 * sy), control1: CGPoint(x: 44 * sx, y: 22.659 * sy), control2: CGPoint(x: 43.862 * sx, y: 21.35 * sy))
            yellow.closeSubpath()
            context.fill(yellow, with: .color(Color(hex: "FFC107")))

            var red = Path()
            red.move(to: CGPoint(x: 6.306 * sx, y: 14.691 * sy))
            red.addLine(to: CGPoint(x: 12.877 * sx, y: 19.51 * sy))
            red.addCurve(to: CGPoint(x: 24 * sx, y: 12 * sy), control1: CGPoint(x: 14.655 * sx, y: 15.108 * sy), control2: CGPoint(x: 18.961 * sx, y: 12 * sy))
            red.addCurve(to: CGPoint(x: 31.961 * sx, y: 15.039 * sy), control1: CGPoint(x: 27.059 * sx, y: 12 * sy), control2: CGPoint(x: 29.842 * sx, y: 13.154 * sy))
            red.addLine(to: CGPoint(x: 37.618 * sx, y: 9.382 * sy))
            red.addCurve(to: CGPoint(x: 24 * sx, y: 4 * sy), control1: CGPoint(x: 34.046 * sx, y: 6.053 * sy), control2: CGPoint(x: 29.268 * sx, y: 4 * sy))
            red.addCurve(to: CGPoint(x: 6.306 * sx, y: 14.691 * sy), control1: CGPoint(x: 16.318 * sx, y: 4 * sy), control2: CGPoint(x: 9.656 * sx, y: 8.337 * sy))
            red.closeSubpath()
            context.fill(red, with: .color(Color(hex: "FF3D00")))

            var green = Path()
            green.move(to: CGPoint(x: 24 * sx, y: 44 * sy))
            green.addCurve(to: CGPoint(x: 37.409 * sx, y: 38.808 * sy), control1: CGPoint(x: 29.166 * sx, y: 44 * sy), control2: CGPoint(x: 33.86 * sx, y: 42.023 * sy))
            green.addLine(to: CGPoint(x: 31.219 * sx, y: 33.57 * sy))
            green.addCurve(to: CGPoint(x: 24 * sx, y: 36 * sy), control1: CGPoint(x: 29.211 * sx, y: 35.091 * sy), control2: CGPoint(x: 26.715 * sx, y: 36 * sy))
            green.addCurve(to: CGPoint(x: 12.717 * sx, y: 28.054 * sy), control1: CGPoint(x: 18.798 * sx, y: 36 * sy), control2: CGPoint(x: 14.381 * sx, y: 32.683 * sy))
            green.addLine(to: CGPoint(x: 6.195 * sx, y: 33.079 * sy))
            green.addCurve(to: CGPoint(x: 24 * sx, y: 44 * sy), control1: CGPoint(x: 9.505 * sx, y: 39.556 * sy), control2: CGPoint(x: 16.227 * sx, y: 44 * sy))
            green.closeSubpath()
            context.fill(green, with: .color(Color(hex: "4CAF50")))

            var blue = Path()
            blue.move(to: CGPoint(x: 43.611 * sx, y: 20.083 * sy))
            blue.addLine(to: CGPoint(x: 42 * sx, y: 20 * sy))
            blue.addLine(to: CGPoint(x: 24 * sx, y: 20 * sy))
            blue.addLine(to: CGPoint(x: 24 * sx, y: 28 * sy))
            blue.addLine(to: CGPoint(x: 35.303 * sx, y: 28 * sy))
            blue.addCurve(to: CGPoint(x: 31.216 * sx, y: 33.571 * sy), control1: CGPoint(x: 34.511 * sx, y: 30.237 * sy), control2: CGPoint(x: 33.072 * sx, y: 32.166 * sy))
            blue.addLine(to: CGPoint(x: 37.406 * sx, y: 38.809 * sy))
            blue.addCurve(to: CGPoint(x: 44 * sx, y: 24 * sy), control1: CGPoint(x: 36.971 * sx, y: 39.205 * sy), control2: CGPoint(x: 44 * sx, y: 34 * sy))
            blue.addCurve(to: CGPoint(x: 43.611 * sx, y: 20.083 * sy), control1: CGPoint(x: 44 * sx, y: 22.659 * sy), control2: CGPoint(x: 43.862 * sx, y: 21.35 * sy))
            blue.closeSubpath()
            context.fill(blue, with: .color(Color(hex: "1976D2")))
        }
    }
}

// MARK: - Button Style

struct OnboardingScaleStylePublic: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Sign Up — method selector") {
    SignUpView(isLogin: false, onSignedUp: {}, onBack: {})
        .environment(AuthState())
}

#Preview("Email Form — Sign Up") {
    NavigationStack {
        EmailFormView(isLoginMode: false, onComplete: {})
            .environment(AuthState())
    }
}

#Preview("Email Form — Log In") {
    NavigationStack {
        EmailFormView(isLoginMode: true, onComplete: {})
            .environment(AuthState())
    }
}

#Preview("Forgot Password") {
    NavigationStack {
        ForgotPasswordView()
            .environment(AuthState())
    }
}

#Preview("Check Your Email") {
    NavigationStack {
        CheckYourEmailView(email: "stevekurien1@gmail.com")
    }
}
