import SwiftUI

private struct CompletedServiceCardState: Equatable {
    let scheduledMileage: Int
    let serviceMileage: Int
    let date: Date
    let items: [String]
}

struct ServicePlanView: View {
    let vehicle: Vehicle
    let sources: [OEMScheduleSource]
    /// Number of logged services for this vehicle — drives the "On record" dots.
    var serviceLogCount: Int = 0
    /// Logged services for this vehicle — used to compute per-milestone progress.
    var serviceLogs: [ServiceLog] = []

    private let milestones: [ServicePlanMilestone]
    private let minimumMileage: Int
    /// Some intervals are typical estimates because the manufacturer publishes no
    /// fixed mileage (Maintenance Minder / oil-life-monitor cars).
    private var usesTypicalIntervals = false

    @Environment(AppState.self) private var appState
    @State private var currentMileage: Int
    @State private var showMileageEdit = false
    @State private var showLogSheet = false
    @State private var mileageDraft: String = ""
    @State private var mileageError = false
    @State private var completedService: CompletedServiceCardState?
    @State private var showCompletedItems = true
    @State private var isOnRecordExpanded = false
    @Environment(\.dismiss) private var dismiss

    init(vehicle: Vehicle, plan: ServicePlan, sources: [OEMScheduleSource] = [], serviceLogs: [ServiceLog] = [], serviceLogCount: Int = 0) {
        self.vehicle = vehicle
        self.sources = sources
        self.serviceLogs = serviceLogs
        self.serviceLogCount = serviceLogCount
        self.milestones = plan.milestones
        self.minimumMileage = plan.currentMileage
        self._currentMileage = State(initialValue: plan.currentMileage)
    }

    init(vehicle: Vehicle, oemItems: [OEMScheduleItemInput], sources: [OEMScheduleSource] = [], severeDuty: Bool = false, serviceLogs: [ServiceLog] = [], serviceLogCount: Int = 0) {
        let plan = ServicePlanBuilder.build(items: oemItems, currentMileage: vehicle.mileage, severeDuty: severeDuty)
        self.vehicle = vehicle
        self.sources = sources
        self.serviceLogs = serviceLogs
        self.serviceLogCount = serviceLogCount
        self.milestones = plan.milestones
        self.minimumMileage = vehicle.mileage
        self.usesTypicalIntervals = oemItems.contains { $0.usesTypicalInterval && !($0.severeOnly && !severeDuty) }
        self._currentMileage = State(initialValue: vehicle.mileage)
    }

    private var plan: ServicePlan {
        ServicePlan(milestones: milestones, currentMileage: currentMileage)
    }

    private var nextMilestone: ServicePlanMilestone? {
        plan.upcomingMilestones.first
    }

    private var compactUpcoming: [ServicePlanMilestone] {
        Array(plan.upcomingMilestones.dropFirst())
    }

    /// `serviceLogCount` is passed in live from the app's logs, so newly saved
    /// services are already counted; adding one for the completed card counted
    /// them twice.
    private var displayedServiceLogCount: Int {
        serviceLogCount
    }

    /// Progress (0–1) through the current mileage interval.
    private var gaugeProgress: Double {
        guard let next = nextMilestone else { return 1 }
        let prev = plan.completedMilestones.last?.mileage ?? 0
        let interval = Double(next.mileage - prev)
        guard interval > 0 else { return 0 }
        return max(0, min(1, Double(currentMileage - prev) / interval))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                navBar
                vehicleHeader
                statsRow
                dividerLine
                onRecordRow
                mainContent
            }
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .bottom)
    }

    private var navBar: some View {
        ZStack {
            // Centered title
            Text("Service Logbook")
                .font(.quicksand(.medium, size: 14))
                .tracking(1.62)
                .foregroundStyle(ServicePlanPalette.textMuted)

            // Back button pinned to the left
            HStack {
                BackButton()

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Vehicle Header

    private var vehicleHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(vehicle.year, format: .number.grouping(.never)) · \(vehicle.make)")
                .font(.quicksand(.regular, size: 14))
                .tracking(2.86)
                .foregroundStyle(ServicePlanPalette.textMuted)
            Text(vehicle.model)
                .font(.quicksand(.semibold, size: 26))
                .foregroundStyle(ServicePlanPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(alignment: .center, spacing: 20) {
            MilesGauge(
                milesUntilNext: plan.milesUntilNext,
                progress: gaugeProgress
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Odometer")
                    .font(.quicksand(.regular, size: 12))
                    .tracking(1.62)
                    .foregroundStyle(ServicePlanPalette.textMuted)
                    .frame(height: 13.5)

                Button {
                    mileageDraft = currentMileage.formatted()
                    mileageError = false
                    showMileageEdit = true
                } label: {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(currentMileage.formatted())
                            .font(.quicksand(.semibold, size: 22))
                            .foregroundStyle(ServicePlanPalette.textPrimary)
                            .monospacedDigit()
                        Text("mi")
                            .font(.quicksand(.medium, size: 13))
                            .foregroundStyle(ServicePlanPalette.textMuted)
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ServicePlanPalette.teal)
                    }
                    .frame(height: 22.5)
                }
                .buttonStyle(.plain)

                if let next = nextMilestone {
                    Text("Next milestone at \(next.mileage.formatted()) mi")
                        .font(.quicksand(.regular, size: 11))
                        .foregroundStyle(ServicePlanPalette.textSecondary)
                        .frame(height: 13.75)
                }
            }
            .frame(width: 214.11, height: 65.72, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, minHeight: 119.99)
        .sheet(isPresented: $showMileageEdit) {
            OdometerEditSheet(draft: $mileageDraft, error: $mileageError, minimumMileage: minimumMileage) { value in
                withAnimation(.easeInOut(duration: 0.3)) { currentMileage = value }
                showMileageEdit = false
            }
        }
    }

    // MARK: - Divider

    private var dividerLine: some View {
        Rectangle()
            .fill(ServicePlanPalette.borderLight)
            .frame(height: 0.75)
            .padding(.horizontal, 20)
    }

    // MARK: - On Record Row

    private var onRecordRow: some View {
        Button {
            withAnimation(.spring(duration: 0.4, bounce: 0)) { isOnRecordExpanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                Text("PREVIOUSLY RECORDED SERVICES")
                    .font(.quicksand(.medium, size: 11))
                    .tracking(1.80)
                    .foregroundStyle(ServicePlanPalette.textMuted)


                Spacer()

                Text("\(displayedServiceLogCount) service\(displayedServiceLogCount == 1 ? "" : "s")")
                    .font(.quicksand(.medium, size: 11))
                    .foregroundStyle(ServicePlanPalette.textMuted)

                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isOnRecordExpanded ? 180 : 0))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ServicePlanPalette.textMuted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Returns (loggedItemCount, requiredItemCount) for a milestone, by matching
    /// service-log entries that fall within the milestone's mileage interval and
    /// share an item category.
    private func milestoneProgress(_ milestone: ServicePlanMilestone) -> (logged: Int, required: Int) {
        guard let index = milestones.firstIndex(of: milestone) else {
            return (0, milestone.items.count)
        }
        let lowerBound = index == 0 ? 0 : milestones[index - 1].mileage
        let upperBound = milestone.mileage
        let logsInRange = serviceLogs.filter { $0.mileage > lowerBound && $0.mileage <= upperBound }
        let loggedCategories = Set(logsInRange.map { $0.category.rawValue.lowercased() })
        let logged = milestone.items.reduce(0) { acc, item in
            loggedCategories.contains(item.category.lowercased()) ? acc + 1 : acc
        }
        return (logged, milestone.items.count)
    }

    // MARK: - Main Scrollable Content

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Completed milestones — inline list, controlled by On Record header toggle
            if !plan.completedMilestones.isEmpty && isOnRecordExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(plan.completedMilestones.enumerated()), id: \.element.id) { index, milestone in
                        let progress = milestoneProgress(milestone)
                        CompletedMilestoneRow(
                            milestone: milestone,
                            loggedCount: progress.logged,
                            requiredCount: progress.required
                        )
                        if index < plan.completedMilestones.count - 1 {
                            Rectangle()
                                .fill(Color.black.opacity(0.15))
                                .frame(height: 0.37)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
                // Fade in after the space opens, fade out quickly before it closes, so the
                // list never slides over the card below it.
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeOut(duration: 0.25).delay(0.12)),
                    removal: .opacity.animation(.easeIn(duration: 0.12))
                ))
            }

            // Next milestone or newly logged completed service
            if let completedService {
                completedServiceCard(completedService)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            } else if let milestone = nextMilestone {
                nextMilestoneCard(milestone)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }

            // Upcoming section
            if !compactUpcoming.isEmpty {
                upcomingSection
            }

            // Footer
            sourceFooter
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
        }
    }

    // MARK: - Next Milestone Card

    @ViewBuilder
    private func nextMilestoneCard(_ milestone: ServicePlanMilestone) -> some View {
        ZStack(alignment: .topLeading) {
            // Card content
            VStack(alignment: .leading, spacing: 0) {

                // Header row: placeholder for ribbon spacing
                HStack(alignment: .bottom, spacing: 0) {
                    Spacer()
                        .frame(width: 28)

                    // "Next service" · distance — spread across remaining width
                    HStack(spacing: 0) {
                        Text("NEXT SERVICE")
                            .font(.quicksand(.semibold, size: 11))
                            .tracking(1.75)
                            .foregroundStyle(ServicePlanPalette.teal)
                        Spacer()
                        Text("\(plan.milesUntilNext.formatted()) mi away")
                            .font(.quicksand(.regular, size: 11))
                            .foregroundStyle(ServicePlanPalette.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 12)
                }
                .padding(.bottom, 16)

                // Mileage headline + unit
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(milestone.mileage.formatted())
                        .font(.quicksand(.semibold, size: 36))
                        .foregroundStyle(ServicePlanPalette.textPrimary)
                        .monospacedDigit()

                    Text("mi")
                        .font(.quicksand(.regular, size: 12))
                        .foregroundStyle(ServicePlanPalette.textSecondary)
                }
                .padding(.bottom, 8)

                // Summary line
                Text(summaryText(milestone))
                    .font(.quicksand(.regular, size: 11))
                    .foregroundStyle(ServicePlanPalette.textSecondary)
                    .padding(.bottom, 14)

                // Replacement item chips
                if !milestone.replacements.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(milestone.replacements) { item in
                                Text(item.name)
                                    .font(.quicksand(.regular, size: 11))
                                    .foregroundStyle(ServicePlanPalette.teal)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(ServicePlanPalette.chipSage)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(ServicePlanPalette.chipSage, lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }

                // Log this service button
                LogServiceButton {
                    showLogSheet = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(ServicePlanPalette.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.75)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 28, y: 12)

            // Ribbon icon — positioned at top-left, bleeding above card
            Image("ribbon-icon")
                .resizable()
                .scaledToFit()
                .padding(EdgeInsets(top: 3, leading: 9, bottom: 6, trailing: 9))
                .frame(width: 28, height: 36)
                .background(ServicePlanPalette.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(0.10), radius: 2, y: 1)
                .offset(x: 20, y: -3.24)
                .zIndex(1)
        }
        .sheet(isPresented: $showLogSheet) {
            if let milestone = nextMilestone {
                LogMilestoneSheet(milestone: milestone, vehicle: vehicle) { logs, itemNames in
                    // One log per item; they share date, shop and mileage.
                    logs.forEach(appState.addServiceLog)
                    guard let first = logs.first else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        completedService = CompletedServiceCardState(
                            scheduledMileage: milestone.mileage,
                            serviceMileage: first.mileage,
                            date: first.date,
                            items: itemNames
                        )
                        showCompletedItems = true
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Completed Service Card

    private func completedServiceCard(_ completed: CompletedServiceCardState) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 0) {
                    Spacer()
                        .frame(width: 40)

                    Text("COMPLETED")
                        .font(.quicksand(.semibold, size: 11))
                        .tracking(1.80)
                        .foregroundStyle(ServicePlanPalette.textMuted)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(height: 15, alignment: .leading)
                        .offset(y: -3) // Competed text Adjust this value to move COMPLETED up/down
                    Spacer()

                    Text("RECORDED")
                        .font(.quicksand(.regular, size: 11))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(height: 15, alignment: .trailing)
                }
                .frame(width: 312.61, height: 15)
                .padding(.bottom, 4)

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(completed.scheduledMileage.formatted())
                        .font(.quicksand(.semibold, size: 36))
                        .foregroundStyle(ServicePlanPalette.textPrimary)
                        .monospacedDigit()
                        .frame(height: 36)

                    Text("mi")
                        .font(.quicksand(.regular, size: 12))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                        .frame(height: 15.99)
                }
                .frame(width: 312.61, height: 36, alignment: .leading)
                .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(completedPrimaryText(completed))
                        .font(.quicksand(.bold, size: 11))
                        .foregroundStyle(ServicePlanPalette.textSecondary)
                        .underline()
                        .frame(height: 15.12)

                    Text(completedSecondaryText(completed))
                        .font(.quicksand(.regular, size: 11))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(height: 13.74)
                }
                .frame(width: 312.61, alignment: .leading)
                .padding(.bottom, 22)

                completedItemsSection(completed)
                    .padding(.bottom, 28)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentMileage = max(currentMileage, completed.scheduledMileage)
                        completedService = nil
                    }
                } label: {
                    Text("Dismiss & view next service")
                        .font(.quicksand(.semibold, size: 11))
                        .tracking(0.28)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36.5)
                        .background(ServicePlanPalette.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20.74)
            .padding(.top, 20.49)
            .padding(.bottom, 20)
            .frame(width: 354.09836, alignment: .topLeading)
            .background(ServicePlanPalette.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 12)
            .shadow(color: .black.opacity(0.04), radius: 0, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 0.37)
                    .stroke(.black.opacity(0.06), lineWidth: 0.74922)
            )

            completedRibbon
                .offset(x: 20, y: -3.24)
                .zIndex(1)
        }
    }

    private var completedRibbon: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 17.39, height: 17.74)
        }
        .padding(EdgeInsets(top: 0, leading: 8.99, bottom: 5.99, trailing: 9))
        .frame(width: 27.99, height: 36)
        .background(ServicePlanPalette.teal)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: Color.black.opacity(0.10), radius: 2, y: 1)
    }

    private func completedItemsSection(_ completed: CompletedServiceCardState) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCompletedItems.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                        .frame(width: 12, height: 12)

                    Text("\(completed.items.count) of \(completed.items.count) items serviced")
                        .font(.quicksand(.medium, size: 11))
                        .foregroundStyle(ServicePlanPalette.textPrimary)
                        .frame(height: 16.5)

                    Spacer()

                    Text(showCompletedItems ? "Hide" : "Show")
                        .font(.quicksand(.medium, size: 11))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                        .frame(width: 32, height: 15, alignment: .trailing)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(width: 312.61, height: 32.5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showCompletedItems {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(completed.items.enumerated()), id: \.offset) { _, item in
                        completedItemRow(item)
                    }
                }
                .frame(width: 312.61, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(width: 312.61, alignment: .leading)
    }

    private func completedItemRow(_ item: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ServicePlanPalette.textMuted)
                .frame(width: 10.99, height: 10.99)

            Text(item)
                .font(.quicksand(.regular, size: 11))
                .foregroundStyle(ServicePlanPalette.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(height: 24)
    }

    private func completedPrimaryText(_ completed: CompletedServiceCardState) -> String {
        "\(completionTimingLabel(completed)) at \(completed.serviceMileage.formatted()) mi · \(completed.date.formatted(.dateTime.month(.abbreviated).day().year()))"
    }

    private func completedSecondaryText(_ completed: CompletedServiceCardState) -> String {
        let delta = abs(completed.scheduledMileage - completed.serviceMileage)
        let scheduled = completed.scheduledMileage.formatted()
        let actual = completed.serviceMileage.formatted()

        if delta == 0 {
            return "Completed at the \(scheduled) mi mark — next intervals reset from \(actual)."
        } else if completed.serviceMileage < completed.scheduledMileage {
            return "\(delta.formatted()) mi before the \(scheduled) mi mark — next intervals reset from \(actual)."
        } else {
            return "\(delta.formatted()) mi after the \(scheduled) mi mark — next intervals reset from \(actual)."
        }
    }

    private func completionTimingLabel(_ completed: CompletedServiceCardState) -> String {
        if completed.serviceMileage < completed.scheduledMileage {
            return "Done early"
        } else if completed.serviceMileage > completed.scheduledMileage {
            return "Done late"
        } else {
            return "Done on time"
        }
    }

    private func summaryText(_ milestone: ServicePlanMilestone) -> String {
        let r = milestone.replacements.count
        let i = milestone.inspections.count
        let rStr = "\(r) replacement\(r == 1 ? "" : "s")"
        let iStr = "\(i) inspection\(i == 1 ? "" : "s")"
        return "\(rStr) and \(iStr)."
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming")
                .font(.quicksand(.regular, size: 11))
                .tracking(1.98)
                .foregroundStyle(ServicePlanPalette.textMuted)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(compactUpcoming) { milestone in
                    CompactMilestoneRow(milestone: milestone)
                }
            }
            .background(ServicePlanPalette.cardBg)
            .overlay(
                Rectangle()
                    .strokeBorder(ServicePlanPalette.borderLight, lineWidth: 0.75)
            )
        }
        .padding(.bottom, 24)
    }

    // MARK: - Source Footer

    private var sourceFooter: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundStyle(ServicePlanPalette.textMuted)

            if sources.isEmpty {
                // No citations saved for this vehicle (analysis failed, model gave none,
                // or the vehicle predates source capture). Don't claim a specific
                // interval here — it may not match the schedule shown above.
                Text("Source — Typical manufacturer intervals. We couldn't link a source for your exact vehicle yet.")
                    .font(.quicksand(.regular, size: 12))
                    .foregroundStyle(ServicePlanPalette.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(usesTypicalIntervals
                         ? "Based on manufacturer recommendations. Your car uses a dashboard maintenance reminder instead of fixed mileages for some services, so those are shown at typical intervals."
                         : "Based on manufacturer recommendations.")
                        .font(.quicksand(.regular, size: 12))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(sources) { source in
                        SourceLinkRow(source: source)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ServicePlanPalette.borderLight)
                .frame(height: 0.75)
        }
    }
}

private struct SourceLinkRow: View {
    let source: OEMScheduleSource

    var body: some View {
        if let url = source.linkURL {
            Link(destination: url) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(ServicePlanPalette.teal)
                        .frame(width: 12, alignment: .center)

                    Text(source.name)
                        .font(.quicksand(.medium, size: 12))
                        .foregroundStyle(ServicePlanPalette.teal)
                        .underline()
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(ServicePlanPalette.textMuted)
                    .frame(width: 12, alignment: .center)

                Text(source.name)
                    .font(.quicksand(.medium, size: 12))
                    .foregroundStyle(ServicePlanPalette.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview("Service Logbook — 2024 Audi A4") {
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
        usage: ["Daily commuter"],
        conditions: []
    )
    let sources: [OEMScheduleSource] = [
        OEMScheduleSource(
            type: "official",
            name: "2024 Audi A4 Warranty & Maintenance Guide",
            url: "https://www.audiusa.com/us/web/en/owners/maintenance.html"
        )
    ]
    return ServicePlanView(
        vehicle: vehicle,
        oemItems: ServicePlanBuilder.demoItems,
        sources: sources,
        serviceLogCount: 6
    )
    .environment(AppState())
}

// MARK: - Odometer Edit Sheet

/// Owns its keyboard focus, so focus ends with the sheet instead of lingering
/// on the Service Plan screen and flashing the keyboard back up after dismissal.
private struct OdometerEditSheet: View {
    @Binding var draft: String
    @Binding var error: Bool
    let minimumMileage: Int
    let onSave: (Int) -> Void

    @FocusState private var focused: Bool
    @State private var sheetHeight: CGFloat = 220

    var body: some View {
        VStack(spacing: 20) {
            Text("Update Odometer")
                .font(.quicksand(.semibold, size: 16))
                .foregroundStyle(ServicePlanPalette.textPrimary)

            HStack(spacing: 8) {
                TextField("", text: $draft)
                    .font(.quicksand(.semibold, size: 24))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .onChange(of: draft) { _, newValue in
                        error = false
                        // Show thousands separators as the user types (e.g. 32,312).
                        let digits = String(newValue.filter(\.isNumber).prefix(7))
                        let formatted = Int(digits).map { $0.formatted() } ?? ""
                        if formatted != newValue { draft = formatted }
                    }
                Text("mi")
                    .font(.quicksand(.regular, size: 18))
                    .foregroundStyle(ServicePlanPalette.textMuted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(ServicePlanPalette.neutralChipBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if error {
                Text("Mileage can only go up (min \(minimumMileage.formatted()) mi)")
                    .font(.quicksand(.regular, size: 11))
                    .foregroundStyle(Color.agDestructive)
            }

            Button {
                guard let value = Int(draft.filter { $0.isNumber }),
                      value >= minimumMileage else {
                    error = true
                    return
                }
                // Drop focus before closing so the keyboard can't flash back up.
                focused = false
                onSave(value)
            } label: {
                Text("Save")
                    .font(.quicksand(.semibold, size: 14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ServicePlanPalette.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .keyboardDoneBar { focused = false }
        // Size the sheet to its content so there's no empty space under Save.
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
        .presentationDetents([.height(sheetHeight)])
        // No auto-focus on open: focusing while the sheet is still presenting makes
        // iOS replay the keyboard as the sheet closes (a quick keyboard flash).
        .onDisappear { focused = false }
    }
}
