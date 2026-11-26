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

/// The "Log Service" sheet (Figma: Log Service Modal w/ Inspections).
/// Each service item has its own cost; Total Cost is their running sum.
struct LogMilestoneSheet: View {
    let milestone: ServicePlanMilestone
    let vehicle: Vehicle
    var onSave: ([ServiceLog], [String]) -> Void = { _, _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    /// Grey (default "today") until the user picks a date, then ink.
    @State private var datePicked = false
    @State private var shop: String = ""
    @State private var serviceMileageText: String
    @State private var inspectionStates: [UUID: InspectionState] = [:]
    @State private var removedItemIDs: Set<UUID> = []
    @State private var customItems: [String] = []
    /// Cost typed for each service item, keyed by `costKey(for:)`.
    @State private var itemCostTexts: [String: String] = [:]
    @State private var showAddItem = false
    @State private var newItemDraft = ""
    @State private var pendingRemoval: PendingServiceItemRemoval?
    /// The field being edited. While set, a Done bar sits above the keyboard and the field is scrolled into view.
    @FocusState private var focusedField: LogSheetField?
    @State private var keyboardVisible = false

    /// Width of the per-item cost field, and of the action tag column, so
    /// cost fields line up across replacement, inspection and custom rows.
    private let costFieldWidth: CGFloat = 80
    private let tagColumnWidth: CGFloat = 52

    init(
        milestone: ServicePlanMilestone,
        vehicle: Vehicle,
        onSave: @escaping ([ServiceLog], [String]) -> Void = { _, _ in }
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
                        .padding(.bottom, 32)
                        // Tapping empty space closes the keyboard. The gesture sits
                        // on the background, not the form: on the form it swallowed
                        // taps meant for the calendar (a UIKit view underneath).
                        .background {
                            Color.white
                                .contentShape(Rectangle())
                                .onTapGesture { focusedField = nil }
                        }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focusedField) { _, field in
                    guard let field else { return }
                    // Wait for the keyboard, then scroll only if the field is hidden
                    // (nil anchor), so hopping between visible fields doesn't move
                    // the form under the next tap.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(field)
                        }
                    }
                }
            }
            if focusedField != nil && keyboardVisible {
                // Sits just above the keyboard: number pads have no return key.
                keyboardDoneBar
            }
        }
        .background(.white)
        // Focus can stay set after its field is removed (e.g. closing "Add
        // another item"), so the Done bar follows the keyboard itself.
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("LOG SERVICE")
                    .font(.quicksand(.medium, size: 11))
                    .tracking(1.8)
                    .foregroundStyle(Color.theme.mutedText)
                Text("\(milestone.mileage.formatted()) mi service")
                    .font(.quicksand(.medium, size: 22))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
            }

            Spacer()

            Button { dismiss() } label: {
                Image("logservice-icon-close")
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ServicePlanPalette.borderLight)
                .frame(height: 0.75)
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            dateAndMileageRow
            shopField
            whatWasDoneSection
            totalCostField
            saveButton
        }
    }

    // MARK: Date + Mileage

    private var dateAndMileageRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                fieldColumn(label: "DATE") {
                    Button {
                        focusedField = nil
                        withAnimation(.easeInOut(duration: 0.2)) { showDatePicker.toggle() }
                    } label: {
                        HStack(spacing: 8) {
                            underlined {
                                Text(selectedDate.formatted(.dateTime.month(.abbreviated).day().year()))
                                    .font(.quicksand(.regular, size: 16))
                                    .foregroundStyle(datePicked ? ServicePlanPalette.textPrimary : Color.theme.faintText)
                            }
                            Image("logservice-icon-calendar")
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Date, \(selectedDate.formatted(date: .long, time: .omitted))")
                }

                fieldColumn(label: "SERVICE MILEAGE*", focusing: .mileage) {
                    HStack(spacing: 8) {
                        underlined {
                            TextField("", text: $serviceMileageText)
                                .onChange(of: serviceMileageText) { _, newValue in
                                    let formatted = formattedMileageInput(newValue)
                                    if formatted != newValue {
                                        serviceMileageText = formatted
                                    }
                                }
                                .font(.quicksand(.regular, size: 16))
                                .foregroundStyle(ServicePlanPalette.textPrimary)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                                .monospacedDigit()
                                .focused($focusedField, equals: .mileage)
                                .id(LogSheetField.mileage)
                        }
                        Text("mi")
                            .font(.quicksand(.regular, size: 14))
                            .foregroundStyle(Color.theme.mutedText)
                    }
                }
            }

            if showDatePicker {
                DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(ServicePlanPalette.teal)
                    .onChange(of: selectedDate) { _, _ in
                        datePicked = true
                        withAnimation(.easeInOut(duration: 0.2)) { showDatePicker = false }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: Shop

    private var shopField: some View {
        fieldColumn(label: "SHOP", focusing: .shop) {
            underlined {
                TextField(
                    "",
                    text: $shop,
                    prompt: Text("e.g. Jiffy Lube").foregroundStyle(Color.theme.faintText)
                )
                .font(.quicksand(.regular, size: 16))
                .foregroundStyle(ServicePlanPalette.textPrimary)
                // Shop names are proper nouns: autocorrect flags them and its
                // replacement popovers swallow the next tap.
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .onSubmit { focusedField = firstCostField }
                .focused($focusedField, equals: .shop)
                .id(LogSheetField.shop)
            }
        }
    }

    // MARK: Total Cost

    /// Read-only: the running sum of every item's cost. Grey at $0.00, ink once
    /// any cost is entered.
    private var totalCostField: some View {
        fieldColumn(label: "TOTAL COST") {
            underlined {
                Text("$ \(formattedAmount(totalCost))")
                    .font(.quicksand(.regular, size: 16))
                    .monospacedDigit()
                    .foregroundStyle(totalCost > 0 ? ServicePlanPalette.textPrimary : Color.theme.faintText)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: totalCost)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Save

    private var saveButton: some View {
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
    }

    // MARK: - What Was Done

    private var whatWasDoneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WHAT WAS DONE")
                .font(.quicksand(.medium, size: 12.5))
                .tracking(1.62)
                .foregroundStyle(Color.theme.mutedText)

            if !visibleReplacements.isEmpty {
                replacementsSection
            }

            if !visibleServices.isEmpty {
                servicesSection
            }

            if !visibleInspections.isEmpty {
                inspectionsSection
            }

            if !customItems.isEmpty {
                customItemsSection
            }

            addAnotherItemRow
                .padding(.top, 10)
        }
    }

    private func groupHeader(_ title: String) -> some View {
        Text(title)
            .font(.quicksand(.medium, size: 11))
            .tracking(1.44)
            .foregroundStyle(Color.theme.mutedText)
    }

    // MARK: Replacements

    /// "Do it" items (perform, rotate, clean, adjust). Listed as done, like
    /// replacements; the user removes any that weren't done.
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupHeader("SERVICES")

            ForEach(visibleServices) { item in
                HStack(spacing: 12) {
                    checkedBox
                    itemName(item.name, weight: .regular)
                    costField(key: costKey(for: item))
                    actionTag(item.action.displayText, color: ServicePlanPalette.serviceTag)
                    removeButton {
                        pendingRemoval = PendingServiceItemRemoval(name: item.name, source: .milestone(item.id))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var replacementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupHeader("REPLACEMENTS")

            ForEach(visibleReplacements) { item in
                HStack(spacing: 12) {
                    checkedBox
                    itemName(item.name, weight: .regular)
                    costField(key: costKey(for: item))
                    actionTag(item.action.displayText, color: ServicePlanPalette.replaceTag)
                    removeButton {
                        pendingRemoval = PendingServiceItemRemoval(name: item.name, source: .milestone(item.id))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: Inspections

    private var inspectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            groupHeader("INSPECTIONS")

            ForEach(visibleInspections) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        itemName(item.name, weight: .medium)
                        costField(key: costKey(for: item))
                        actionTag(item.action.displayText, color: ServicePlanPalette.inspectTag)
                        removeButton {
                            pendingRemoval = PendingServiceItemRemoval(name: item.name, source: .milestone(item.id))
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
                                            .strokeBorder(Color.theme.faintText, lineWidth: 1.5)
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
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        }
    }

    // MARK: Custom Items

    private var customItemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(customItems, id: \.self) { item in
                HStack(spacing: 12) {
                    checkedBox
                    itemName(item, weight: .regular)
                    costField(key: customCostKey(item))
                    // Custom items have no action; keep the column so costs line up.
                    Color.clear.frame(width: tagColumnWidth, height: 1)
                    removeButton {
                        pendingRemoval = PendingServiceItemRemoval(name: item, source: .custom(item))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: Row Pieces

    private var checkedBox: some View {
        Image("logservice-icon-check")
            .frame(width: 20, height: 20)
            .background(ServicePlanPalette.textPrimary, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
    }

    private func itemName(_ name: String, weight: QuicksandWeight) -> some View {
        Text(name)
            .font(.quicksand(weight, size: 14))
            .foregroundStyle(ServicePlanPalette.textPrimary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "$ 0.00" cost input for one item. Grey until a cost is typed, then ink.
    private func costField(key: String) -> some View {
        let text = Binding(
            get: { itemCostTexts[key] ?? "" },
            set: { newValue in
                let formatted = formattedCostInput(newValue)
                itemCostTexts[key] = formatted.isEmpty ? nil : formatted
            }
        )
        let hasValue = !(itemCostTexts[key] ?? "").isEmpty
        let field = LogSheetField.itemCost(key)

        return HStack(spacing: 4) {
            Text("$")
                .foregroundStyle(hasValue ? ServicePlanPalette.textPrimary : Color.theme.faintText)
            TextField("", text: text, prompt: Text("0.00").foregroundStyle(Color.theme.faintText))
                .foregroundStyle(ServicePlanPalette.textPrimary)
                .keyboardType(.decimalPad)
                .monospacedDigit()
                .focused($focusedField, equals: field)
        }
        .font(.quicksand(.regular, size: 14))
        .frame(width: costFieldWidth, height: 20, alignment: .leading)
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.theme.borderStrong)
                .frame(height: 0.75)
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField = field }
        .id(field)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cost")
    }

    private func actionTag(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.quicksand(.medium, size: 11))
            .tracking(0.5)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .frame(width: tagColumnWidth, alignment: .trailing)
    }

    private func removeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Image("logservice-icon-remove-a")
                Image("logservice-icon-remove-b")
            }
            .frame(width: 14, height: 14)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, -4)
        .accessibilityLabel("Remove service item")
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
                        .foregroundStyle(Color.theme.faintText)
                    Spacer()
                    Image("logservice-icon-plus")
                        .rotationEffect(.degrees(showAddItem ? 45 : 0))
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
            Line()
                .stroke(Color.theme.borderStrong, style: StrokeStyle(lineWidth: 0.75, dash: [3, 3]))
                .frame(height: 0.75)
        }
    }

    private func addCustomItem() {
        let trimmed = newItemDraft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !customItems.contains(trimmed) else { return }
        customItems.append(trimmed)
        newItemDraft = ""
        showAddItem = false
        focusedField = nil
    }

    // MARK: - Keyboard Done Bar

    private var keyboardDoneBar: some View {
        HStack {
            Spacer()
            Button("Done") { focusedField = nil }
                .font(.quicksand(.semibold, size: 16))
                .foregroundStyle(ServicePlanPalette.textPrimary)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
        }
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ServicePlanPalette.borderLight)
                .frame(height: 0.75)
        }
    }

    // MARK: - Field Helpers

    /// A label above its input. With `focusing`, a tap anywhere in the column
    /// (label, prefix, underline) focuses that field, not just the text line.
    private func fieldColumn<Content: View>(
        label: String,
        focusing field: LogSheetField? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.quicksand(.medium, size: 12))
                .tracking(1.62)
                .foregroundStyle(Color.theme.mutedText)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            if let field { focusedField = field }
        }
    }

    /// The thin underline used under every input in the sheet.
    private func underlined<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .padding(.bottom, 4)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.theme.borderStrong)
                    .frame(height: 0.75)
            }
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
            itemCostTexts[customCostKey(name)] = nil
        }
        pendingRemoval = nil
    }

    // MARK: - Costs

    private func costKey(for item: ServicePlanItem) -> String { "item-\(item.id.uuidString)" }
    private func customCostKey(_ name: String) -> String { "custom-\(name)" }

    /// Keys of every item still in the sheet; removed items drop out of the total.
    private var visibleCostKeys: [String] {
        (visibleReplacements + visibleServices + visibleInspections).map(costKey(for:)) + customItems.map(customCostKey)
    }

    private var totalCost: Double {
        visibleCostKeys.reduce(0) { sum, key in
            sum + (itemCostTexts[key].flatMap(parsedCostInput) ?? 0)
        }
    }

    private var firstCostField: LogSheetField? {
        visibleCostKeys.first.map(LogSheetField.itemCost)
    }

    private func formattedAmount(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    // MARK: - Save Action

    /// Saves one log per service item, each with the cost the user entered,
    /// so the Cost section lists them as separate lines under one visit
    /// (same day and shop) whose total is their sum.
    private func save() {
        guard let serviceMileage = parsedServiceMileage else { return }
        let trimmedShop = shop.trimmingCharacters(in: .whitespaces)

        func log(_ name: String, cost: Double, category: ServiceCategory, notes: String? = nil) -> ServiceLog {
            ServiceLog(
                id: UUID(),
                vehicleId: vehicle.id,
                name: name,
                date: selectedDate,
                mileage: serviceMileage,
                cost: cost,
                shop: trimmedShop.isEmpty ? nil : trimmedShop,
                notes: notes,
                category: category
            )
        }

        func cost(_ key: String) -> Double { itemCostTexts[key].flatMap(parsedCostInput) ?? 0 }
        func category(for item: ServicePlanItem) -> ServiceCategory {
            ServiceCategory.fromPlanCategory(item.category) ?? .inferred(from: item.name)
        }

        var logs: [ServiceLog] = (visibleReplacements + visibleServices).map { item in
            log(item.name, cost: cost(costKey(for: item)), category: category(for: item))
        }
        logs += visibleInspections.map { item in
            // Keep the inspection result with the line, e.g. "Checked — all good".
            let result = (inspectionStates[item.id] ?? .notChecked).label
            return log(item.name, cost: cost(costKey(for: item)), category: category(for: item), notes: result)
        }
        logs += customItems.map { name in
            log(name, cost: cost(customCostKey(name)), category: .inferred(from: name))
        }

        // Every item was removed: still record the visit itself.
        if logs.isEmpty {
            logs = [log("\(milestone.mileage.formatted()) mi service", cost: 0, category: .general)]
        }

        onSave(logs, completedItemNames)
        dismiss()
    }

    private var completedItemNames: [String] {
        let milestoneItems = visibleReplacements.map(\.name) + visibleServices.map(\.name) + visibleInspections.map(\.name)
        return milestoneItems + customItems
    }

    private var visibleReplacements: [ServicePlanItem] {
        milestone.replacements.filter { !removedItemIDs.contains($0.id) }
    }

    /// Items you look at (inspect, check): logged with the 3 inspection choices.
    private var visibleInspections: [ServicePlanItem] {
        milestone.inspections.filter { Self.isInspection($0.action) && !removedItemIDs.contains($0.id) }
    }

    /// Items you do (perform, rotate, clean, adjust): logged as done, like replacements.
    private var visibleServices: [ServicePlanItem] {
        milestone.inspections.filter { !Self.isInspection($0.action) && !removedItemIDs.contains($0.id) }
    }

    private static func isInspection(_ action: ServiceAction) -> Bool {
        action == .inspect || action == .check
    }

    private var parsedServiceMileage: Int? {
        let digits = serviceMileageText.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }

    private var canSave: Bool {
        parsedServiceMileage != nil
    }
}

/// A horizontal line for dashed dividers.
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
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
    case mileage, shop, newItem
    case itemCost(String)
}
