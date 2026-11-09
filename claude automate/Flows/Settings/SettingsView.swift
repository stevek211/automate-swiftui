import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var cacheClearedMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section {
                    HStack(spacing: AGSpacing.lg) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.agPrimary)

                        VStack(alignment: .leading, spacing: AGSpacing.xs) {
                            Text(authState.currentUser?.name ?? "Driver")
                                .font(.poppinsHeadline)
                            Text(authState.currentUser?.email ?? "")
                                .font(.poppinsCaption)
                                .foregroundStyle(Color.agMutedForeground)
                        }
                    }
                    .padding(.vertical, AGSpacing.sm)
                }

                // Account
                Section("Account") {
                    Button {
                        // Reset password placeholder
                    } label: {
                        Label("Reset Password", systemImage: "lock.rotation")
                    }

                    Button {
                        // Rate app placeholder
                    } label: {
                        Label("Rate AutoGuard", systemImage: "star.fill")
                    }
                }

                // App Info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Color.agMutedForeground)
                    }

                    // Mode row — tappable to toggle demo
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            appState.isDemo.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Mode")
                                .foregroundStyle(Color.agForeground)
                            Spacer()
                            if appState.isDemo {
                                Text("Demo")
                                    .font(.poppinsCaption)
                                    .foregroundStyle(Color.agAccent)
                                    .padding(.horizontal, AGSpacing.sm)
                                    .padding(.vertical, AGSpacing.xs)
                                    .background(Color.agAccent.opacity(0.1))
                                    .clipShape(Capsule())
                            } else {
                                Text("Live")
                                    .font(.poppinsCaption)
                                    .foregroundStyle(Color.agSuccess)
                                    .padding(.horizontal, AGSpacing.sm)
                                    .padding(.vertical, AGSpacing.xs)
                                    .background(Color.agSuccess.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Button {
                        let count = AIMaintenanceAnalyzer.clearCache()
                        cacheClearedMessage = count == 0
                            ? "No cached schedules to clear."
                            : "Cleared \(count) cached schedule\(count == 1 ? "" : "s")."
                    } label: {
                        Label("Clear OEM Schedule Cache", systemImage: "trash.slash")
                    }
                    if let msg = cacheClearedMessage {
                        Text(msg)
                            .font(.poppinsCaption)
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
                #endif

                // Actions
                Section {
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
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
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        _ = await authState.deleteAccount()
                        dismiss()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(AuthState())
}
