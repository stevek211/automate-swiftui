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
                heroIllustration
                    // Clear the Dynamic Island so the driver's hair doesn't crowd it.
                    .padding(.top, 36)

                Spacer().frame(height: 40)

                // Title
                Text(isLogin ? "Welcome back" : "Create an account")
                    .font(.custom("Quicksand-SemiBold", size: 28))
                    .tracking(-0.53)
                    .foregroundColor(Color.theme.ink)
                    .frame(height: 40)

                Spacer().frame(height: 46)

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

                Spacer().frame(height: 31)

                // "Already have an account? Log in" toggle
                Button {
                    emailFormIsLogin = !isLogin
                    showEmailForm = true
                } label: {
                    HStack(spacing: 0) {
                        Text(isLogin ? "New here? " : "Already have an account? ")
                            .font(.custom("Quicksand-Regular", size: 12))
                            .foregroundStyle(Color(hex: "7E8694"))
                        Text(isLogin ? "Create an account" : "Log in")
                            .font(.custom("Quicksand-Regular", size: 12))
                            .tracking(-0.31)
                            .foregroundStyle(Color(hex: "7E8694"))
                            .underline()
                    }
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 24)

                legalFooter

                Spacer(minLength: 24)
            }
            .ignoresSafeArea(edges: .top)

            if !socialAuthError.isEmpty {
                VStack {
                    Spacer()
                    Text(socialAuthError)
                        .font(.quicksandScaled(.regular, size: 13))
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
        .background(Color.theme.card.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
        .standardBackButton(action: onBack)
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
            HStack(spacing: 16) {
                icon().frame(width: 20, height: 24)
                Text(label)
                    .font(.custom("Quicksand-Medium", size: 14))
                    .tracking(-0.15)
                    .foregroundStyle(Color.theme.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 53.5)
            .background(Color.theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(Color(hex: "A2A2A2"), lineWidth: 0.75))
        }
        .buttonStyle(OnboardingScaleStylePublic())
    }

    // MARK: - Hero

    /// Car illustration bleeding to the top edge, with the "REV" plate on the door.
    private var heroIllustration: some View {
        GeometryReader { geo in
            // Figma: 406pt-wide image on a 394pt screen, offset 6pt left.
            let width = geo.size.width * 406 / 394
            let height = width * 271 / 406
            Image("signup-hero")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .overlay(alignment: .top) {
                    Text("REV")
                        .font(.custom("Noteworthy-Light", size: 28))
                        .tracking(5)
                        .foregroundStyle(Color(hex: "ECECEE"))
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
                        .frame(height: 40)
                        .offset(x: 6.5, y: height * 181 / 271)
                }
                .offset(x: -6 * geo.size.width / 394)
        }
        .aspectRatio(394.0 / 271.0, contentMode: .fit)
        .accessibilityHidden(true)
    }

    // MARK: - Icons

    private var appleIcon: some View {
        Image("auth-apple").resizable().frame(width: 20, height: 23.8)
    }

    private var googleIcon: some View {
        Image("auth-google").resizable().frame(width: 20, height: 20)
    }

    private var emailIcon: some View {
        Image("auth-email").resizable().frame(width: 20, height: 20)
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
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                Text("By continuing, you agree to the ")
                    .font(.custom("Quicksand-Light", size: 12))
                    .foregroundStyle(Color.theme.mutedText)
                Text("Terms of service")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundStyle(Color.theme.faintText)
                    .underline()
            }
            HStack(spacing: 0) {
                Text("and ")
                    .font(.custom("Quicksand-Light", size: 12))
                    .foregroundStyle(Color.theme.mutedText)
                Text("Privacy policy")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundStyle(Color.theme.faintText)
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
    /// The field being edited; the form scrolls it above the keyboard.
    @FocusState private var focusedField: SignUpField?

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
            Color.theme.background.ignoresSafeArea()

            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header: title + subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isLoginMode ? "Welcome back" : "Welcome to AutoMate!")
                            .font(.custom("Quicksand-Bold", size: 24))
                            .tracking(0.07)
                            .foregroundStyle(Color.theme.ink)

                        Text(isLoginMode
                            ? "Log in to access your garage and vehicle maintenance history."
                            : "Create an account to access managing your service history, maintenance schedules, and more.")
                            .font(.custom("Quicksand-Regular", size: 14))
                            .foregroundStyle(Color.theme.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 24)

                    // Form fields
                    VStack(alignment: .leading, spacing: 16) {
                        if !isLoginMode {
                            labeledField(label: "First name*", text: $firstName, field: .firstName)
                            labeledField(label: "Last name*", text: $lastName, field: .lastName)
                        }
                        labeledField(label: "Email address*", text: $email, keyboard: .emailAddress, field: .email)
                        labeledPasswordField

                        if isLoginMode {
                            Button { showForgotPassword = true } label: {
                                Text("Forgot password?")
                                    .font(.custom("Quicksand-Medium", size: 13))
                                    .foregroundStyle(Color.theme.brand)
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
                        .background(isFormValid ? Color.theme.brand : Color.theme.borderStrong)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(OnboardingScaleStylePublic())
                    .disabled(isLoading)
                    .animation(.easeInOut(duration: 0.2), value: isFormValid)

                    // OR divider
                    HStack(spacing: 16) {
                        Rectangle().fill(Color.theme.border).frame(height: 1)
                        Text("or")
                            .font(.custom("Quicksand-Regular", size: 14))
                            .foregroundStyle(Color.theme.mutedText)
                        Rectangle().fill(Color.theme.border).frame(height: 1)
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
                            .fill(Color.theme.brand)
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
                                .overlay(Circle().strokeBorder(Color.theme.borderStrong, lineWidth: 0.37))
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
            .scrollDismissesKeyboard(.interactively)
            // Bring the field being edited fully above the keyboard once it has opened.
            .onChange(of: focusedField) { _, field in
                guard let field else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(field, anchor: .center)
                    }
                }
            }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .standardBackButton()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLoginMode.toggle()
                        error = ""
                    }
                } label: {
                    Text(isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Log in")
                        .font(.custom("Quicksand-Medium", size: 13))
                        .foregroundStyle(Color.theme.ink)
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

    private func labeledField(label: String, text: Binding<String>, keyboard: UIKeyboardType = .default, field: SignUpField) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("Quicksand-Medium", size: 12))
                .foregroundStyle(Color.theme.mutedText)

            TextField("", text: text)
                .font(.custom("Quicksand-Regular", size: 14))
                .foregroundStyle(Color.theme.ink)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit { focusedField = field.next }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.theme.borderStrong, lineWidth: 0.75)
                )
        }
        .id(field)
    }

    // MARK: - Labeled Password Field

    private var labeledPasswordField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Password (8+ characters)*")
                .font(.custom("Quicksand-Medium", size: 12))
                .foregroundStyle(Color.theme.mutedText)

            HStack {
                Group {
                    if showPassword {
                        TextField("", text: $password)
                    } else {
                        SecureField("", text: $password)
                    }
                }
                .font(.custom("Quicksand-Regular", size: 14))
                .foregroundStyle(Color.theme.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .password)
                .submitLabel(isLoginMode ? .go : .done)
                .onSubmit {
                    focusedField = nil
                    if isFormValid { submit() }
                }

                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.theme.mutedText)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.theme.borderStrong, lineWidth: 0.75)
            )
        }
        .id(SignUpField.password)
    }

    // MARK: - Legal Text

    private var legalText: some View {
        (Text("By continuing, you agree to AutoMates ")
            .font(.custom("Quicksand-Regular", size: 12))
            .foregroundColor(Color.theme.mutedText)
        + Text("Terms & Conditions")
            .font(.custom("Quicksand-Medium", size: 12))
            .foregroundColor(Color.theme.brand)
        + Text(" and ")
            .font(.custom("Quicksand-Regular", size: 12))
            .foregroundColor(Color.theme.mutedText)
        + Text("Privacy Policy")
            .font(.custom("Quicksand-Medium", size: 12))
            .foregroundColor(Color.theme.brand)
        + Text(".")
            .font(.custom("Quicksand-Regular", size: 12))
            .foregroundColor(Color.theme.mutedText)
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

private enum SignUpField: Hashable {
    case firstName, lastName, email, password

    /// Where the keyboard's return key goes from this field.
    var next: SignUpField? {
        switch self {
        case .firstName: return .lastName
        case .lastName: return .email
        case .email: return .password
        case .password: return nil
        }
    }
}

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
                    .foregroundStyle(Color.theme.ink)

                Text("No worries, we'll send you reset instructions.")
                    .font(.custom("Quicksand-Regular", size: 14))
                    .foregroundStyle(Color.theme.mutedText)
            }
            .padding(.bottom, 24)

            // Email field
            VStack(alignment: .leading, spacing: 4) {
                Text("Email address*")
                    .font(.custom("Quicksand-Medium", size: 12))
                    .foregroundStyle(Color.theme.mutedText)

                TextField("Enter your email", text: $email)
                    .font(.custom("Quicksand-Regular", size: 16))
                    .foregroundStyle(Color.theme.ink)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.theme.borderStrong, lineWidth: 0.75)
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
                .background(isEmailFilled ? Color.theme.brand : Color.theme.borderStrong)
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
                .foregroundStyle(Color.theme.mutedText)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.white.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
        .standardBackButton()
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
                    .fill(Color.theme.success.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.theme.ink)
            }
            .padding(.bottom, 24)

            Text("Check your email")
                .font(.custom("Quicksand-Bold", size: 24))
                .foregroundStyle(Color.theme.ink)
                .padding(.bottom, 12)

            Text("We've sent a password reset link to \(email)")
                .font(.custom("Quicksand-Regular", size: 14))
                .foregroundStyle(Color.theme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

            Text("Didn't receive the email? Check your spam folder or try again.")
                .font(.custom("Quicksand-Regular", size: 12))
                .foregroundStyle(Color.theme.mutedText)
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
                    .background(Color.theme.brand)
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
            Gradient.Stop(color: Color.theme.background, location: 0.00),
            Gradient.Stop(color: Color.theme.surfaceAlt, location: 1.00),
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
