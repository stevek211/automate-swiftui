import SwiftUI

struct MileageUpdaterSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss
    @State private var mileageText = ""
    @FocusState private var mileageFocused: Bool

    private var vehicle: Vehicle? { appState.selectedVehicle ?? appState.vehicles.first }

    var body: some View {
        FormSheetScaffold(
            eyebrow: "Update mileage",
            title: vehicle?.displayName ?? "Your car",
            canSave: parsedMileage != nil,
            onClose: { dismiss() },
            onSave: save
        ) {
            if let vehicle {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 16) {
                        FormSheetField(label: "Current odometer") {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(vehicle.mileage.formatted())
                                    .font(.quicksand(.regular, size: 17))
                                    .foregroundStyle(ServicePlanPalette.textSecondary)
                                    .monospacedDigit()
                                Text("mi")
                                    .font(.quicksand(.regular, size: 15))
                                    .foregroundStyle(FormSheetStyle.labelColor)
                            }
                        }

                        FormSheetField(label: "New odometer *") {
                            FormSheetTextField(
                                placeholder: "",
                                text: $mileageText,
                                suffix: "mi",
                                keyboard: .numberPad
                            )
                            .monospacedDigit()
                            .focused($mileageFocused)
                            .onChange(of: mileageText) { _, newValue in
                                let formatted = formattedMileageInput(newValue)
                                if formatted != newValue { mileageText = formatted }
                            }
                        }
                    }

                    FormSheetHint(text: lastUpdatedHint(vehicle))
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { mileageFocused = true }
    }

    private func lastUpdatedHint(_ vehicle: Vehicle) -> String {
        guard let updated = vehicle.mileageUpdatedAt else {
            return "Check the number on your dashboard. Keeping it current makes your service reminders accurate."
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let when = Calendar.current.isDateInToday(updated)
            ? "today"
            : formatter.localizedString(for: updated, relativeTo: .now)
        return "Last updated \(when). Keeping it current makes your service reminders accurate."
    }

    private var parsedMileage: Int? {
        Int(mileageText.filter(\.isNumber))
    }

    private func save() {
        guard let mileage = parsedMileage else { return }
        appState.updateMileage(mileage)
        if !appState.isDemo,
           let userId = authState.currentUser?.id,
           let saved = appState.selectedVehicle {
            Task { await SupabaseManager.upsertVehicle(saved, userId: userId) }
        }
        dismiss()
    }
}

#Preview {
    MileageUpdaterSheet()
        .environment(AppState())
        .environment(AuthState())
}
