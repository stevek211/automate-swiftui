import StoreKit
import SwiftUI

/// Settings sheet (Figma "Settings", node 526:4677).
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @AppStorage("settings.maintenanceDueReminders") private var maintenanceDueReminders = true
    @AppStorage("settings.mileageCheckIn") private var mileageCheckIn = MileageCheckIn.monthly.rawValue
    @AppStorage("settings.tipsAndExplainers") private var tipsAndExplainers = true

    @State private var showLogoutConfirmation = false
    @State private var cacheClearedMessage: String?

    private let ink = Color.garageInk
    private let muted = Color.settingsMuted

    var body: some View {
        NavigationStack {
            settingsContent
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: SettingsRoute.self) { route in
                    switch route {
                    case .account: AccountView()
                    }
                }
        }
    }

    private var settingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                backButton
                    .padding(.bottom, 24)

                title
                    .padding(.bottom, 20)

                profileRow
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 28)

                VStack(alignment: .leading, spacing: 28) {
                    remindersSection
                    dataSection
                    supportSection
                    legalSection
                    #if DEBUG
                    debugSection
                    #endif
                }

                logOutButton
                    .padding(.top, 28)

                Text("Version 1.0.0")
                    .font(.quicksand(.regular, size: 12))
                    .foregroundStyle(muted.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .appBackground()
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                Task {
                    await authState.logOut()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Header

    private var backButton: some View {
        Button { dismiss() } label: {
            Image("settings-icon-back")
                .renderingMode(.template)
                .foregroundStyle(ink)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(Color.settingsBackBorder, lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 1.5, y: 1)
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Back")
    }

    private var title: some View {
        Text("Settings\(Text(".").foregroundStyle(Color.settingsAccentDot))")
            .foregroundStyle(ink)
            .font(.quicksand(.bold, size: 40))
            .accessibilityAddTraits(.isHeader)
    }

    private var profileRow: some View {
        let name = authState.currentUser?.name ?? "Driver"
        let email = authState.currentUser?.email ?? ""

        return NavigationLink(value: SettingsRoute.account) {
        HStack(spacing: 12) {
            Text(initials(for: name))
                .font(.quicksand(.bold, size: 20))
                .foregroundStyle(ink)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.settingsAvatarFill))

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.quicksand(.bold, size: 18))
                    .foregroundStyle(ink)
                if !email.isEmpty {
                    Text(email)
                        .font(.quicksand(.regular, size: 14))
                        .foregroundStyle(muted)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Image("settings-icon-arrow-up-right")
                .renderingMode(.template)
                .foregroundStyle(ink)
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.garageHairline, lineWidth: 1))
                .padding(.leading, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20.6)
        .overlay(alignment: .top) { hairline }
        .overlay(alignment: .bottom) { hairline }
        .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens your account")
    }

    private var hairline: some View {
        Rectangle().fill(Color.garageHairline).frame(height: 0.625)
    }

    // MARK: - Sections

    private var remindersSection: some View {
        section(number: "01", title: "Reminders") {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    rowIcon("settings-icon-bell", size: 20)
                    VStack(alignment: .leading, spacing: 4) {
                        rowTitle("Maintenance due", weight: .bold)
                        Text("We'll nudge you before a service is due")
                            .font(.quicksand(.regular, size: 14))
                            .foregroundStyle(muted)
                            .lineSpacing(4)
                            .frame(maxWidth: 192, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Toggle("Maintenance due", isOn: $maintenanceDueReminders)
                        .toggleStyle(SettingsSwitchStyle())
                }
                .padding(.vertical, 12)
                .frame(minHeight: 56)

                HStack(spacing: 12) {
                    rowIcon("settings-icon-gauge", size: 20)
                    rowTitle("Mileage check-in", weight: .bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    mileagePicker
                }
                .padding(.vertical, 12)
                .frame(minHeight: 56)

                HStack(spacing: 12) {
                    rowIcon("settings-icon-bulb", size: 20)
                    rowTitle("Tips & explainers", weight: .bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Toggle("Tips & explainers", isOn: $tipsAndExplainers)
                        .toggleStyle(SettingsSwitchStyle())
                }
                .padding(.vertical, 16)
                .frame(minHeight: 56)
            }
        }
    }

    private var mileagePicker: some View {
        Menu {
            Picker("Mileage check-in", selection: $mileageCheckIn) {
                ForEach(MileageCheckIn.allCases) { option in
                    Text(option.label).tag(option.rawValue)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(MileageCheckIn(rawValue: mileageCheckIn)?.label ?? MileageCheckIn.monthly.label)
                    .font(.quicksand(.regular, size: 14))
                    .foregroundStyle(ink)
                Image("settings-icon-chevron-down")
                    .renderingMode(.template)
                    .foregroundStyle(muted)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Capsule().fill(Color.settingsChipFill))
        }
        .accessibilityLabel("Mileage check-in")
    }

    private var dataSection: some View {
        section(number: "02", title: "Your data") {
            VStack(spacing: 8) {
                Button {
                    // PDF export isn't built yet.
                } label: {
                    serviceHistoryCard
                }
                .buttonStyle(ScaleButtonStyle())

                linkRow("Privacy", icon: "settings-icon-shield") {}
            }
        }
    }

    private var serviceHistoryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image("settings-icon-download")
                    .renderingMode(.template)
                    .foregroundStyle(ink)
                Text("PDF EXPORT")
                    .font(.quicksand(.bold, size: 12))
                    .foregroundStyle(ink)
            }
            Text("Service history")
                .font(.quicksand(.bold, size: 20))
                .foregroundStyle(ink)
                .padding(.top, 4)
            Text("For your next mechanic. Or your car's next chapter.")
                .font(.quicksand(.regular, size: 14))
                .foregroundStyle(muted)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 220, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 144, alignment: .leading)
        .background(alignment: .bottomTrailing) {
            Image("settings-history-illustration")
                .resizable()
                .scaledToFit()
                .frame(width: 144, height: 112)
                .blendMode(.multiply)
                .offset(x: 16, y: -4)
        }
        .overlay(alignment: .topTrailing) {
            Image("settings-icon-card-arrow")
                .renderingMode(.template)
                .foregroundStyle(ink)
                .padding(12)
        }
        .background(Color.settingsAvatarFill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }

    private var supportSection: some View {
        section(number: "03", title: "Support") {
            VStack(spacing: 0) {
                linkRow("Help & FAQ", icon: "settings-icon-help") {}
                linkRow("Contact us", icon: "settings-icon-mail") {}
                linkRow("Rate AutoMate", icon: "settings-icon-star") { requestReview() }
                ShareLink(item: "I use AutoMate to keep track of my car's maintenance. Check it out!") {
                    linkRowLabel("Share with a friend", icon: "settings-icon-share")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var legalSection: some View {
        section(number: "04", title: "Legal") {
            HStack(spacing: 24) {
                legalLink("Privacy Policy")
                legalLink("Terms")
            }
        }
    }

    #if DEBUG
    private var debugSection: some View {
        section(number: "05", title: "Debug") {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    rowTitle("Demo mode", weight: .semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Toggle("Demo mode", isOn: Binding(
                        get: { appState.isDemo },
                        set: { newValue in
                            withAnimation(.spring(duration: 0.25)) { appState.isDemo = newValue }
                        }
                    ))
                    .toggleStyle(SettingsSwitchStyle())
                }
                .frame(minHeight: 48)

                linkRow("Clear OEM schedule cache", icon: "settings-icon-help", showsChevron: false) {
                    let count = AIMaintenanceAnalyzer.clearCache()
                    cacheClearedMessage = count == 0
                        ? "No cached schedules to clear."
                        : "Cleared \(count) cached schedule\(count == 1 ? "" : "s")."
                }
                if let msg = cacheClearedMessage {
                    Text(msg)
                        .font(.quicksand(.regular, size: 13))
                        .foregroundStyle(muted)
                }
            }
        }
    }
    #endif

    private var logOutButton: some View {
        Button { showLogoutConfirmation = true } label: {
            HStack(spacing: 8) {
                Image("settings-icon-logout")
                    .renderingMode(.template)
                    .foregroundStyle(ink)
                Text("Log Out")
                    .font(.quicksand(.bold, size: 16))
                    .foregroundStyle(ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Building blocks

    private func section<Content: View>(
        number: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(number)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(muted)
                Text(title)
                    .font(.quicksand(.bold, size: 18))
                    .foregroundStyle(ink)
                    .accessibilityAddTraits(.isHeader)
                hairline
                    .padding(.leading, 4)
            }
            content()
        }
    }

    private func rowIcon(_ name: String, size: CGFloat = 16) -> some View {
        Image(name)
            .renderingMode(.template)
            .foregroundStyle(muted)
            .frame(width: size, height: size)
    }

    private func rowTitle(_ text: String, weight: QuicksandWeight) -> some View {
        Text(text)
            .font(.quicksand(weight, size: 16))
            .foregroundStyle(ink)
    }

    private func linkRow(
        _ title: String,
        icon: String,
        showsChevron: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            linkRowLabel(title, icon: icon, showsChevron: showsChevron)
        }
        .buttonStyle(.plain)
    }

    private func linkRowLabel(_ title: String, icon: String, showsChevron: Bool = true) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .renderingMode(.template)
                .foregroundStyle(ink)
            rowTitle(title, weight: .semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            if showsChevron {
                Image("settings-icon-chevron-right")
                    .renderingMode(.template)
                    .foregroundStyle(muted)
            }
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }

    private func legalLink(_ title: String) -> some View {
        Button {
            // Policy URLs not set up yet.
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.quicksand(.medium, size: 14))
                    .foregroundStyle(muted)
                Image("settings-icon-external")
                    .renderingMode(.template)
                    .foregroundStyle(muted)
            }
            .frame(height: 36)
        }
        .buttonStyle(.plain)
    }

    private func initials(for name: String) -> String {
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}

enum SettingsRoute: Hashable {
    case account
}

/// How often to ask for an odometer reading.
private enum MileageCheckIn: String, CaseIterable, Identifiable {
    case weekly, biweekly, monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        }
    }
}

/// Small navy pill switch from the design (36×20, white knob).
private struct SettingsSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                configuration.isOn.toggle()
            }
        } label: {
            Capsule()
                .fill(configuration.isOn ? Color.garageInk : Color(hex: "CBD5E1"))
                .frame(width: 36, height: 20)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                        .padding(2)
                }
                .shadow(color: .black.opacity(0.1), radius: 1.5, y: 1)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(AuthState())
}
