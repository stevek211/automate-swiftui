import SwiftUI
import PhotosUI

enum QuickLogStep: String {
    case choose, services, details, review
}

struct QuickLogView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var step: QuickLogStep = .choose
    @State private var selectedServices: [String] = []
    @State private var customService = ""
    @State private var date = Date.now
    @State private var dateText: String = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }()
    @State private var mileageText = ""
    /// Cost typed for each selected service, keyed by service name.
    @State private var serviceCostTexts: [String: String] = [:]
    @State private var shop = ""
    @State private var receiptPhoto: PhotosPickerItem?
    @State private var receiptImageData: Data?
    @State private var editingReview = false
    @State private var showDiscardConfirm = false
    /// The text field being edited, if any. While set, the bottom bar is hidden so it can't cover the field.
    @FocusState private var focusedField: QuickLogField?

    var vehicle: Vehicle? { appState.selectedVehicle }

    var progressSteps: [QuickLogStep] { [.services, .details, .review] }
    var progressIndex: Int { progressSteps.firstIndex(of: step) ?? -1 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    if step != .choose {
                        BackButton {
                            withAnimation(.spring(duration: 0.25)) {
                                switch step {
                                case .services: step = .choose
                                case .details: step = .services
                                case .review: step = .details
                                default: break
                                }
                            }
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }

                    Spacer()

                    Text("QUICK LOG")
                        .font(.quicksandScaled(.semibold, size: 12))
                        .foregroundStyle(Color.agMutedForeground)
                        .tracking(1)

                    Spacer()

                    Button {
                        if step == .choose { dismiss() }
                        else { showDiscardConfirm = true }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                            .frame(width: 36, height: 36)
                            .background(Color.agMuted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Progress dots
                if step != .choose {
                    HStack(spacing: 8) {
                        ForEach(Array(progressSteps.enumerated()), id: \.offset) { index, _ in
                            Capsule()
                                .fill(index <= progressIndex ? Color.agPrimary : Color.agMuted)
                                .frame(width: index <= progressIndex ? 32 : 16, height: 6)
                        }
                    }
                    .padding(.bottom, 16)
                    .animation(.spring(duration: 0.3), value: progressIndex)
                }

                // Content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            switch step {
                            case .choose: chooseView
                            case .services: servicesView
                            case .details: detailsView
                            case .review: reviewView
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
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

                // Bottom CTA — hidden while typing so the keyboard doesn't push it over the field
                if focusedField == nil {
                    bottomCTA
                }
            }
            .background(Color.agBackground)
            .navigationBarHidden(true)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                // Number pads have no return key, so give them a way to close the keyboard.
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField?.isNumberPad == true {
                        Spacer()
                        Button("Done") { focusedField = nil }
                            .font(.quicksandScaled(.semibold, size: 16))
                    }
                }
            }
            .onAppear {
                mileageText = vehicle.map { $0.mileage.formatted() } ?? ""
            }
        }
        .confirmationDialog("Discard changes?", isPresented: $showDiscardConfirm) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your service log hasn't been saved yet.")
        }
    }

    // MARK: - Choose Step

    var chooseView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Log Service")
                    .font(.quicksandScaled(.bold, size: 26))
                    .foregroundStyle(Color.agForeground)
                Text("How would you like to log it?")
                    .font(.quicksandScaled(.regular, size: 16))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .padding(.top, 16)

            // Upload receipt (placeholder — no AI processing yet)
            Button {
                // In future: camera/photo + AI extraction
                // For now, go straight to manual
                withAnimation(.spring(duration: 0.25)) { step = .services }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.agPrimary.opacity(0.1))
                            .frame(width: 52, height: 52)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.agPrimary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upload Receipt Photo")
                            .font(.quicksandScaled(.bold, size: 17))
                            .foregroundStyle(Color.agForeground)
                        Text("Coming soon — auto-extract services & cost")
                            .font(.quicksandScaled(.regular, size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    Spacer()
                }
                .padding(20)
                .background(Color.agPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.agPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Manual entry
            Button {
                withAnimation(.spring(duration: 0.25)) { step = .services }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.agMuted)
                            .frame(width: 52, height: 52)
                        Image(systemName: "pencil")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enter Manually")
                            .font(.quicksandScaled(.bold, size: 17))
                            .foregroundStyle(Color.agForeground)
                        Text("Select services and fill in details yourself")
                            .font(.quicksandScaled(.regular, size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    Spacer()
                }
                .padding(20)
                .background(Color.agCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.agBorder, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Services Step

    var servicesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 4) {
                Text("What Was Done?")
                    .font(.quicksandScaled(.bold, size: 18))
                    .foregroundStyle(Color.agForeground)
                Text("Select all services performed")
                    .font(.quicksandScaled(.regular, size: 14))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .frame(maxWidth: .infinity)

            // Service grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(VehicleDatabase.commonServices, id: \.self) { service in
                    let isSelected = selectedServices.contains(service)
                    Button {
                        if isSelected { selectedServices.removeAll { $0 == service } }
                        else { selectedServices.append(service) }
                    } label: {
                        HStack(spacing: 6) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(service)
                                .font(.quicksandScaled(.medium, size: 12))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? .white : Color.agForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(height: 40)
                        .background(isSelected ? Color.agPrimary : Color.agMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            // Custom service
            HStack(spacing: 8) {
                TextField("Other service...", text: $customService)
                    .font(.quicksandScaled(.regular, size: 14))
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Color.agCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.agBorder, lineWidth: 1)
                    )
                    .focused($focusedField, equals: .customService)
                    .id(QuickLogField.customService)
                    .onSubmit { addCustomService() }

                Button {
                    addCustomService()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.agPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(customService.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(customService.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            }

            // Selected summary
            if !selectedServices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SELECTED (\(selectedServices.count))")
                        .font(.quicksandScaled(.semibold, size: 11))
                        .foregroundStyle(Color.agMutedForeground)
                        .tracking(0.5)

                    FlowLayout(spacing: 6) {
                        ForEach(selectedServices, id: \.self) { service in
                            HStack(spacing: 4) {
                                Text(service)
                                    .font(.quicksandScaled(.medium, size: 12))
                                    .foregroundStyle(Color.agPrimary)
                                Button {
                                    selectedServices.removeAll { $0 == service }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(Color.agPrimary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.agPrimary.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(12)
                .background(Color.agCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.agBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Details Step

    var detailsView: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Fill In Details")
                    .font(.quicksandScaled(.bold, size: 18))
                    .foregroundStyle(Color.agForeground)
                Text("Add cost, shop, and mileage")
                    .font(.quicksandScaled(.regular, size: 14))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .frame(maxWidth: .infinity)

            detailField(label: "DATE") {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            costsCard

            detailField(label: "SHOP / LOCATION") {
                TextField("e.g. Jiffy Lube", text: $shop)
                    .font(.quicksandScaled(.medium, size: 16))
                    .focused($focusedField, equals: .shop)
                    .id(QuickLogField.shop)
            }

            detailField(label: "MILEAGE") {
                TextField(vehicle.map { $0.mileage.formatted() } ?? "0", text: $mileageText)
                    .font(.quicksandScaled(.medium, size: 16))
                    .keyboardType(.numberPad)
                    .onChange(of: mileageText) { _, newValue in
                        let formatted = formattedMileageInput(newValue)
                        if formatted != newValue { mileageText = formatted }
                    }
                    .focused($focusedField, equals: .mileage)
                    .id(QuickLogField.mileage)
            }

            // Receipt photo
            detailField(label: "RECEIPT PHOTO (OPTIONAL)") {
                PhotosPicker(selection: $receiptPhoto, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.agPrimary)
                        Text(receiptImageData != nil ? "Photo added" : "Add photo")
                            .font(.quicksandScaled(.medium, size: 14))
                            .foregroundStyle(receiptImageData != nil ? Color.agSuccess : Color.agPrimary)
                    }
                }
            }

        }
        .onChange(of: receiptPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    receiptImageData = data
                }
            }
        }
    }

    // MARK: - Costs

    /// A cost field for each selected service and their running total.
    /// "$ 0.00" stays grey until a cost is typed; the total is grey at $0.
    var costsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COST PER SERVICE")
                .font(.quicksandScaled(.semibold, size: 11))
                .foregroundStyle(Color.agMutedForeground)
                .tracking(0.5)

            ForEach(selectedServices, id: \.self) { service in
                HStack(spacing: 12) {
                    Text(service)
                        .font(.quicksandScaled(.medium, size: 14))
                        .foregroundStyle(Color.agForeground)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    serviceCostField(service)
                }
            }

            Rectangle()
                .fill(Color.agBorder)
                .frame(height: 1)

            HStack {
                Text("Total")
                    .font(.quicksandScaled(.semibold, size: 14))
                    .foregroundStyle(Color.agForeground)
                Spacer()
                Text("$\(formattedAmount(totalCost))")
                    .font(.quicksandScaled(.semibold, size: 16))
                    .monospacedDigit()
                    .foregroundStyle(totalCost > 0 ? Color.agForeground : Color.agMutedForeground)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: totalCost)
            }
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.agBorder, lineWidth: 1)
        )
    }

    func serviceCostField(_ service: String) -> some View {
        let text = Binding(
            get: { serviceCostTexts[service] ?? "" },
            set: { newValue in
                let formatted = formattedCostInput(newValue)
                serviceCostTexts[service] = formatted.isEmpty ? nil : formatted
            }
        )
        let hasValue = !(serviceCostTexts[service] ?? "").isEmpty
        return HStack(spacing: 4) {
            Text("$")
                .foregroundStyle(hasValue ? Color.agForeground : Color.agMutedForeground)
            TextField("", text: text, prompt: Text("0.00").foregroundStyle(Color.agMutedForeground))
                .foregroundStyle(Color.agForeground)
                .keyboardType(.decimalPad)
                .monospacedDigit()
                .focused($focusedField, equals: .serviceCost(service))
        }
        .font(.quicksandScaled(.medium, size: 15))
        .padding(.horizontal, 10)
        .frame(width: 112, height: 36)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.agBorder, lineWidth: 1)
        )
        .id(QuickLogField.serviceCost(service))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(service) cost")
    }

    // MARK: - Review Step

    var reviewView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Confirm & Save")
                    .font(.quicksandScaled(.bold, size: 18))
                    .foregroundStyle(Color.agForeground)
                Text("Everything look right?")
                    .font(.quicksandScaled(.regular, size: 14))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .frame(maxWidth: .infinity)

            // Summary card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("SERVICE DETAILS")
                        .font(.quicksandScaled(.bold, size: 11))
                        .foregroundStyle(Color.agMutedForeground)
                        .tracking(0.5)
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.2)) { step = .details }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                            Text("Edit")
                                .font(.quicksandScaled(.medium, size: 12))
                        }
                        .foregroundStyle(Color.agPrimary)
                    }
                    .buttonStyle(.plain)
                }

                // Service names can be long, so they get the full width
                // instead of the narrow label column the other rows use.
                ForEach(selectedServices, id: \.self) { service in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(service)
                            .font(.quicksandScaled(.regular, size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("$\(formattedAmount(cost(for: service)))")
                            .font(.quicksandScaled(.semibold, size: 14))
                            .foregroundStyle(Color.agForeground)
                            .monospacedDigit()
                    }
                }
                reviewRow("Total", "$\(formattedAmount(totalCost))")
                    .padding(.bottom, 4)
                reviewRow("Date", formattedDate)
                reviewRow("Shop", shop.isEmpty ? "—" : shop)
                reviewRow("Mileage", "\((Int(mileageText.filter(\.isNumber)) ?? vehicle?.mileage ?? 0).formatted()) mi")
            }
            .padding(16)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )

            Text("Tap Edit to fix any incorrect info")
                .font(.quicksandScaled(.regular, size: 12))
                .foregroundStyle(Color.agMutedForeground)
        }
    }

    // MARK: - Bottom CTA

    var bottomCTA: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 12) {
                switch step {
                case .choose:
                    EmptyView()
                case .services:
                    Button {
                        withAnimation(.spring(duration: 0.25)) { step = .details }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Continue")
                                .font(.quicksandScaled(.semibold, size: 14))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.agPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(selectedServices.isEmpty)
                    .opacity(selectedServices.isEmpty ? 0.4 : 1)

                case .details:
                    Button {
                        withAnimation(.spring(duration: 0.25)) { step = .review }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Review")
                                .font(.quicksandScaled(.semibold, size: 14))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.agPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())

                case .review:
                    Button {
                        saveLog()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                            Text("Save to Service History")
                                .font(.quicksandScaled(.semibold, size: 14))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.agPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.agPrimary.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // Vehicle context
                if let vehicle, step != .choose {
                    Text("Logging for **\(vehicle.displayName)**")
                        .font(.quicksandScaled(.regular, size: 11))
                        .foregroundStyle(Color.agMutedForeground)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.agBackground.opacity(0.95))
    }

    // MARK: - Helpers

    @ViewBuilder
    func detailField(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.quicksandScaled(.semibold, size: 11))
                .foregroundStyle(Color.agMutedForeground)
                .tracking(0.5)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color.agCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.agBorder, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.agBorder, lineWidth: 1)
        )
    }

    func reviewRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.quicksandScaled(.regular, size: 14))
                .foregroundStyle(Color.agMutedForeground)
                .frame(width: 70, alignment: .leading)
            Spacer()
            Text(value)
                .font(.quicksandScaled(.semibold, size: 14))
                .foregroundStyle(Color.agForeground)
                .multilineTextAlignment(.trailing)
        }
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    func addCustomService() {
        let trimmed = customService.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedServices.contains(trimmed) else { return }
        selectedServices.append(trimmed)
        customService = ""
    }

    /// Saves one log per selected service, each with its own cost, so the
    /// Cost section lists them as separate lines under one visit (same day
    /// and shop) whose total is their sum.
    func saveLog() {
        guard let vehicleId = appState.selectedVehicleId else { return }
        let logMileage = Int(mileageText.filter(\.isNumber)) ?? vehicle?.mileage ?? 0
        let trimmedShop = shop.trimmingCharacters(in: .whitespaces)
        for service in selectedServices {
            appState.addServiceLog(ServiceLog(
                id: UUID(),
                vehicleId: vehicleId,
                name: service,
                date: date,
                mileage: logMileage,
                cost: cost(for: service),
                shop: trimmedShop.isEmpty ? nil : trimmedShop,
                notes: nil,
                category: .inferred(from: service)
            ))
        }

        // Update vehicle mileage if higher
        if logMileage > (vehicle?.mileage ?? 0) {
            appState.updateMileage(logMileage)
        }

        dismiss()
    }

    func cost(for service: String) -> Double {
        serviceCostTexts[service].flatMap(parsedCostInput) ?? 0
    }

    /// Sum of the selected services' costs; removed services drop out.
    var totalCost: Double {
        selectedServices.reduce(0) { $0 + cost(for: $1) }
    }

    func formattedAmount(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

}

#Preview {
    QuickLogView()
        .environment(AppState())
}

private enum QuickLogField: Hashable {
    case customService, shop, mileage
    case serviceCost(String)

    /// Number and decimal pads have no return key and need a Done button.
    var isNumberPad: Bool {
        switch self {
        case .mileage, .serviceCost: return true
        case .customService, .shop: return false
        }
    }
}
