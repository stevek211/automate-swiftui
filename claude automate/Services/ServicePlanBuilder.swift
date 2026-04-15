import Foundation

/// Builds a milestone-based ServicePlan from a flat list of OEM maintenance
/// items with recurrence metadata (matching the Perplexity Sonar JSON schema).
///
/// The UI expects milestones at regular 5,000-mile intervals from 5,000 up to
/// `maxMileage` (default 100,000). Each milestone holds whichever items come
/// due at that mileage — derived from each item's recurrence pattern.
enum ServicePlanBuilder {

    /// Default step between milestones — matches the Figma design.
    static let milestoneStep = 5_000
    static let defaultMaxMileage = 150_000

    static func build(
        items: [OEMScheduleItemInput],
        currentMileage: Int,
        maxMileage: Int = defaultMaxMileage,
        severeDuty: Bool = false,
        monthsPerMile: Double = 12.0 / 10_000.0 // rough default: 10k mi/year
    ) -> ServicePlan {

        let step = milestoneStep
        var bucketed: [Int: [ServicePlanItem]] = [:]

        for input in items {
            // Skip severe-only items if user isn't in severe-duty conditions.
            if input.severeOnly && !severeDuty { continue }

            let dueMileages = dueMileages(for: input, upTo: maxMileage)
            for mi in dueMileages {
                // Snap to the nearest 5k bucket (most OEM intervals are 5k-aligned
                // already, but this guards against stray 7,500/15k rows).
                let bucket = roundToNearestMultiple(mi, step: step, max: maxMileage)
                bucketed[bucket, default: []].append(
                    ServicePlanItem(name: input.name, action: input.action, category: input.category)
                )
            }
        }

        let milestones: [ServicePlanMilestone] = stride(from: step, through: maxMileage, by: step)
            .compactMap { mileage in
                guard let items = bucketed[mileage], !items.isEmpty else { return nil }
                let months = Int((Double(mileage) * monthsPerMile).rounded())
                return ServicePlanMilestone(mileage: mileage, months: months, items: items)
            }

        return ServicePlan(milestones: milestones, currentMileage: currentMileage)
    }

    // MARK: - Private

    /// Returns every mileage at which this item is due, up to `maxMileage`.
    private static func dueMileages(for item: OEMScheduleItemInput, upTo maxMileage: Int) -> [Int] {
        switch item.type {
        case .oneTime:
            if let first = item.firstDueMiles, first <= maxMileage { return [first] }
            return []

        case .recurring:
            let interval = item.intervalMiles ?? item.subsequentIntervalMiles ?? 0
            guard interval > 0 else { return [] }
            let first = item.firstDueMiles ?? interval
            return Array(stride(from: first, through: maxMileage, by: interval))

        case .recurringAfterFirst:
            guard let first = item.firstDueMiles, first <= maxMileage else { return [] }
            let interval = item.subsequentIntervalMiles ?? item.intervalMiles ?? 0
            guard interval > 0 else { return [first] }
            var dues: [Int] = [first]
            var cursor = first + interval
            while cursor <= maxMileage {
                dues.append(cursor)
                cursor += interval
            }
            return dues
        }
    }

    /// Snap `value` to the nearest multiple of `step`, clamped to `[step, max]`.
    private static func roundToNearestMultiple(_ value: Int, step: Int, max: Int) -> Int {
        let rounded = Int((Double(value) / Double(step)).rounded()) * step
        return Swift.max(step, Swift.min(max, rounded))
    }
}

// MARK: - Demo data for previews

extension ServicePlanBuilder {
    /// Sample items approximating a 2024 Audi A4 OEM schedule — used for
    /// SwiftUI previews and the demo screen entry point.
    static var demoItems: [OEMScheduleItemInput] {
        [
            .make(name: "Oil & Filter Change", action: "replace", category: "oil",
                  type: "recurring", intervalMiles: 10_000, firstDueMiles: 5_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Tire Rotation", action: "perform", category: "tires",
                  type: "recurring", intervalMiles: 10_000, firstDueMiles: 10_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Cabin Air Filter", action: "replace", category: "filters",
                  type: "recurring", intervalMiles: 20_000, firstDueMiles: 15_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Brake Inspection", action: "inspect", category: "brakes",
                  type: "recurring", intervalMiles: 20_000, firstDueMiles: 20_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Brake Fluid", action: "replace", category: "fluids",
                  type: "recurring", intervalMiles: 40_000, firstDueMiles: 40_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Spark Plugs", action: "replace", category: "ignition",
                  type: "recurring", intervalMiles: 40_000, firstDueMiles: 40_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Engine Air Filter", action: "replace", category: "filters",
                  type: "recurring", intervalMiles: 30_000, firstDueMiles: 30_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Transmission Fluid", action: "replace", category: "transmission",
                  type: "recurring", intervalMiles: 60_000, firstDueMiles: 60_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Engine Coolant", action: "replace", category: "cooling",
                  type: "recurring_after_first", intervalMiles: nil, firstDueMiles: 100_000,
                  subsequentIntervalMiles: 50_000),
            .make(name: "PCV Valve", action: "inspect", category: "engine",
                  type: "one_time", intervalMiles: nil, firstDueMiles: 90_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Timing Belt", action: "replace", category: "belts",
                  type: "one_time", intervalMiles: nil, firstDueMiles: 75_000,
                  subsequentIntervalMiles: nil),
            .make(name: "Drive Belt", action: "inspect", category: "belts",
                  type: "recurring", intervalMiles: 30_000, firstDueMiles: 60_000,
                  subsequentIntervalMiles: nil),
        ]
    }
}
