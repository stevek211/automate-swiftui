import SwiftUI

/// Edit the selected vehicle's details from Home (year, odometer, make/model, trim).
/// Styled like the Log Service sheet via FormSheetScaffold.
struct EditVehicleSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var lookupManager = VehicleLookupManager()
    @State private var draft: Vehicle?
    @State private var mileageText = ""

    var body: some View {
        FormSheetScaffold(
            eyebrow: "Edit vehicle",
            title: draft?.displayName ?? "Your car",
            canSave: canSave,
            onClose: { dismiss() },
            onSave: save
        ) {
            if let draft = Binding($draft) {
                form(draft)
            }
        }
        .presentationDetents([.large])
        .onAppear {
            guard draft == nil, let vehicle = appState.selectedVehicle ?? appState.vehicles.first else { return }
            draft = vehicle
            mileageText = vehicle.mileage.formatted()
        }
        .task(id: trimLookupKey) {
            guard let draft, !draft.make.isEmpty, !draft.model.isEmpty else { return }
            lookupManager.trims = []
            await lookupManager.loadTrims(make: draft.make, model: draft.model, year: draft.year)
        }
    }

    // MARK: - Form

    private func form(_ draft: Binding<Vehicle>) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                FormSheetField(label: "Year") {
                    FormSheetMenuField(
                        selection: draft.year,
                        options: Self.yearRange(including: draft.wrappedValue.year),
                        label: { String($0) }
                    )
                }
                FormSheetField(label: "Odometer *") {
                    FormSheetTextField(placeholder: "", text: $mileageText, suffix: "mi", keyboard: .numberPad)
                        .monospacedDigit()
                        .onChange(of: mileageText) { _, newValue in
                            let formatted = formattedMileageInput(newValue)
                            if formatted != newValue { mileageText = formatted }
                        }
                }
            }

            FormSheetField(label: "Make *") {
                FormSheetTextField(placeholder: "e.g. Toyota", text: draft.make, capitalization: .words)
            }

            VStack(alignment: .leading, spacing: 8) {
                FormSheetField(label: "Model *") {
                    FormSheetTextField(placeholder: "e.g. Camry", text: draft.model, capitalization: .words)
                }
                FormSheetHint(text: "Changing the make or model updates the car photo. Your service schedule stays as it is.")
            }

            FormSheetField(label: "Trim") {
                FormSheetMenuField(
                    selection: trimBinding(draft),
                    options: [""] + trimOptions(current: draft.wrappedValue.trim),
                    label: { $0.isEmpty ? (lookupManager.isLoadingTrims ? "Loading…" : "Not set") : $0 }
                )
            }

            FormSheetField(label: "Body style") {
                FormSheetMenuField(
                    selection: Binding(
                        get: { draft.wrappedValue.bodyStyle ?? "" },
                        set: { draft.wrappedValue.bodyStyle = $0.isEmpty ? nil : $0 }
                    ),
                    options: [""] + Vehicle.bodyStyleOptions,
                    label: { $0.isEmpty ? "Not set" : $0 }
                )
            }
        }
    }

    // MARK: - Options

    /// API/database trims for this make/model/year, plus the individual names inside
    /// a combined trim like "S, Sport, SE, Autobahn" so the user can pick the real one.
    private func trimOptions(current: String?) -> [String] {
        var options: [String] = []
        let fetched = lookupManager.trims.isEmpty
            ? VehicleDatabase.trimsFor(make: draft?.make ?? "", model: draft?.model ?? "")
            : lookupManager.trims
        for trim in fetched + Self.splitTrims(current) {
            for part in Self.splitTrims(trim) where !options.contains(part) {
                options.append(part)
            }
        }
        // Keep the exact current value selectable even if it isn't in the list.
        if let current, !current.isEmpty, !options.contains(current) {
            options.insert(current, at: 0)
        }
        return options
    }

    static func splitTrims(_ trim: String?) -> [String] {
        guard let trim, !trim.isEmpty else { return [] }
        return trim
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func yearRange(including year: Int) -> [Int] {
        let latest = Calendar.current.component(.year, from: .now) + 1
        let earliest = min(1980, year)
        return Array((earliest...max(latest, year)).reversed())
    }

    private func trimBinding(_ draft: Binding<Vehicle>) -> Binding<String> {
        Binding(
            get: { draft.wrappedValue.trim ?? "" },
            set: { draft.wrappedValue.trim = $0.isEmpty ? nil : $0 }
        )
    }

    private var trimLookupKey: String {
        guard let draft else { return "" }
        return "\(draft.make)|\(draft.model)|\(draft.year)"
    }

    // MARK: - Save

    private var parsedMileage: Int? {
        Int(mileageText.filter(\.isNumber))
    }

    private var canSave: Bool {
        guard let draft else { return false }
        return !draft.make.trimmingCharacters(in: .whitespaces).isEmpty
            && !draft.model.trimmingCharacters(in: .whitespaces).isEmpty
            && parsedMileage != nil
    }

    private func save() {
        guard var updated = draft, let mileage = parsedMileage else { return }
        if appState.guardWrite() {
            dismiss()
            return
        }
        updated.make = updated.make.trimmingCharacters(in: .whitespaces)
        updated.model = updated.model.trimmingCharacters(in: .whitespaces)
        updated.mileage = mileage
        appState.updateVehicle(updated)

        if let userId = authState.currentUser?.id,
           let saved = appState.vehicles.first(where: { $0.id == updated.id }) {
            Task { await SupabaseManager.upsertVehicle(saved, userId: userId) }
        }
        dismiss()
    }
}
