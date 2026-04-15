import SwiftUI

/// Milestone-based Service Plan timeline.
///
/// Renders a vertical timeline of OEM maintenance milestones from 5,000 miles
/// up to 100,000. The current odometer position is shown with a "YOU ARE HERE"
/// marker between completed and upcoming milestones. The first few upcoming
/// milestones are shown in detail; later ones collapse into a compact list.
struct ServicePlanView: View {
    let vehicle: Vehicle

    /// OEM citations (manufacturer PDFs, dealer pages, etc.) rendered as
    /// tappable links in the footer so users can verify the schedule.
    let sources: [OEMScheduleSource]

    /// The set of milestones — fixed once the view is initialized. Mileage
    /// updates don't rebuild this list; they only shift the completed /
    /// upcoming partition.
    private let milestones: [ServicePlanMilestone]

    /// The lowest mileage the user can commit to. Odometers only go up, so
    /// this locks to the initial mileage for the lifetime of the view.
    private let minimumMileage: Int

    @State private var currentMileage: Int

    /// How many upcoming milestones to render in detail before collapsing
    /// the rest into the compact list. Matches the Figma design (3).
    private let detailedUpcomingCount = 3

    @State private var moreExpanded = true
    @Environment(\.dismiss) private var dismiss

    init(vehicle: Vehicle, plan: ServicePlan, sources: [OEMScheduleSource] = []) {
        self.vehicle = vehicle
        self.sources = sources
        self.milestones = plan.milestones
        self.minimumMileage = plan.currentMileage
        self._currentMileage = State(initialValue: plan.currentMileage)
    }

    /// Convenience initializer that builds the plan from raw OEM items.
    init(
        vehicle: Vehicle,
        oemItems: [OEMScheduleItemInput],
        sources: [OEMScheduleSource] = [],
        severeDuty: Bool = false
    ) {
        let plan = ServicePlanBuilder.build(
            items: oemItems,
            currentMileage: vehicle.mileage,
            severeDuty: severeDuty
        )
        self.vehicle = vehicle
        self.sources = sources
        self.milestones = plan.milestones
        self.minimumMileage = vehicle.mileage
        self._currentMileage = State(initialValue: vehicle.mileage)
    }

    /// Live plan, recomputed whenever `currentMileage` changes — drives the
    /// completed / upcoming / "you are here" split reactively.
    private var plan: ServicePlan {
        ServicePlan(milestones: milestones, currentMileage: currentMileage)
    }

    // Split upcoming into detailed (first N) and compact (rest).
    private var detailedUpcoming: [ServicePlanMilestone] {
        Array(plan.upcomingMilestones.prefix(detailedUpcomingCount))
    }
    private var compactUpcoming: [ServicePlanMilestone] {
        Array(plan.upcomingMilestones.dropFirst(detailedUpcomingCount))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                timeline
                    .padding(.top, 16)
                    .padding(.leading, 32)
                    .padding(.trailing, 16)
                    .padding(.bottom, 24)
            }
            .background(ServicePlanPalette.bg)
        }
        .background(ServicePlanPalette.bg)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(ServicePlanPalette.neutralChipBg)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Service Plan")
                    .font(.poppins(.bold, size: 16))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                Text("\(vehicle.year.description) \(vehicle.make) \(vehicle.model) · \(currentMileage.formatted()) mi")
                    .font(.poppins(.regular, size: 11))
                    .foregroundStyle(ServicePlanPalette.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ServicePlanPalette.borderDefault)
                .frame(height: 0.75)
        }
    }

    // MARK: - Timeline

    private var timeline: some View {
        ZStack(alignment: .topLeading) {
            // Vertical timeline line runs the full height of the content area.
            Rectangle()
                .fill(ServicePlanPalette.timeline)
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 16) {
                // Completed milestones — collapsed into a single row.
                if !plan.completedMilestones.isEmpty {
                    CollapsedCompletedRow(
                        milestones: Array(plan.completedMilestones),
                        rangeLabel: completedRangeLabel
                    )
                    .padding(.leading, 14)
                }

                // You Are Here marker.
                YouAreHereCard(
                    currentMileage: plan.currentMileage,
                    minimumMileage: minimumMileage,
                    nextMileage: plan.upcomingMilestones.first?.mileage,
                    milesUntilNext: plan.milesUntilNext,
                    onCommit: { newMileage in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentMileage = newMileage
                        }
                    }
                )

                // First N upcoming milestones — expanded cards.
                ForEach(Array(detailedUpcoming.enumerated()), id: \.element.id) { idx, milestone in
                    DetailedMilestoneCard(
                        milestone: milestone,
                        index: idx + 1,
                        isNext: idx == 0
                    )
                }

                // Remaining upcoming milestones — compact list with expand toggle.
                if !compactUpcoming.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        MoreMilestonesToggle(
                            count: compactUpcoming.count,
                            rangeLabel: compactRangeLabel,
                            isExpanded: $moreExpanded
                        )
                        .padding(.leading, 14)
                        .padding(.vertical, 8)

                        if moreExpanded {
                            VStack(spacing: 4) {
                                ForEach(compactUpcoming) { milestone in
                                    CompactMilestoneRow(milestone: milestone)
                                        .padding(.leading, 14)
                                }
                            }
                        }
                    }
                }

                // "Schedule continues" note.
                HStack(spacing: 12) {
                    Circle()
                        .fill(ServicePlanPalette.borderDefault)
                        .frame(width: 10, height: 10)
                        .offset(x: -5)
                    Text("Schedule continues at 5,000-mile intervals")
                        .font(.poppins(.regular, size: 11))
                        .italic()
                        .foregroundStyle(ServicePlanPalette.textMuted)
                }
                .padding(.top, 8)

                // Footer.
                footer
                    .padding(.top, 4)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 10))
                    .foregroundStyle(ServicePlanPalette.textMuted)
                (
                    Text("Based on ")
                        .font(.poppins(.regular, size: 10))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                    + Text("manufacturer recommendations")
                        .font(.poppins(.semibold, size: 10))
                        .foregroundStyle(ServicePlanPalette.textMuted)
                )
                Spacer()
            }

            if !sources.isEmpty {
                Rectangle()
                    .fill(ServicePlanPalette.borderDefault)
                    .frame(height: 0.75)
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sources) { source in
                        sourceRow(source)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ServicePlanPalette.neutralChipBg)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ServicePlanPalette.borderDefault, lineWidth: 0.75)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func sourceRow(_ source: OEMScheduleSource) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(source.type.uppercased())
                .font(.poppins(.bold, size: 8))
                .kerning(0.3)
                .foregroundStyle(ServicePlanPalette.teal)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(ServicePlanPalette.tealTintChip)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            if let url = source.linkURL {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text(source.name)
                            .font(.poppins(.medium, size: 10))
                            .foregroundStyle(ServicePlanPalette.teal)
                            .underline()
                            .multilineTextAlignment(.leading)
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 9))
                            .foregroundStyle(ServicePlanPalette.teal)
                    }
                }
            } else {
                Text(source.name)
                    .font(.poppins(.medium, size: 10))
                    .foregroundStyle(ServicePlanPalette.textBody)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Labels

    private var completedRangeLabel: String {
        guard let first = plan.completedMilestones.first,
              let last = plan.completedMilestones.last else { return "" }
        if first.mileage == last.mileage {
            return "(\(first.mileage.formatted()) mi)"
        }
        return "(\(first.mileage.formatted())–\(last.mileage.formatted()) mi)"
    }

    private var compactRangeLabel: String {
        guard let first = compactUpcoming.first,
              let last = compactUpcoming.last else { return "" }
        return "(\(first.mileage.formatted())–\(last.mileage.formatted()) mi)"
    }
}

// MARK: - Preview

#Preview("Service Plan — 2024 Audi A4") {
    let demoVehicle = Vehicle(
        id: UUID(),
        year: 2024,
        make: "Audi",
        model: "A4",
        trim: "Premium",
        mileage: 11_000,
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
    let demoSources: [OEMScheduleSource] = [
        OEMScheduleSource(
            type: "official",
            name: "2024 Audi A4 Warranty & Maintenance Guide",
            url: "https://www.audiusa.com/us/web/en/owners/maintenance.html"
        ),
        OEMScheduleSource(
            type: "dealer",
            name: "Audi Caldwell A4 Maintenance Schedule",
            url: "https://www.audicaldwell.com/"
        ),
        OEMScheduleSource(
            type: "specialist",
            name: "CarEdge Audi A4 Maintenance Schedule",
            url: "https://caredge.com/audi/a4/maintenance"
        )
    ]
    return NavigationStack {
        ServicePlanView(
            vehicle: demoVehicle,
            oemItems: ServicePlanBuilder.demoItems,
            sources: demoSources
        )
    }
}
