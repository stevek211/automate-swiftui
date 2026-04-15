import SwiftUI

// MARK: - Design Tokens (scoped to this feature)
//
// Exact hex values from the Figma design, scoped locally so the rest of the
// app's theme (agPrimary etc.) stays untouched. If these need to promote to
// global tokens later, lift them into Theme/Colors.swift.

enum ServicePlanPalette {
    static let bg            = Color(hex: "F9FAFB")
    static let timeline      = Color(hex: "E5E7EB")
    static let timelineAccent = Color(hex: "295350") // active segment

    static let teal          = Color(hex: "00786F")  // primary brand in design
    static let tealDeep      = Color(hex: "295350")
    static let tealBright    = Color(hex: "007970")
    static let tealTintSoft  = Color(hex: "F3FFF8")
    static let tealTintChip  = Color(hex: "E8EFEE")
    static let tealTintBtn   = Color(hex: "E6EFED")
    static let tealRing      = Color(hex: "E4EBE8")

    static let greenTint     = Color(hex: "DCFCE7")
    static let greenText     = Color(hex: "008236")

    // Mint tint used by the REPLACE action pill and the compact-row
    // "N replace" summary chip in the updated design language.
    static let replaceTint   = Color(hex: "CBFBF1")

    static let neutralChipBg  = Color(hex: "F3F4F6")
    static let neutralChipTxt = Color(hex: "4A5565")
    static let borderDefault  = Color(hex: "E5E7EB")
    static let borderSoft     = Color(hex: "C8C8C8")
    static let borderCheckbox = Color(hex: "D1D5DC")

    static let textPrimary   = Color(hex: "101828")
    static let textSecondary = Color(hex: "364153")
    static let textMuted     = Color(hex: "6A7282")
    static let textBody      = Color(hex: "4A5565")
    static let textFaint     = Color(hex: "99A1AF")
}

// MARK: - Action Pill

struct ActionPill: View {
    let action: ServiceAction

    private var bg: Color {
        switch action {
        case .replace:                  return ServicePlanPalette.replaceTint
        case .adjust, .clean:           return ServicePlanPalette.tealTintChip
        case .perform:                  return ServicePlanPalette.greenTint
        case .inspect:                  return ServicePlanPalette.neutralChipBg
        }
    }

    private var fg: Color {
        switch action {
        case .replace, .adjust, .clean: return ServicePlanPalette.teal
        case .perform:                  return ServicePlanPalette.greenText
        case .inspect:                  return ServicePlanPalette.neutralChipTxt
        }
    }

    var body: some View {
        Text(action.displayText)
            .font(.poppins(.semibold, size: 9))
            .kerning(0.2)
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Service Item Row (checkbox + icon + name + action pill)

struct ServiceItemRow: View {
    let item: ServicePlanItem
    @State private var checked = false

    var body: some View {
        Button {
            checked.toggle()
        } label: {
            HStack(spacing: 10) {
                // Checkbox
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(ServicePlanPalette.borderCheckbox, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(checked ? ServicePlanPalette.teal : Color.white)
                    )
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(checked ? 1 : 0)
                    )

                // Use a custom SVG asset if available, otherwise fall back to SF Symbol
                if let asset = ServiceItemIcon.customAsset(for: item.category) {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: ServiceItemIcon.sfSymbol(for: item.category, action: item.action))
                        .font(.system(size: 11))
                        .foregroundStyle(ServicePlanPalette.textBody)
                        .frame(width: 14, height: 14)
                }

                Text(item.name)
                    .font(.poppins(.medium, size: 12))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                    .strikethrough(checked, color: ServicePlanPalette.textMuted)
                    .lineLimit(1)

                Spacer(minLength: 8)

                ActionPill(action: item.action)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category → icon mapping

enum ServiceItemIcon {
    /// Returns a custom asset name if we have a hand-crafted icon for this
    /// category, or nil to fall back to an SF Symbol.
    static func customAsset(for category: String) -> String? {
        switch category.lowercased() {
        case "oil": return "icon-oil-can"
        default:    return nil
        }
    }

    static func sfSymbol(for category: String, action: ServiceAction) -> String {
        switch category.lowercased() {
        case "oil":          return "drop.fill"
        case "tires":        return "arrow.triangle.2.circlepath"
        case "brakes":       return "car.side"
        case "filters":      return "wind"
        case "battery":      return "bolt.fill"
        case "transmission": return "gearshape.2.fill"
        case "cooling":      return "thermometer"
        case "fluids":       return "drop"
        case "belts":        return "arrow.triangle.2.circlepath.circle"
        case "ignition":     return "bolt.circle.fill"
        case "suspension":   return "car.rear"
        case "engine":       return "engine.combustion.fill"
        case "exhaust":      return "smoke.fill"
        case "electrical":   return "bolt"
        default:
            switch action {
            case .inspect: return "magnifyingglass"
            case .replace: return "wrench.fill"
            default:       return "wrench.and.screwdriver"
            }
        }
    }
}

// MARK: - "Did All — Mark Complete" button

struct MarkCompleteButton: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 12, weight: .semibold))
                Text("Did All — Mark Complete")
                    .font(.poppins(.semibold, size: 12))
            }
            .foregroundStyle(ServicePlanPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(ServicePlanPalette.tealTintBtn)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(ServicePlanPalette.borderDefault, lineWidth: 0.75)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detailed Milestone Card

struct DetailedMilestoneCard: View {
    let milestone: ServicePlanMilestone
    let index: Int           // 1-based position in upcoming list
    let isNext: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Numbered timeline badge
            ZStack {
                Circle()
                    .fill(Color.white)
                    .overlay(
                        Circle().strokeBorder(
                            isNext ? ServicePlanPalette.teal : ServicePlanPalette.borderCheckbox,
                            lineWidth: 1.5
                        )
                    )
                    .frame(width: 22, height: 22)
                Text("\(index)")
                    .font(.poppins(.bold, size: 9))
                    .foregroundStyle(isNext ? ServicePlanPalette.tealDeep : ServicePlanPalette.textMuted)
            }
            .offset(x: -11) // center on timeline
            .padding(.top, 14)

            // Card
            card
                .padding(.leading, 14)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: mileage / months + NEXT badge
            HStack(alignment: .firstTextBaseline) {
                Text("\(milestone.mileage.formatted()) mi")
                    .font(.poppins(.bold, size: 14))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                Spacer()
                if isNext {
                    Text("NEXT")
                        .font(.poppins(.bold, size: 9))
                        .kerning(0.25)
                        .foregroundStyle(ServicePlanPalette.teal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ServicePlanPalette.tealTintChip)
                        .clipShape(Capsule())
                }
            }

            MarkCompleteButton()

            if !milestone.replacements.isEmpty {
                sectionHeader("REPLACEMENTS", accent: true)
                VStack(spacing: 0) {
                    ForEach(milestone.replacements) { item in
                        ServiceItemRow(item: item)
                    }
                }
            }

            if !milestone.inspections.isEmpty {
                sectionHeader("INSPECTIONS & SERVICE", accent: false)
                VStack(spacing: 0) {
                    ForEach(milestone.inspections) { item in
                        ServiceItemRow(item: item)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isNext ? ServicePlanPalette.borderSoft : ServicePlanPalette.borderDefault,
                    lineWidth: 0.75
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
    }

    private func sectionHeader(_ text: String, accent: Bool) -> some View {
        Text(text)
            .font(.poppins(.semibold, size: 10))
            .kerning(0.5)
            .foregroundStyle(accent ? ServicePlanPalette.teal : ServicePlanPalette.textBody)
    }
}

// MARK: - Compact Milestone Row

struct CompactMilestoneRow: View {
    let milestone: ServicePlanMilestone

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    // Timeline dot — overlays the vertical line
                    Circle()
                        .fill(ServicePlanPalette.borderCheckbox)
                        .frame(width: 9, height: 9)
                        .offset(x: -4.5)

                    Text("\(milestone.mileage.formatted()) mi")
                        .font(.poppins(.bold, size: 12))
                        .foregroundStyle(ServicePlanPalette.textPrimary)

                    Text("\(milestone.items.count) items")
                        .font(.poppins(.medium, size: 10))
                        .foregroundStyle(ServicePlanPalette.textMuted)

                    if milestone.replaceCount > 0 {
                        Text("\(milestone.replaceCount) replace")
                            .font(.poppins(.semibold, size: 9))
                            .kerning(0.25)
                            .foregroundStyle(ServicePlanPalette.teal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(ServicePlanPalette.replaceTint)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer(minLength: 4)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(milestone.items) { item in
                        ServiceItemRow(item: item)
                    }
                }
                .padding(.leading, 24)
                .padding(.trailing, 8)
                .padding(.top, 4)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - "You Are Here" marker card

struct YouAreHereCard: View {
    let currentMileage: Int
    /// The minimum allowed value — odometers only go up, so you can never
    /// save a mileage lower than the previously-committed value.
    let minimumMileage: Int
    let nextMileage: Int?
    let milesUntilNext: Int
    /// Called when the user commits a valid new mileage via the checkmark.
    var onCommit: (Int) -> Void = { _ in }

    @State private var isEditing = false
    @State private var draft: String = ""
    @State private var showError = false
    @FocusState private var focused: Bool

    private var parsedDraft: Int? {
        Int(draft.filter { $0.isNumber })
    }

    private var canCommit: Bool {
        guard let value = parsedDraft else { return false }
        return value >= minimumMileage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline indicator: pill + location pin
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(ServicePlanPalette.tealDeep)
                    .frame(width: 3, height: 44)
                    .offset(y: 18)

                Circle()
                    .fill(ServicePlanPalette.tealBright)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image("car")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.white)
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    )
                    .shadow(color: ServicePlanPalette.tealBright.opacity(0.25), radius: 4, x: 0, y: 2)
                    .offset(y: 24)
            }
            .frame(width: 28)
            .offset(x: -14)

            // Card
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("YOU ARE HERE")
                        .font(.poppins(.bold, size: 11))
                        .kerning(0.1)
                        .foregroundStyle(ServicePlanPalette.teal)

                    if isEditing {
                        editingRow
                    } else {
                        displayRow
                    }
                }

                if isEditing, showError {
                    Text("Mileage can only go up (min \(minimumMileage.formatted()) mi)")
                        .font(.poppins(.regular, size: 10))
                        .foregroundStyle(Color.agDestructive)
                } else if let next = nextMileage {
                    (
                        Text("Next service at \(next.formatted()) mi — ")
                            .font(.poppins(.regular, size: 11))
                            .foregroundStyle(ServicePlanPalette.textBody)
                        + Text("\(milesUntilNext.formatted()) mi away")
                            .font(.poppins(.semibold, size: 11))
                            .foregroundStyle(ServicePlanPalette.textPrimary)
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ServicePlanPalette.tealTintSoft)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isEditing && showError ? Color.agDestructive : ServicePlanPalette.borderSoft,
                        lineWidth: 0.75
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.leading, 14)
        }
    }

    // MARK: - Display / Edit subviews

    private var displayRow: some View {
        HStack(spacing: 6) {
            Button {
                beginEditing()
            } label: {
                Text("\(currentMileage.formatted()) mi")
                    .font(.poppins(.medium, size: 11))
                    .foregroundStyle(ServicePlanPalette.tealDeep)
                    .underline()
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                beginEditing()
            } label: {
                Text("Update odometer")
                    .font(.poppins(.medium, size: 10))
                    .foregroundStyle(ServicePlanPalette.tealDeep)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }

    private var editingRow: some View {
        HStack(spacing: 6) {
            TextField("", text: $draft)
                .font(.poppins(.semibold, size: 12))
                .foregroundStyle(ServicePlanPalette.textPrimary)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .focused($focused)
                .frame(minWidth: 60, maxWidth: 90)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(ServicePlanPalette.borderSoft, lineWidth: 0.75)
                )
                .onChange(of: draft) { _, _ in
                    if showError { showError = false }
                }
                .onSubmit { commit() }

            Text("mi")
                .font(.poppins(.regular, size: 11))
                .foregroundStyle(ServicePlanPalette.textMuted)

            Spacer()

            Button { cancelEditing() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ServicePlanPalette.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Color.white)
                    .overlay(Circle().strokeBorder(ServicePlanPalette.borderDefault, lineWidth: 0.75))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button { commit() } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(canCommit ? ServicePlanPalette.tealBright : ServicePlanPalette.borderCheckbox)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canCommit && !showError) // allow taps so we can show the error
        }
    }

    // MARK: - Actions

    private func beginEditing() {
        draft = "\(currentMileage)"
        showError = false
        withAnimation(.easeInOut(duration: 0.15)) { isEditing = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
    }

    private func cancelEditing() {
        focused = false
        showError = false
        withAnimation(.easeInOut(duration: 0.15)) { isEditing = false }
    }

    private func commit() {
        guard let value = parsedDraft, value >= minimumMileage else {
            showError = true
            return
        }
        focused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
            showError = false
        }
        onCommit(value)
    }
}

// MARK: - Collapsed-completed header row

struct CollapsedCompletedRow: View {
    let milestones: [ServicePlanMilestone]
    let rangeLabel: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    // Green check badge overlapping the timeline
                    Circle()
                        .fill(ServicePlanPalette.greenTint)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(ServicePlanPalette.greenText)
                        )
                        .offset(x: -9)

                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ServicePlanPalette.textMuted)
                        Text("\(milestones.count) completed milestones")
                            .font(.poppins(.medium, size: 12))
                            .foregroundStyle(ServicePlanPalette.textMuted)
                        Text(rangeLabel)
                            .font(.poppins(.medium, size: 10))
                            .foregroundStyle(ServicePlanPalette.textFaint)
                    }
                    .padding(.leading, 6)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(milestones) { milestone in
                        CompletedMilestoneRow(milestone: milestone)
                    }
                }
                .padding(.leading, 14)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Completed milestone row (inside the expanded completed section)

struct CompletedMilestoneRow: View {
    let milestone: ServicePlanMilestone

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(ServicePlanPalette.greenTint)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(ServicePlanPalette.greenText)
                        )
                        .offset(x: -6)

                    Text("\(milestone.mileage.formatted()) mi")
                        .font(.poppins(.bold, size: 12))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                        .strikethrough(true, color: ServicePlanPalette.textFaint)

                    Text("\(milestone.items.count) items")
                        .font(.poppins(.medium, size: 10))
                        .foregroundStyle(ServicePlanPalette.textFaint)

                    Spacer(minLength: 4)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(milestone.items) { item in
                        ServiceItemRow(item: item)
                    }
                }
                .padding(.leading, 18)
                .padding(.trailing, 8)
                .padding(.vertical, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - "N more milestones" toggle header

struct MoreMilestonesToggle: View {
    let count: Int
    let rangeLabel: String
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 0) {
                Circle()
                    .fill(ServicePlanPalette.borderCheckbox)
                    .frame(width: 12, height: 12)
                    .offset(x: -6)

                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                    Text("\(count) more milestones")
                        .font(.poppins(.medium, size: 12))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                    Text(rangeLabel)
                        .font(.poppins(.medium, size: 10))
                        .foregroundStyle(ServicePlanPalette.textFaint)
                }
                .padding(.leading, 6)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

