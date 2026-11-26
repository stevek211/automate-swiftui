import SwiftUI
import UIKit
import Supabase

struct AddVehicleFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    // Entry-point config
    var allowDismiss: Bool = true
    var primaryCTA: String = "Add Vehicle"
    var onComplete: (() -> Void)? = nil

    // Vehicle fields
    @State private var vinInput = ""
    @State private var selectedYear: Int? = nil
    @State private var selectedMake = ""
    @State private var selectedModel = ""
    /// The user chose "Not listed? Type it in" on the Model menu.
    @State private var isTypingModel = false
    @State private var selectedTrim = ""
    @State private var selectedBodyStyle = ""
    @State private var mileageInput = ""
    @State private var lookupManager = VehicleLookupManager()

    // Driving profile
    @State private var selectedUsage: Set<String> = []
    @State private var selectedConditions: Set<String> = []
    @State private var selectedAnnualMileage = ""

    // Sheet state
    @State private var showDiscardConfirm = false
    @State private var addedVehicle: Vehicle? = nil

    private var mileageValue: Int {
        Int(mileageInput.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var canSubmit: Bool {
        selectedYear != nil &&
        !selectedMake.isEmpty &&
        !selectedModel.isEmpty &&
        mileageValue > 0 &&
        !selectedUsage.isEmpty &&
        !selectedConditions.isEmpty &&
        !selectedAnnualMileage.isEmpty
    }

    var body: some View {
        if let vehicle = addedVehicle {
            PostVehicleServiceSetupFlow(vehicle: vehicle) {
                if let onComplete { onComplete() } else { dismiss() }
            }
            .transition(.move(edge: .trailing))
        } else {
            formBody
                .keyboardDoneBar()
        }
    }

    private var formBody: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.agBorder)
            ScrollView {
                VStack(spacing: 16) {
                    vinField
                    HStack(spacing: 12) {
                        yearPickerField
                        makePickerField
                    }
                    HStack(spacing: 12) {
                        modelPickerField
                        trimPickerField
                    }
                    bodyStylePickerField
                    mileageField
                    drivingProfileDivider
                    usageChips
                    conditionChips
                    annualMilesSegment
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            bottomCTA
        }
        .background(Color.agBackground)
        .interactiveDismissDisabled(!allowDismiss || addedVehicle != nil)
        .confirmationDialog("Discard vehicle?", isPresented: $showDiscardConfirm) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("Your progress won't be saved.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Add Vehicle")
                .font(Font.custom("Quicksand", size: 18).weight(.bold))
                .foregroundStyle(Color.agForeground)
            Spacer()
            if allowDismiss {
                Button {
                    if hasAnyInput { showDiscardConfirm = true } else { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.agMutedForeground)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color.agBackground)
    }

    private var hasAnyInput: Bool {
        selectedYear != nil || !selectedMake.isEmpty || !selectedModel.isEmpty ||
        !mileageInput.isEmpty || !vinInput.isEmpty
    }

    // MARK: - VIN

    private var vinField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("VIN", required: false)
            HStack(spacing: 8) {
                // Standard TextField so the system edit menu (Copy / Paste), Cmd+V and
                // simulator pasteboard sync all work. Pasted text is cleaned below:
                // spaces/dashes dropped, uppercased, capped at 17.
                TextField("17-character VIN (optional)", text: $vinInput)
                    .font(.quicksand(.regular, size: 14))
                    .foregroundStyle(Color.agForeground)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .submitLabel(.done)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: vinInput) { oldValue, newValue in
                        let capped = sanitizedVIN(newValue)
                        if capped != vinInput { vinInput = capped }
                        if capped.count == 17, sanitizedVIN(oldValue) != capped {
                            Task { await decodeVIN() }
                        }
                    }
                if lookupManager.isDecodingVIN {
                    ProgressView().frame(width: 16, height: 16)
                }
                #if DEBUG
                // Testing aid only — not shipped. In release builds users paste through
                // the standard iOS edit menu (long-press → Paste) on the TextField above.
                if !lookupManager.isDecodingVIN && vinInput.isEmpty {
                    PasteButton(payloadType: String.self) { strings in
                        guard let pasted = strings.first else { return }
                        Task { @MainActor in setVINInput(pasted) }
                    }
                    .labelStyle(.titleOnly)
                    .buttonBorderShape(.capsule)
                    .controlSize(.mini)
                    .tint(Color.agPrimary)
                }
                #endif
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(height: 41)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )

            if let error = lookupManager.vinError, !vinInput.isEmpty {
                Text(error)
                    .font(.quicksandScaled(.regular, size: 11))
                    .foregroundStyle(Color.agMutedForeground)
            }
        }
    }

    // MARK: - Year picker (native menu dropdown)

    private var yearPickerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Year", required: true)
            Menu {
                ForEach(VehicleDatabase.years, id: \.self) { year in
                    Button(String(year)) {
                        if selectedYear != year {
                            selectedYear = year
                            selectedMake = ""; selectedModel = ""; selectedTrim = ""; isTypingModel = false
                            lookupManager.makes = []; lookupManager.models = []; lookupManager.trims = []
                            Task { await lookupManager.loadMakes(year: year) }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedYear.map(String.init) ?? "Select")
                        .font(Font.custom("Quicksand", size: 14))
                        .foregroundStyle(selectedYear == nil ? Color.agMutedForeground : Color.agForeground)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.agMutedForeground)
                }
                .padding(.horizontal, 12)
                .frame(height: 41)
                .background(Color.agCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.agBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Make / Model / Trim menu pickers

    private var makePickerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Make", required: true)
            let disabled = selectedYear == nil
            let makes = lookupManager.makes.isEmpty ? VehicleDatabase.makes : lookupManager.makes
            Menu {
                if lookupManager.isLoadingMakes {
                    Label("Loading…", systemImage: "clock").disabled(true)
                } else {
                    ForEach(makes, id: \.self) { make in
                        Button(make) {
                            selectedMake = make
                            selectedModel = ""; selectedTrim = ""
                            isTypingModel = false
                            lookupManager.models = []; lookupManager.trims = []
                            if let y = selectedYear {
                                Task { await lookupManager.loadModels(make: make, year: y) }
                            }
                        }
                    }
                }
            } label: {
                menuLabel(selectedMake.isEmpty ? nil : selectedMake, disabled: disabled)
            }
            .disabled(disabled)
            .task(id: selectedYear) {
                if let y = selectedYear, lookupManager.makes.isEmpty {
                    await lookupManager.loadMakes(year: y)
                }
            }
        }
    }

    private var modelPickerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Model", required: true)
            let disabled = selectedMake.isEmpty
            let models = lookupManager.models.isEmpty
                ? (VehicleDatabase.models[selectedMake] ?? [])
                : lookupManager.models
            if isTypingModel {
                manualModelField
            } else {
                Menu {
                    if lookupManager.isLoadingModels {
                        Label("Loading…", systemImage: "clock").disabled(true)
                    } else {
                        if models.isEmpty {
                            Text("No models found for \(selectedMake)")
                        }
                        ForEach(models, id: \.self) { model in
                            Button(model) {
                                selectedModel = model
                                selectedTrim = ""
                                lookupManager.trims = []
                                if let y = selectedYear {
                                    Task { await lookupManager.loadTrims(make: selectedMake, model: model, year: y) }
                                }
                            }
                        }
                        Divider()
                        Button {
                            selectedModel = ""; selectedTrim = ""
                            isTypingModel = true
                        } label: {
                            Label("Not listed? Type it in", systemImage: "keyboard")
                        }
                    }
                } label: {
                    menuLabel(selectedModel.isEmpty ? nil : selectedModel, disabled: disabled)
                }
                .disabled(disabled)
            }
        }
        .task(id: selectedMake) {
            if !selectedMake.isEmpty, let y = selectedYear, lookupManager.models.isEmpty {
                await lookupManager.loadModels(make: selectedMake, year: y)
            }
        }
    }

    private var trimPickerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Trim", required: false)
            let disabled = selectedModel.isEmpty
            let trims = lookupManager.trims.isEmpty
                ? VehicleDatabase.trimsFor(make: selectedMake, model: selectedModel)
                : lookupManager.trims
            Menu {
                if lookupManager.isLoadingTrims {
                    Label("Loading…", systemImage: "clock").disabled(true)
                } else {
                    Button("Skip") { selectedTrim = "" }
                    ForEach(trims, id: \.self) { trim in
                        Button(trim) { selectedTrim = trim }
                    }
                }
            } label: {
                menuLabel(selectedTrim.isEmpty ? nil : selectedTrim, disabled: disabled)
            }
            .disabled(disabled)
            .task(id: selectedModel) {
                if !selectedModel.isEmpty, let y = selectedYear, lookupManager.trims.isEmpty {
                    await lookupManager.loadTrims(make: selectedMake, model: selectedModel, year: y)
                }
            }
        }
    }

    private var bodyStylePickerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Body Style", required: false)
            Menu {
                Button("Skip") { selectedBodyStyle = "" }
                ForEach(Vehicle.bodyStyleOptions, id: \.self) { style in
                    Button(style) { selectedBodyStyle = style }
                }
            } label: {
                menuLabel(selectedBodyStyle.isEmpty ? nil : selectedBodyStyle, disabled: false)
            }
        }
    }

    /// Free-text model entry for cars missing from the API / bundled lists.
    private var manualModelField: some View {
        HStack(spacing: 8) {
            TextField("Type your model", text: $selectedModel)
                .font(Font.custom("Quicksand", size: 14))
                .foregroundStyle(Color.agForeground)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    let model = selectedModel.trimmingCharacters(in: .whitespaces)
                    selectedModel = model
                    lookupManager.trims = []
                    if !model.isEmpty, let y = selectedYear {
                        Task { await lookupManager.loadTrims(make: selectedMake, model: model, year: y) }
                    }
                }
            Button {
                selectedModel = ""; selectedTrim = ""
                isTypingModel = false
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose model from list")
        }
        .padding(.horizontal, 12)
        .frame(height: 41)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.agBorder, lineWidth: 1)
        )
    }

    private func menuLabel(_ value: String?, disabled: Bool) -> some View {
        HStack {
            Text(value ?? "Select")
                .font(Font.custom("Quicksand", size: 14))
                .foregroundStyle(value == nil ? Color.agMutedForeground : Color.agForeground)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.agMutedForeground)
        }
        .padding(.horizontal, 12)
        .frame(height: 41)
        .background(disabled ? Color.agMuted.opacity(0.4) : Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(disabled ? Color.agBorder.opacity(0.5) : Color.agBorder, lineWidth: 1)
        )
    }

    // MARK: - Mileage

    private var mileageField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Current Mileage", required: true)
            HStack {
                TextField("e.g. 47,230", text: $mileageInput)
                    .font(Font.custom("Quicksand", size: 14))
                    .keyboardType(.numberPad)
                    .onChange(of: mileageInput) { _, newValue in
                        let digits = newValue.filter { $0.isNumber }
                        if let n = Int(digits) {
                            let formatted = n.formatted(.number.grouping(.automatic))
                            if mileageInput != formatted { mileageInput = formatted }
                        } else {
                            mileageInput = digits
                        }
                    }
                Text("mi")
                    .font(Font.custom("Quicksand", size: 12))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .padding(.horizontal, 12)
            .frame(height: 41)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Driving profile

    private var drivingProfileDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.agBorder).frame(height: 1)
            Text("Driving Profile")
                .font(Font.custom("Quicksand", size: 10))
                .tracking(0.5)
                .foregroundStyle(Color.agMutedForeground)
            Rectangle().fill(Color.agBorder).frame(height: 1)
        }
        .padding(.top, 4)
    }

    private var usageChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("How you use this car", required: true)
            ChipFlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(VehicleDatabase.usageOptions) { opt in
                    chip(label: opt.label, emoji: usageEmoji(opt.id),
                         selected: selectedUsage.contains(opt.id)) {
                        if selectedUsage.contains(opt.id) { selectedUsage.remove(opt.id) }
                        else { selectedUsage.insert(opt.id) }
                    }
                }
            }
        }
    }

    private var conditionChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Driving conditions", required: true)
            ChipFlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(VehicleDatabase.conditionOptions) { opt in
                    chip(label: opt.label, emoji: conditionEmoji(opt.id),
                         selected: selectedConditions.contains(opt.id)) {
                        if selectedConditions.contains(opt.id) { selectedConditions.remove(opt.id) }
                        else { selectedConditions.insert(opt.id) }
                    }
                }
            }
        }
    }

    private var annualMilesSegment: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Annual miles", required: true)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VehicleDatabase.annualMileageOptions) { opt in
                        let selected = selectedAnnualMileage == opt.id
                        Button {
                            selectedAnnualMileage = opt.id
                        } label: {
                            Text(opt.label)
                                .font(Font.custom("Quicksand", size: 12).weight(.medium))
                                .foregroundStyle(selected ? .white : Color.agForeground)
                                .padding(.horizontal, 14)
                                .frame(height: 33)
                                .background(selected ? Color.agPrimary : Color.agCard)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(selected ? Color.clear : Color.agPrimary.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Chip / Label helpers

    private func chip(label: String, emoji: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji).font(Font.custom("Quicksand", size: 14))
                Text(label)
                    .font(Font.custom("Quicksand", size: 12).weight(.medium))
                    .foregroundStyle(selected ? .white : Color.agForeground)
            }
            .padding(.horizontal, 14)
            .frame(height: 29)
            .background(selected ? Color.agPrimary : Color.agCard)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(selected ? Color.clear : Color.agPrimary.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func fieldLabel(_ text: String, required: Bool) -> some View {
        HStack(spacing: 0) {
            Text(text)
                .font(Font.custom("Quicksand", size: 12).weight(.bold))
                .foregroundStyle(Color.agForeground)
            if required {
                Text("*")
                    .font(Font.custom("Quicksand", size: 12).weight(.bold))
                    .foregroundStyle(Color.agPrimary)
            }
        }
    }

    // Usage/condition emoji lookup. Falls back to a neutral glyph when the
    // option doesn't have a dedicated emoji in its id.
    private func usageEmoji(_ id: String) -> String {
        switch id {
        case "commute", "daily-commute": return "🏢"
        case "weekend", "weekend-trips": return "🌄"
        case "family", "family-hauler": return "👨‍👩‍👧‍👦"
        case "road-trip", "road-trips": return "🗺️"
        case "performance", "performance-driving": return "🏁"
        case "work", "work-truck": return "🔧"
        case "rideshare": return "🚕"
        default: return "🚗"
        }
    }

    private func conditionEmoji(_ id: String) -> String {
        switch id {
        case "city", "city-traffic": return "🏙️"
        case "highway": return "🛣️"
        case "hills", "hills-mountains", "mountains": return "⛰️"
        case "dusty", "dusty-roads": return "🌫️"
        case "hot", "hot-climate": return "☀️"
        case "cold", "cold-snow", "snow": return "❄️"
        case "rain", "wet": return "🌧️"
        case "stop-go": return "🚦"
        default: return "📍"
        }
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        Button {
            saveVehicle()
        } label: {
            Text(primaryCTA)
                .font(Font.custom("Quicksand", size: 14).weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.theme.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.3)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.95))
        .overlay(
            Rectangle()
                .strokeBorder(Color.theme.surfaceAlt, lineWidth: 0.5)
        )
    }

    // MARK: - VIN + save

    private func sanitizedVIN(_ value: String) -> String {
        let cleaned = value.uppercased().filter { $0.isLetter || $0.isNumber }
        return String(cleaned.prefix(17))
    }

    /// Lookup is triggered by the VIN field's onChange once it reaches 17 characters.
    private func setVINInput(_ value: String) {
        vinInput = sanitizedVIN(value)
    }

    private func decodeVIN() async {
        await lookupManager.decodeVIN(vinInput)
        if let result = lookupManager.vinResult {
            selectedYear = result.year
            selectedMake = result.make
            selectedModel = result.model
            selectedTrim = result.trim ?? ""
            if let style = Vehicle.bodyStyle(fromNHTSA: result.bodyClass) { selectedBodyStyle = style }
        }
    }

    private func saveVehicle() {
        let usageLabels = VehicleDatabase.usageOptions
            .filter { selectedUsage.contains($0.id) }
            .map(\.label)
        let conditionLabels = VehicleDatabase.conditionOptions
            .filter { selectedConditions.contains($0.id) }
            .map(\.label)

        let vehicle = Vehicle(
            id: UUID(),
            year: selectedYear ?? 2024,
            make: selectedMake,
            model: selectedModel,
            trim: selectedTrim.isEmpty ? nil : selectedTrim,
            mileage: mileageValue,
            color: "Unknown",
            vin: vinInput.count == 17 ? vinInput : nil,
            healthScore: 100,
            lastService: nil,
            nextService: nil,
            maintenanceCurrent: 0,
            maintenanceTotal: 0,
            usage: usageLabels,
            conditions: conditionLabels,
            annualMileage: selectedAnnualMileage.isEmpty ? nil : selectedAnnualMileage,
            bodyStyle: selectedBodyStyle.isEmpty ? nil : selectedBodyStyle
        )
        appState.addVehicle(vehicle)
        if let userId = authState.currentUser?.id {
            Task { await SupabaseManager.upsertVehicle(vehicle, userId: userId) }
        }
        if onComplete != nil {
            AnalyticsService.shared.track(.onboardingVehicleAdded)
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            addedVehicle = vehicle
        }
    }
}

// MARK: - Simple flow layout for chip rows

private struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let rows = arrange(width: width, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * rowSpacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private struct Row {
        var items: [(view: LayoutSubview, size: CGSize)] = []
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width && !current.items.isEmpty {
                rows.append(current)
                current = Row()
                x = 0
            }
            current.items.append((sub, size))
            current.height = max(current.height, size.height)
            x += size.width + spacing
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}

#Preview {
    AddVehicleFlowView()
        .environment(AppState())
        .environment(AuthState())
}
