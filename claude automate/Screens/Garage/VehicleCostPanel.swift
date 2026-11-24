import SwiftUI

// MARK: - Cost range filter

enum CostRange: String, CaseIterable, Identifiable {
    case allTime = "All time"
    case last12Months = "Last 12 months"
    case thisYear = "This year"

    var id: String { rawValue }

    func includes(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        switch self {
        case .allTime:
            return true
        case .last12Months:
            guard let start = calendar.date(byAdding: .month, value: -12, to: now) else { return true }
            return date >= start
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

// MARK: - Visit (one shop, one day, one or more services)

struct ServiceVisit: Identifiable {
    let id: String
    let date: Date
    let shop: String
    let mileage: Int
    let services: [ServiceLog]

    var total: Double { services.reduce(0) { $0 + $1.cost } }

    /// Groups service logs into visits: same calendar day and same shop.
    static func group(_ logs: [ServiceLog], calendar: Calendar = .current) -> [ServiceVisit] {
        let buckets = Dictionary(grouping: logs) { log -> String in
            let day = calendar.startOfDay(for: log.date).timeIntervalSince1970
            let shop = (log.shop?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 } ?? "Service"
            return "\(day)|\(shop)"
        }
        return buckets.map { key, logs in
            let first = logs[0]
            let shop = (first.shop?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 } ?? "Service"
            return ServiceVisit(
                id: key,
                date: first.date,
                shop: shop,
                mileage: logs.map(\.mileage).max() ?? first.mileage,
                services: logs.sorted { $0.cost > $1.cost }
            )
        }
        .sorted { $0.date > $1.date }
    }
}

// MARK: - Cost panel (Maintenance → Cost)

struct VehicleCostPanel: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let logs: [ServiceLog]
    @Binding var range: CostRange
    var onLog: () -> Void
    var onEditVisit: ((ServiceVisit) -> Void)? = nil

    private var filtered: [ServiceLog] { logs.filter { range.includes($0.date) } }
    private var visits: [ServiceVisit] { ServiceVisit.group(filtered) }
    private var total: Double { filtered.reduce(0) { $0 + $1.cost } }
    private var paidCount: Int { filtered.filter { $0.cost > 0 }.count }
    private var averagePaid: Double { paidCount == 0 ? 0 : total / Double(paidCount) }

    var body: some View {
        if logs.isEmpty {
            FirstServiceEmptyState(onLog: onLog)
        } else {
            populated
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            summary

            Text("Services")
                .font(.quicksandScaled(.semibold, size: 15))
                .foregroundStyle(Color.vdInk)

            if visits.isEmpty {
                emptyState
            } else {
                VStack(spacing: 7.2) {
                    ForEach(visits) { visit in
                        ServiceVisitCard(visit: visit, onEdit: onEditVisit.map { edit in { edit(visit) } })
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Service costs")
                .font(.quicksandScaled(.semibold, size: 17))
                .foregroundStyle(Color.vdInk)

            Spacer()

            HStack(spacing: 8) {
                Menu {
                    Picker("Range", selection: $range) {
                        ForEach(CostRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image("vehicle-icon-filter")
                            .renderingMode(.template)
                            .foregroundStyle(Color.vdMuted)
                            .frame(width: 16, height: 16)
                        Text(range.rawValue)
                            .font(.quicksandScaled(.medium, size: 13))
                            .foregroundStyle(Color.vdMuted)
                    }
                    .padding(.horizontal, 8.625)
                    .frame(height: 32)
                    .background(Color.vdTrack, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.vdBorder, lineWidth: 1))
                }
                .accessibilityLabel("Date range, \(range.rawValue)")

                Button(action: onLog) {
                    HStack(spacing: 4) {
                        Text("+")
                        Text("Log")
                    }
                    .font(.quicksandScaled(.semibold, size: 13))
                    .foregroundStyle(Color.vdAccent)
                    .padding(.horizontal, 4)
                    .frame(height: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log a service")
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total recorded spend")
                .font(.quicksandScaled(.regular, size: 12))
                .foregroundStyle(Color.vdMuted)

            Text(Self.currency(total))
                .font(.quicksandScaled(.semibold, size: 30))
                .foregroundStyle(Color.vdInk)

            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    stat(value: Self.currency(averagePaid), label: "Average per paid record")
                    stat(value: "\(paidCount) of \(filtered.count)", label: "Records with a cost")
                }
                .padding(.top, 12)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    stat(value: Self.currency(averagePaid), label: "Average per paid record")
                    stat(value: "\(paidCount) of \(filtered.count)", label: "Records with a cost")
                        .padding(.leading, 12.625)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(Color.vdBorder).frame(width: 0.625)
                        }
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20.625)
        .overlay(alignment: .top) { Rectangle().fill(Color.vdBorder).frame(height: 0.625) }
        .overlay(alignment: .bottom) { Rectangle().fill(Color.vdBorder).frame(height: 0.625) }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.quicksandScaled(.semibold, size: 15))
                .foregroundStyle(Color.vdInk)
            Text(label)
                .font(.quicksandScaled(.regular, size: 13))
                .foregroundStyle(Color.vdMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("No services in this range")
                .font(.quicksandScaled(.semibold, size: 15))
                .foregroundStyle(Color.vdInk)
            Button(action: onLog) {
                Text("Log a service")
                    .font(.quicksandScaled(.medium, size: 13))
                    .foregroundStyle(Color.vdAccent)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.vdSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.vdBorder, lineWidth: 1))
    }

    static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }
}

// MARK: - First-run empty state (Figma 582:182)

/// Shown before any service is logged: a prompt to log the first service,
/// then a faded preview of what the cost summary and a visit card will look like.
private struct FirstServiceEmptyState: View {
    var onLog: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image("vehicle-icon-receipt")
                    .renderingMode(.template)
                    .foregroundStyle(Color.vdAccent)
                    .frame(width: 28, height: 28)
                    .frame(width: 56, height: 56)
                    .background(Color.vdAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)

                VStack(spacing: 4) {
                    Text("No service costs yet")
                        .font(.quicksandScaled(.semibold, size: 17))
                        .foregroundStyle(Color.vdInk)
                    Text("Log your first oil change or repair and we'll start tracking what this car costs you.")
                        .font(.quicksandScaled(.regular, size: 13))
                        .foregroundStyle(Color.vdMuted)
                        .lineSpacing(3)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

                Button(action: onLog) {
                    HStack(spacing: 6) {
                        Text("+")
                        Text("Log first service")
                    }
                    .font(.quicksandScaled(.medium, size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(minHeight: 40)
                    .background(Color.vdAccent, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log first service")
            }
            .padding(.horizontal, 16)

            preview
        }
        .padding(.top, 8)
    }

    /// Faded sample of the populated layout; decorative only.
    private var preview: some View {
        VStack(spacing: 7.6) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total recorded spend")
                    .font(.quicksandScaled(.regular, size: 12))
                    .foregroundStyle(Color.vdMuted)
                Text(VehicleCostPanel.currency(0))
                    .font(.quicksandScaled(.semibold, size: 30))
                    .foregroundStyle(Color.vdInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16.625)
            .overlay(alignment: .top) { Rectangle().fill(Color.vdBorder).frame(height: 0.625) }
            .overlay(alignment: .bottom) { Rectangle().fill(Color.vdBorder).frame(height: 0.625) }

            HStack(spacing: 11.6) {
                DateBadge(date: Self.sampleDate)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your first visit")
                        .font(.quicksandScaled(.semibold, size: 15))
                        .foregroundStyle(Color.vdInk)
                    Text("Oil Change · Tire Rotation")
                        .font(.quicksandScaled(.regular, size: 13))
                        .foregroundStyle(Color.vdMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(VehicleCostPanel.currency(97))
                    .font(.quicksandScaled(.bold, size: 16))
                    .foregroundStyle(Color.vdInk)
            }
            .padding(12)
            .background(Color.vdSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.vdBorder, lineWidth: 1))

            Text("This is what your service visits will look like")
                .font(.quicksandScaled(.regular, size: 12))
                .foregroundStyle(Color.vdMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .opacity(0.4)
        .accessibilityHidden(true)
    }

    private static let sampleDate: Date = {
        var parts = DateComponents()
        parts.year = Calendar.current.component(.year, from: .now)
        parts.month = 3
        parts.day = 12
        return Calendar.current.date(from: parts) ?? .now
    }()
}

// MARK: - Visit card

private struct ServiceVisitCard: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let visit: ServiceVisit
    var onEdit: (() -> Void)?
    @State private var isExpanded = false

    /// Visits with more services than this show the first few plus a "Show N more" toggle.
    private static let collapsedLimit = 3

    private var hiddenCount: Int { max(visit.services.count - Self.collapsedLimit, 0) }

    private var shownServices: ArraySlice<ServiceLog> {
        isExpanded ? visit.services[...] : visit.services.prefix(Self.collapsedLimit)
    }

    /// Side by side normally; stacked when accessibility text sizes leave no room.
    private var rowLayout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 11.6))
    }

    var body: some View {
        VStack(spacing: 0) {
            rowLayout {
                DateBadge(date: visit.date)

                VStack(alignment: .leading, spacing: 0) {
                    Text(visit.shop)
                        .font(.quicksandScaled(.semibold, size: 15))
                        .foregroundStyle(Color.vdInk)
                    Text("\(visit.mileage.formatted()) mi")
                        .font(.quicksandScaled(.regular, size: 13))
                        .foregroundStyle(Color.vdMuted)
                        .padding(.top, 2)
                    Text(visit.services.count == 1 ? "1 service" : "\(visit.services.count) services")
                        .font(.quicksandScaled(.regular, size: 13))
                        .foregroundStyle(Color.vdMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 2.38) {
                    Text(VehicleCostPanel.currency(visit.total))
                        .font(.quicksandScaled(.bold, size: 16))
                        .foregroundStyle(Color.vdInk)
                    if let onEdit {
                        Button(action: onEdit) {
                            Text("Edit visit")
                                .font(.quicksandScaled(.medium, size: 13))
                                .foregroundStyle(Color.vdAccent)
                                .padding(.horizontal, 6)
                                .frame(minHeight: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit visit at \(visit.shop)")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 11.62)
            .padding(.bottom, 7.62)

            VStack(spacing: 0) {
                ForEach(shownServices) { service in
                    (typeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                        : AnyLayout(HStackLayout())) {
                        Text(service.name)
                            .font(.quicksandScaled(.regular, size: 14))
                            .foregroundStyle(Color.vdInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(VehicleCostPanel.currency(service.cost))
                            .font(.quicksandScaled(.medium, size: 14))
                            .foregroundStyle(Color.vdMuted)
                    }
                    .frame(minHeight: 20)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                if hiddenCount > 0 {
                    showMoreButton
                }
            }
            .overlay(alignment: .top) {
                Line()
                    .stroke(Color.vdBorder, style: StrokeStyle(lineWidth: 0.625, dash: [3, 3]))
                    .frame(height: 0.625)
            }
        }
        .padding(1)
        .background(Color.vdSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.vdBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var showMoreButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 4) {
                Text(isExpanded
                     ? "Show fewer services"
                     : "Show \(hiddenCount) more \(hiddenCount == 1 ? "service" : "services")")
                    .font(.quicksandScaled(.medium, size: 13))
                    .foregroundStyle(Color.vdInk)
                Image("settings-icon-chevron-down")
                    .renderingMode(.template)
                    .foregroundStyle(Color.vdInk)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 28)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }
}

private struct DateBadge: View {
    let date: Date
    @ScaledMetric(relativeTo: .footnote) private var width: CGFloat = 50

    var body: some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.month(.abbreviated)))
                .font(.quicksandScaled(.bold, size: 11))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.vdAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background(Color.vdAccent.opacity(0.15))
            Text(date.formatted(.dateTime.day(.twoDigits)))
                .font(.quicksandScaled(.semibold, size: 18))
                .foregroundStyle(Color.vdInk)
                .frame(minHeight: 22)
            Text(date.formatted(.dateTime.year()))
                .font(.quicksandScaled(.regular, size: 11))
                .foregroundStyle(Color.vdMuted)
                .frame(minHeight: 14)
                .padding(.bottom, 2)
        }
        .padding(1)
        .frame(width: width)
        .background(Color.vdTrack.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.vdBorder, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(date.formatted(date: .long, time: .omitted))
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}
