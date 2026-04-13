import SwiftUI

struct AddVehicleFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    @State private var expandedSection: String? = "year"

    // Step 1 data
    @State private var selectedYear: Int? = nil
    @State private var selectedMake = ""
    @State private var selectedModel = ""
    @State private var selectedTrim = ""
    @State private var mileageInput = ""
    @State private var selectedColor = ""
    @State private var searchMake = ""
    @State private var searchModel = ""
    @State private var searchTrim = ""
    @State private var vinInput = ""
    @State private var lookupManager = VehicleLookupManager()

    // Step 2 data
    @State private var selectedUsage: Set<String> = []
    @State private var selectedConditions: Set<String> = []
    @State private var selectedAnnualMileage = ""

    @State private var showDiscardConfirm = false
    @State private var addedVehicle: Vehicle? = nil

    var mileageValue: Int { Int(mileageInput.replacingOccurrences(of: ",", with: "")) ?? 0 }

    var canProceedStep1: Bool {
        selectedYear != nil && !selectedMake.isEmpty && !selectedModel.isEmpty && mileageValue > 0
    }

    var canSubmit: Bool {
        !selectedUsage.isEmpty && !selectedConditions.isEmpty && !selectedAnnualMileage.isEmpty
    }

    var stepLabel: String {
        if let year = selectedYear, !selectedMake.isEmpty, !selectedModel.isEmpty {
            return "\(year) \(selectedMake) \(selectedModel)"
        }
        return "Your Car"
    }

    var body: some View {
        if let vehicle = addedVehicle {
            PostVehicleServiceSetupFlow(vehicle: vehicle) {
                dismiss()
            }
            .transition(.move(edge: .trailing))
        } else {
            addVehicleBody
        }
    }

    var addVehicleBody: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with step indicator
                VStack(spacing: 12) {
                    HStack {
                        if step == 2 {
                            Button {
                                withAnimation(.spring(duration: 0.2)) { step = 1 }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 14))
                                    Text("Back")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundStyle(Color.agMutedForeground)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        Text(step == 1 ? "Your Car" : "How You Drive")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.agForeground)
                        Spacer()
                        Button {
                            if step == 1 && selectedMake.isEmpty {
                                dismiss()
                            } else {
                                showDiscardConfirm = true
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.agMutedForeground)
                                .frame(width: 32, height: 32)
                                .background(Color.agMuted)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Progress bar
                    HStack(spacing: 8) {
                        Capsule()
                            .fill(Color.agPrimary)
                            .frame(height: 4)
                        Capsule()
                            .fill(step >= 2 ? Color.agPrimary : Color.agMuted)
                            .frame(height: 4)
                    }

                    if step == 2 {
                        Text(stepLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(Color.agBackground)

                Divider()

                // Content
                if step == 1 {
                    stepOneContent
                } else {
                    stepTwoContent
                }

                // Bottom CTA
                VStack(spacing: 0) {
                    Divider()
                    if step == 1 {
                        Button {
                            withAnimation(.spring(duration: 0.2)) { step = 2 }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Continue")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.agPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(!canProceedStep1)
                        .opacity(canProceedStep1 ? 1 : 0.3)
                    } else {
                        Button {
                            saveVehicle()
                        } label: {
                            Text("Add Vehicle")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.agPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(!canSubmit)
                        .opacity(canSubmit ? 1 : 0.3)
                    }
                }
                .padding(16)
                .background(Color.agBackground.opacity(0.95))
            }
            .background(Color.agBackground)
            .navigationBarHidden(true)
        }
        .confirmationDialog("Discard vehicle?", isPresented: $showDiscardConfirm) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("Your progress won't be saved.")
        }
    }

    // MARK: - Step 1: Your Car

    var stepOneContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // VIN Lookup Card
                vinLookupCard
                    .padding(.vertical, 12)

                sectionDivider

                // Year
                accordionSection(
                    id: "year",
                    title: "Year",
                    value: selectedYear.map(String.init)
                ) {
                    VStack(spacing: 8) {
                        Picker("Year", selection: Binding(
                            get: { selectedYear ?? 2024 },
                            set: { selectedYear = $0 }
                        )) {
                            ForEach(VehicleDatabase.years, id: \.self) { y in
                                Text(String(y)).tag(y)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .clipped()

                        Button {
                            if selectedYear == nil { selectedYear = 2024 }
                            withAnimation(.spring(duration: 0.2)) { expandedSection = "make" }
                            Task { await lookupManager.loadMakes(year: selectedYear) }
                        } label: {
                            Text("Select \(selectedYear ?? 2024)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.agPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }

                sectionDivider

                // Make
                accordionSection(
                    id: "make",
                    title: "Make",
                    value: selectedMake.isEmpty ? nil : selectedMake
                ) {
                    VStack(spacing: 8) {
                        searchField("Search makes...", text: $searchMake)

                        if lookupManager.isLoadingMakes {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            let makesList = lookupManager.makes.isEmpty ? VehicleDatabase.makes : lookupManager.makes
                            let filtered = makesList.filter {
                                searchMake.isEmpty || $0.localizedCaseInsensitiveContains(searchMake)
                            }
                            ScrollView {
                                VStack(spacing: 4) {
                                    ForEach(filtered, id: \.self) { make in
                                        optionButton(make, selected: selectedMake == make) {
                                            selectedMake = make
                                            selectedModel = ""
                                            selectedTrim = ""
                                            searchMake = ""
                                            withAnimation(.spring(duration: 0.2)) { expandedSection = "model" }
                                            if let year = selectedYear {
                                                Task { await lookupManager.loadModels(make: make, year: year) }
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 180)
                        }
                    }
                }

                sectionDivider

                // Model
                accordionSection(
                    id: "model",
                    title: "Model",
                    value: selectedModel.isEmpty ? nil : selectedModel
                ) {
                    if selectedMake.isEmpty {
                        Text("Select a make first")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 8) {
                            searchField("Search models...", text: $searchModel)

                            if lookupManager.isLoadingModels {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                            } else {
                                let modelsList = lookupManager.models.isEmpty ? (VehicleDatabase.models[selectedMake] ?? []) : lookupManager.models
                                let filtered = modelsList.filter {
                                    searchModel.isEmpty || $0.localizedCaseInsensitiveContains(searchModel)
                                }
                                ScrollView {
                                    VStack(spacing: 4) {
                                        ForEach(filtered, id: \.self) { model in
                                            optionButton(model, selected: selectedModel == model) {
                                                selectedModel = model
                                                selectedTrim = ""
                                                searchModel = ""
                                                withAnimation(.spring(duration: 0.2)) { expandedSection = "trim" }
                                                if let year = selectedYear {
                                                    Task { await lookupManager.loadTrims(make: selectedMake, model: model, year: year) }
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(maxHeight: 180)
                            }
                        }
                    }
                }

                sectionDivider

                // Trim
                accordionSection(
                    id: "trim",
                    title: "Trim",
                    value: selectedTrim.isEmpty ? nil : selectedTrim
                ) {
                    if selectedModel.isEmpty {
                        Text("Select a model first")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                            .padding(.vertical, 8)
                    } else if lookupManager.isLoadingTrims {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        let trimsList = lookupManager.trims.isEmpty ? VehicleDatabase.trimsFor(make: selectedMake, model: selectedModel) : lookupManager.trims
                        VStack(spacing: 8) {
                            if trimsList.count > 8 {
                                searchField("Search trims...", text: $searchTrim)
                            }

                            let filtered = trimsList.filter {
                                searchTrim.isEmpty || $0.localizedCaseInsensitiveContains(searchTrim)
                            }
                            ScrollView {
                                VStack(spacing: 4) {
                                    ForEach(filtered, id: \.self) { trim in
                                        optionButton(trim, selected: selectedTrim == trim) {
                                            selectedTrim = trim
                                            searchTrim = ""
                                            withAnimation(.spring(duration: 0.2)) { expandedSection = "mileage" }
                                        }
                                    }
                                    Button {
                                        selectedTrim = ""
                                        searchTrim = ""
                                        withAnimation(.spring(duration: 0.2)) { expandedSection = "mileage" }
                                    } label: {
                                        Text("Skip")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.agMutedForeground)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .frame(maxHeight: 180)
                        }
                    }
                }

                sectionDivider

                // Mileage
                accordionSection(
                    id: "mileage",
                    title: "Mileage",
                    value: mileageValue > 0 ? "\(mileageValue.formatted()) mi" : nil
                ) {
                    VStack(spacing: 8) {
                        TextField("e.g. 47,230", text: $mileageInput)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color.agCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.agBorder, lineWidth: 1)
                            )

                        Text("Check your odometer for the exact number")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }

                sectionDivider

                // Color (optional)
                accordionSection(
                    id: "color",
                    title: "Color (optional)",
                    value: selectedColor.isEmpty ? nil : selectedColor
                ) {
                    VStack(spacing: 8) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(VehicleDatabase.commonColors, id: \.self) { color in
                                optionButton(color, selected: selectedColor == color) {
                                    selectedColor = color
                                }
                            }
                        }

                        TextField("Or enter custom color", text: Binding(
                            get: { VehicleDatabase.commonColors.contains(selectedColor) ? "" : selectedColor },
                            set: { selectedColor = $0 }
                        ))
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.agCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.agBorder, lineWidth: 1)
                        )

                        Button {
                            selectedColor = ""
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.agMutedForeground)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Step 2: How You Drive

    var stepTwoContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Context card
                VStack(alignment: .leading, spacing: 4) {
                    Text("Almost there!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.agForeground)
                    Text("This helps us personalize your maintenance schedule. Cars driven in stop-and-go traffic need different care than highway cruisers.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agMutedForeground)
                }
                .padding(16)
                .background(Color.agPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.agPrimary.opacity(0.1), lineWidth: 1)
                )

                // Usage
                VStack(alignment: .leading, spacing: 8) {
                    Text("How do you use this car?")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.agForeground)
                    Text("Select all that apply")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agMutedForeground)

                    VStack(spacing: 6) {
                        ForEach(VehicleDatabase.usageOptions) { opt in
                            let selected = selectedUsage.contains(opt.id)
                            Button {
                                if selected { selectedUsage.remove(opt.id) }
                                else { selectedUsage.insert(opt.id) }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: opt.emoji)
                                        .font(.system(size: 18))
                                        .foregroundStyle(selected ? Color.agPrimary : Color.agMutedForeground)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(opt.label)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.agForeground)
                                        Text(opt.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.agMutedForeground)
                                    }
                                    Spacer()
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.agPrimary)
                                    }
                                }
                                .padding(12)
                                .background(selected ? Color.agPrimary.opacity(0.1) : Color.agMuted.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(selected ? Color.agPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }

                // Conditions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Driving conditions")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.agForeground)
                    Text("Select all that apply")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agMutedForeground)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(VehicleDatabase.conditionOptions) { opt in
                            let selected = selectedConditions.contains(opt.id)
                            Button {
                                if selected { selectedConditions.remove(opt.id) }
                                else { selectedConditions.insert(opt.id) }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: opt.emoji)
                                        .font(.system(size: 20))
                                        .foregroundStyle(selected ? Color.agPrimary : Color.agMutedForeground)
                                    Text(opt.label)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.agForeground)
                                        .multilineTextAlignment(.center)
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(Color.agPrimary)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(selected ? Color.agPrimary.opacity(0.1) : Color.agMuted.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(selected ? Color.agPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }

                // Annual Mileage
                VStack(alignment: .leading, spacing: 8) {
                    Text("Annual miles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.agForeground)

                    VStack(spacing: 6) {
                        ForEach(VehicleDatabase.annualMileageOptions) { opt in
                            let selected = selectedAnnualMileage == opt.id
                            Button {
                                selectedAnnualMileage = opt.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(opt.label)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.agForeground)
                                        Text(opt.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.agMutedForeground)
                                    }
                                    Spacer()
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.agPrimary)
                                    }
                                }
                                .padding(12)
                                .background(selected ? Color.agPrimary.opacity(0.1) : Color.agMuted.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(selected ? Color.agPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    func accordionSection(id: String, title: String, value: String?, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.2)) {
                    expandedSection = expandedSection == id ? nil : id
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.agForeground)
                    Spacer()
                    HStack(spacing: 6) {
                        if let value {
                            Text(value)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.agPrimary)
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                            .rotationEffect(.degrees(expandedSection == id ? 180 : 0))
                    }
                }
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expandedSection == id {
                content()
                    .padding(.bottom, 16)
            }
        }
    }

    var sectionDivider: some View {
        Rectangle()
            .fill(Color.agBorder)
            .frame(height: 1)
    }

    // MARK: - VIN Lookup Card

    var vinLookupCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.agPrimary)
                Text("Have your VIN?")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.agForeground)
            }

            Text("Enter your 17-character VIN to auto-fill your vehicle details.")
                .font(.system(size: 12))
                .foregroundStyle(Color.agMutedForeground)

            HStack(spacing: 8) {
                TextField("e.g. 1HGCV1F34LA000001", text: $vinInput)
                    .font(.system(size: 14, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: vinInput) { _, newValue in
                        vinInput = String(newValue.prefix(17)).uppercased()
                        if vinInput.count == 17 {
                            Task { await decodeVIN() }
                        }
                    }

                if lookupManager.isDecodingVIN {
                    ProgressView()
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )

            if let success = lookupManager.vinSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agSuccess)
                    Text(success)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.agSuccess)
                }
            }

            if let error = lookupManager.vinError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agWarning)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agMutedForeground)
                }
            }
        }
        .padding(16)
        .background(Color.agPrimary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.agPrimary.opacity(0.15), lineWidth: 1)
        )
    }

    private func decodeVIN() async {
        await lookupManager.decodeVIN(vinInput)
        if let result = lookupManager.vinResult {
            selectedYear = result.year
            selectedMake = result.make
            selectedModel = result.model
            selectedTrim = result.trim ?? ""
            withAnimation(.spring(duration: 0.2)) { expandedSection = "mileage" }
        }
    }

    private func searchField(_ placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(Color.agMutedForeground)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.agBorder, lineWidth: 1)
        )
    }

    func optionButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(selected ? .white : Color.agForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(selected ? Color.agPrimary : Color.agMuted.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    func saveVehicle() {
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
            color: selectedColor.isEmpty ? "Unknown" : selectedColor,
            vin: vinInput.count == 17 ? vinInput : nil,
            healthScore: 100,
            lastService: nil,
            nextService: nil,
            maintenanceCurrent: 0,
            maintenanceTotal: 0,
            usage: usageLabels,
            conditions: conditionLabels,
            annualMileage: selectedAnnualMileage.isEmpty ? nil : selectedAnnualMileage
        )
        appState.addVehicle(vehicle)
        print("🚗 [AddVehicle] Vehicle saved: \(vehicle.displayName) — transitioning to service setup")
        withAnimation(.easeInOut(duration: 0.35)) {
            addedVehicle = vehicle
        }
    }
}

#Preview {
    AddVehicleFlowView()
        .environment(AppState())
}
