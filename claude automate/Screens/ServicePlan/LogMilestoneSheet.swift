import SwiftUI

// MARK: - Inspection State

enum InspectionState: CaseIterable, Equatable {
    case notChecked, allGood, needsAttention

    var label: String {
        switch self {
        case .notChecked:    return "Not checked"
        case .allGood:       return "Checked — all good"
        case .needsAttention: return "Checked — needs attention"
        }
    }
}

private struct PendingServiceItemRemoval: Identifiable, Equatable {
    enum Source: Equatable {
        case milestone(UUID)
        case custom(String)
    }

    let id = UUID()
    let name: String
    let source: Source
}

// MARK: - Log Milestone Sheet

struct LogMilestoneSheet: View {
    let milestone: ServicePlanMilestone
    let vehicle: Vehicle
    var onSave: (ServiceLog, [String]) -> Void = { _, _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var shop: String = ""
    @State private var costText: String = ""
    @State private var serviceMileageText: String
    @State private var inspectionStates: [UUID: InspectionState] = [:]
    @State private var removedItemIDs: Set<UUID> = []
    @State private var customItems: [String] = []
    @State private var showAddItem = false
    @State private var newItemDraft = ""
    @State private var pendingRemoval: PendingServiceItemRemoval?
    /// The field being edited. While set, the Save bar hides and the field is scrolled above the keyboard.
    @FocusState private var focusedField: LogSheetField?

    init(
        milestone: ServicePlanMilestone,
        vehicle: Vehicle,
        onSave: @escaping (ServiceLog, [String]) -> Void = { _, _ in }
    ) {
        self.milestone = milestone
        self.vehicle = vehicle
        self.onSave = onSave
        self._serviceMileageText = State(initialValue: "")
    }

    var body: some View {
        ZStack {
            editContent

            if let pendingRemoval {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .transition(.opacity)

                removeConfirmationPopup(pendingRemoval)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: pendingRemoval)
        .onAppear {
            for item in milestone.inspections {
                inspectionStates[item.id] = .notChecked
            }
        }
    }

    private var editContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            dragHandle
            header
            ScrollViewReader { proxy in
                ScrollView {
                    formContent
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focusedField) { _, field in
                    guard let field else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(field, anchor: .center)
                        }
                    }
                }
            }
            // Hidden while typing so the keyboard doesn't push it over the field.
            if focusedField == nil {
                saveArea
            }
        }
        .background(.white)
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        HStack {
            Capsule()
                .fill(Color.theme.borderStrong)
                .frame(width: 40, height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("LOG SERVICE")
                    .font(.quicksand(.medium, size: 12)) //log service font size
                    .tracking(2.00)
                    .foregroundStyle(Color.theme.mutedText)
                Text("\(milestone.mileage.formatted()) mi service")
                    .font(.quicksand(.medium, size: 22))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ServicePlanPalette.textMuted)
                    .frame(width: 32, height: 32)
                    .background(ServicePlanPalette.neutralChipBg)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ServicePlanPalette.borderLight)
                .frame(height: 0.75)
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 20) {

            // DATE + SERVICE MILEAGE
            HStack(alignment: .top, spacing: 16) {
                underlineField(label: "DATE") {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(ServicePlanPalette.teal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                underlineField(label: "SERVICE MILEAGE *") { //
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("", text: $serviceMileageText)
                            .onChange(of: serviceMileageText) { _, newValue in
                                let digits = newValue.filter(\.isNumber)
                                let formatted = formatMileageInput(digits)
                                if formatted != newValue {
                                    serviceMileageText = formatted
                                }
                            }
                            .font(.quicksand(.regular, size: 17))
                            .foregroundStyle(ServicePlanPalette.textPrimary)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .monospacedDigit()
                            .focused($focusedField, equals: .mileage)
                            .id(LogSheetField.mileage)

                        Text("mi")
                            .font(.quicksand(.regular, size: 15))
                            .foregroundStyle(Color.theme.mutedText)
                    }
                }
            }

            // SHOP text 
            underlineField(label: "SHOP") {
                TextField("e.g. Jiffy Lube", text: $shop)
                    .font(.quicksand(.regular, size: 17))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                    .focused($focusedField, equals: .shop)
                    .id(LogSheetField.shop)
            }
            .frame(maxWidth: .infinity)

            // TOTAL COST
            underlineField(label: "TOTAL COST") {
                HStack(spacing: 4) {
                    Text("$")
                        .font(.quicksand(.regular, size: 17))
                        .foregroundStyle(ServicePlanPalette.textPrimary)
                    TextField("0.00", text: $costText)
                        .focused($focusedField, equals: .cost)
                        .id(LogSheetField.cost)
                        .onChange(of: costText) { _, newValue in
                            let filtered = sanitizedCostInput(newValue)
                            if filtered != newValue {
                                costText = filtered
                            }
                        }
                        .font(.quicksand(.regular, size: 17))
                        .foregroundStyle(ServicePlanPalette.textPrimary)
                        .keyboardType(.decimalPad)
                }
            }
            .frame(maxWidth: .infinity)

            // WHAT WAS DONE
            whatWasDoneSection
        }
    }

    // MARK: - What Was Done

    private var whatWasDoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WHAT WAS DONE")
                .font(.quicksand(.semibold, size: 13))
                .tracking(1.76)
                .foregroundStyle(Color.theme.mutedText)

            if !visibleReplacements.isEmpty {
                replacementsSection
            }

            if !visibleInspections.isEmpty {
                inspectionsSection
            }

            // Custom items
            ForEach(customItems, id: \.self) { item in
                HStack(spacing: 12) {
                    ZStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 20, height: 20)
                    .background(ServicePlanPalette.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(item)
                        .font(.quicksand(.regular, size: 14))
                        .foregroundStyle(ServicePlanPalette.textPrimary)

                    Spacer()

                    removeButton {
                        pendingRemoval = PendingServiceItemRemoval(
                            name: item,
                            source: .custom(item)
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            // Add another item
            addAnotherItemRow
        }
    }

    // MARK: - Replacements

    private var replacementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REPLACEMENTS")
                .font(.quicksand(.medium, size: 12))
                .tracking(1.60)
                .foregroundStyle(ServicePlanPalette.dotColor)

            ForEach(visibleReplacements) { item in
                HStack(spacing: 12) {
                    // Always-checked dark square
                    ZStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 20, height: 20)
                    .background(ServicePlanPalette.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(item.name)
                        .font(.quicksand(.regular, size: 14))
                        .foregroundStyle(ServicePlanPalette.textPrimary)

                    Spacer()

                    Text(item.action.displayText)
                        .font(.quicksand(.regular, size: 12))
                        .tracking(0.50)
                        .foregroundStyle(ServicePlanPalette.dotColor)

                    removeButton {
                        pendingRemoval = PendingServiceItemRemoval(
                            name: item.name,
                            source: .milestone(item.id)
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Inspections

    private var inspectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INSPECTIONS")
                .font(.quicksand(.medium, size: 12))
                .tracking(1.60)
                .foregroundStyle(ServicePlanPalette.dotColor)

            ForEach(visibleInspections) { item in
                VStack(alignment: .leading, spacing: 10) {
                    // Item name + action label
                    HStack {
                        Text(item.name)
                            .font(.quicksand(.medium, size: 14))
                            .foregroundStyle(ServicePlanPalette.textPrimary)
                        Spacer()
                        Text(item.action.displayText)
                            .font(.quicksand(.regular, size: 12))
                            .tracking(0.50)
                            .foregroundStyle(ServicePlanPalette.dotColor)
                        removeButton {
                            pendingRemoval = PendingServiceItemRemoval(
                                name: item.name,
                                source: .milestone(item.id)
                            )
                        }
                    }

                    // 3-state radio
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(InspectionState.allCases, id: \.label) { option in
                            let selected = (inspectionStates[item.id] ?? .notChecked) == option
                            Button {
                                inspectionStates[item.id] = option
                            } label: {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(ServicePlanPalette.dotColor, lineWidth: 0.75)
                                            .frame(width: 16, height: 16)
                                        if selected {
                                            Circle()
                                                .fill(ServicePlanPalette.textPrimary)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    Text(option.label)
                                        .font(.quicksand(.medium, size: 14))
                                        .foregroundStyle(ServicePlanPalette.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        }
    }

    // MARK: - Add Another Item

    private var addAnotherItemRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showAddItem.toggle() }
                // Opening the row puts the cursor straight in the name field.
                focusedField = showAddItem ? .newItem : nil
            } label: {
                HStack {
                    Text("Add another item")
                        .font(.quicksand(.medium, size: 14))
                        .foregroundStyle(ServicePlanPalette.dotColor)
                    Spacer()
                    Image(systemName: showAddItem ? "minus" : "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ServicePlanPalette.dotColor)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showAddItem {
                HStack(spacing: 12) {
                    TextField("Service item name", text: $newItemDraft)
                        .font(.quicksand(.regular, size: 14))
                        .foregroundStyle(ServicePlanPalette.textPrimary)
                        .focused($focusedField, equals: .newItem)
                        .submitLabel(.done)
                        .onSubmit { addCustomItem() }

                    Button {
                        addCustomItem()
                    } label: {
                        Text("Add")
                            .font(.quicksand(.semibold, size: 12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(ServicePlanPalette.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 12)
                .id(LogSheetField.newItem)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .overlay(alignment: .top) {
            Rectangle().fill(ServicePlanPalette.borderLight).frame(height: 0.75)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(ServicePlanPalette.borderLight).frame(height: 0.75)
        }
    }

    private func addCustomItem() {
        let trimmed = newItemDraft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        customItems.append(trimmed)
        newItemDraft = ""
        showAddItem = false
        focusedField = nil
    }

    // MARK: - Save Area

    private var saveArea: some View {
        VStack {
            Button { save() } label: {
                Text("Save")
                    .font(.quicksand(.semibold, size: 14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(canSave ? ServicePlanPalette.textPrimary : ServicePlanPalette.dotColor.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ServicePlanPalette.borderLight)
                .frame(height: 0.75)
        }
    }

    // MARK: - Underline Field Helper

    @ViewBuilder
    private func underlineField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.quicksand(.medium, size: 10))
                .tracking(1.80)
                .foregroundStyle(Color.theme.mutedText)
            content()
                .frame(height: 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.theme.borderStrong)
                        .frame(height: 0.75)
                }
        }
    }

    private func removeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "trash")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ServicePlanPalette.dotColor)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove service item")
    }

    private func removeConfirmationPopup(_ removal: PendingServiceItemRemoval) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Remove Item?")
                .font(.quicksand(.semibold, size: 18))
                .foregroundStyle(ServicePlanPalette.textPrimary)
                .lineLimit(1)
                .frame(width: 314.11, height: 28, alignment: .leading)
                .padding(.bottom, 14)

            Text("Are you sure you want to remove \"\(removal.name)\" from your service?")
                .font(.quicksand(.regular, size: 14))
                .foregroundStyle(ServicePlanPalette.textSecondary)
                .lineSpacing(0)
                .frame(width: 314.11, alignment: .leading)
                .frame(minHeight: 40, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 24)

            HStack(alignment: .top, spacing: 12) {
                Button {
                    pendingRemoval = nil
                } label: {
                    Text("Cancel")
                        .font(.quicksand(.semibold, size: 14))
                        .foregroundStyle(ServicePlanPalette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42.99)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .inset(by: 0.75)
                                .stroke(Color.theme.borderStrong, lineWidth: 0.75)
                        }
                }
                .buttonStyle(.plain)

                Button {
                    confirmRemoval(removal)
                } label: {
                    Text("Remove")
                        .font(.quicksand(.semibold, size: 14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42.99)
                        .background(Color.theme.danger)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .frame(width: 314.11, height: 42.99)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(width: 362.11, alignment: .topLeading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.25), radius: 50, x: 0, y: 25)
    }

    private func confirmRemoval(_ removal: PendingServiceItemRemoval) {
        switch removal.source {
        case .milestone(let id):
            removedItemIDs.insert(id)
        case .custom(let name):
            customItems.removeAll { $0 == name }
        }
        pendingRemoval = nil
    }

    // MARK: - Save Action

    private func save() {
        guard let serviceMileage = parsedServiceMileage else { return }
        let cost = Double(costText
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespaces)) ?? 0
        let log = ServiceLog(
            id: UUID(),
            vehicleId: vehicle.id,
            name: "\(milestone.mileage.formatted()) mi service",
            date: selectedDate,
            mileage: serviceMileage,
            cost: cost,
            shop: shop.isEmpty ? nil : shop,
            notes: nil,
            category: .general
        )
        onSave(log, completedItemNames)
        dismiss()
    }

    private var completedItemNames: [String] {
        let milestoneItems = visibleReplacements.map(\.name) + visibleInspections.map(\.name)
        return milestoneItems + customItems
    }

    private var visibleReplacements: [ServicePlanItem] {
        milestone.replacements.filter { !removedItemIDs.contains($0.id) }
    }

    private var visibleInspections: [ServicePlanItem] {
        milestone.inspections.filter { !removedItemIDs.contains($0.id) }
    }

    private var parsedServiceMileage: Int? {
        let digits = serviceMileageText.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }

    private func sanitizedCostInput(_ value: String) -> String {
        var result = ""
        var hasDecimal = false
        var decimalPlaces = 0

        for character in value {
            if character.isNumber {
                if hasDecimal {
                    guard decimalPlaces < 2 else { continue }
                    decimalPlaces += 1
                }
                result.append(character)
            } else if character == ".", !hasDecimal {
                hasDecimal = true
                result.append(character)
            }
        }

        return result
    }

    private func formatMileageInput(_ digits: String) -> String {
        guard let value = Int(digits), !digits.isEmpty else { return "" }
        return value.formatted()
    }

    private var canSave: Bool {
        parsedServiceMileage != nil
    }
}

// MARK: - Preview

#Preview("Log Milestone Sheet") {
    let vehicle = Vehicle(
        id: UUID(),
        year: 2024,
        make: "Audi",
        model: "A4",
        trim: "Premium",
        mileage: 32_500,
        color: "Glacier White",
        vin: nil,
        healthScore: 88,
        lastService: nil,
        nextService: nil,
        maintenanceCurrent: 0,
        maintenanceTotal: 0,
        usage: [],
        conditions: []
    )
    let milestone = ServicePlanBuilder.build(
        items: ServicePlanBuilder.demoItems,
        currentMileage: 32_500
    ).upcomingMilestones.first!
    return LogMilestoneSheet(milestone: milestone, vehicle: vehicle)
        .presentationDetents([.large])
}

private enum LogSheetField: Hashable {
    case mileage, shop, cost, newItem
}
