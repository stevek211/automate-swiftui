import SwiftUI

/// Account details, pushed from the profile row in Settings (Figma "Account", node 527:4848).
struct AccountView: View {
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false
    @State private var isSendingReset = false
    @State private var resetAlert: ResetAlert?

    private var ink: Color { Color.garageInk }
    private var label: Color { Color.settingsLabel }

    private var user: LocalUser? { authState.currentUser }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 12)

                accountSection

                if user?.authProvider == .email {
                    changePasswordButton
                        .padding(.top, 20)
                }

                Rectangle()
                    .fill(Color.garageHairline)
                    .frame(height: 0.625)
                    .padding(.top, 96)

                Button { showDeleteConfirmation = true } label: {
                    Text("Delete account")
                        .font(.quicksand(.bold, size: 14))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { _ = await authState.deleteAccount() }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .alert(item: $resetAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }

    // MARK: - Pieces

    private var header: some View {
        ZStack {
            Text("Account")
                .font(.quicksand(.bold, size: 16))
                .foregroundStyle(ink)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Button { dismiss() } label: {
                    Image("settings-icon-back")
                        .renderingMode(.template)
                        .foregroundStyle(ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Back")
                Spacer()
            }
        }
        .frame(height: 44)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR ACCOUNT")
                .font(.quicksand(.semibold, size: 12))
                .foregroundStyle(label)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                detailRow("Name", value: user?.name ?? "Driver")
                divider
                detailRow("Email", value: user?.email ?? "—")
                divider
                detailRow("Login method", value: loginMethod)
            }
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
        }
    }

    private var changePasswordButton: some View {
        Button { sendPasswordReset() } label: {
            ZStack {
                Text("Change password")
                    .font(.quicksand(.bold, size: 14))
                    .foregroundStyle(ink)
                    .opacity(isSendingReset ? 0 : 1)
                if isSendingReset {
                    ProgressView().tint(ink)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isSendingReset)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.settingsRowDivider)
            .frame(height: 0.625)
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.quicksand(.regular, size: 14))
                .foregroundStyle(label)
            Spacer(minLength: 0)
            Text(value)
                .font(.quicksand(.bold, size: 14))
                .foregroundStyle(ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .frame(minHeight: 64)
        .accessibilityElement(children: .combine)
    }

    private var loginMethod: String {
        switch user?.authProvider {
        case .apple: return "Sign in with Apple"
        case .google: return "Google"
        default: return "Email & password"
        }
    }

    private func sendPasswordReset() {
        guard let email = user?.email else { return }
        isSendingReset = true
        Task {
            let result = await authState.resetPassword(email: email)
            isSendingReset = false
            resetAlert = result.success
                ? ResetAlert(title: "Check your email", message: "We sent a link to \(email) to change your password.")
                : ResetAlert(title: "Couldn't send link", message: result.error ?? "Please try again.")
        }
    }
}

private struct ResetAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#Preview {
    NavigationStack {
        AccountView()
            .environment(AuthState())
    }
}
