import Foundation

// Some manufacturers (Honda/Acura "Maintenance Minder", GM "Oil Life Monitor", BMW CBS…)
// don't publish fixed mileages for most services — the dashboard decides. The AI schedule
// then comes back with recurring items that have NO interval. Without a number those items
// can't be placed on the timeline or given a status, so we fall back to typical intervals.

enum TypicalServiceIntervals {
    /// A typical interval in miles for a recurring service the OEM gave no fixed mileage for.
    static func miles(name: String, category: String, action: ServiceAction) -> Int {
        let n = name.lowercased()

        // Name-specific first.
        if n.contains("timing belt") { return 100_000 }
        if n.contains("spark plug") { return 100_000 }
        if n.contains("coolant") { return 60_000 }
        if n.contains("brake fluid") { return 30_000 }
        if n.contains("transmission") || n.contains("transfer") || n.contains("differential") { return 30_000 }
        if n.contains("air cleaner") || n.contains("air filter") || n.contains("cabin")
            || n.contains("pollen") { return 30_000 }
        if n.contains("drive belt") || n.contains("serpentine") { return 30_000 }
        if n.contains("repair kit") { return 15_000 }
        if n.contains("oil") && !n.contains("fluid") { return 7_500 }
        if action == .rotate || (n.contains("tire") && n.contains("rotat")) { return 7_500 }

        switch category {
        case "oil": return 7_500
        case "tires": return action == .inspect ? 15_000 : 7_500
        case "filters": return 30_000
        case "transmission": return 30_000
        case "cooling": return 60_000
        case "ignition": return 100_000
        case "belts": return 30_000
        case "fluids": return action == .replace ? 30_000 : 15_000
        default: return 15_000 // general inspections (brakes, suspension, exhaust, lines…)
        }
    }
}

extension OEMScheduleItemInput {
    /// True when the OEM gave no repeat mileage and we fall back to a typical one.
    var usesTypicalInterval: Bool {
        guard type != .oneTime else { return false }
        return (intervalMiles ?? 0) <= 0 && (subsequentIntervalMiles ?? 0) <= 0
    }

    /// The repeat interval in miles: the OEM's if present, otherwise a typical one.
    /// nil for one-time items.
    var resolvedIntervalMiles: Int? {
        switch type {
        case .oneTime:
            return nil
        case .recurring:
            if let interval = intervalMiles ?? subsequentIntervalMiles, interval > 0 { return interval }
        case .recurringAfterFirst:
            if let interval = subsequentIntervalMiles ?? intervalMiles, interval > 0 { return interval }
        }
        return TypicalServiceIntervals.miles(name: name, category: category, action: action)
    }

    /// Mileage of the first scheduled occurrence.
    var resolvedFirstDueMiles: Int? {
        if let first = firstDueMiles, first > 0 { return first }
        if type == .oneTime { return intervalMiles }
        return resolvedIntervalMiles
    }

    /// The scheduled occurrences either side of `mileage`:
    /// `previous` is the latest one at or below it, `next` the first one above it.
    func occurrences(around mileage: Int) -> (previous: Int?, next: Int?) {
        guard let first = resolvedFirstDueMiles else { return (nil, nil) }
        if mileage < first { return (nil, first) }
        guard let interval = resolvedIntervalMiles, interval > 0 else { return (first, nil) }
        let steps = (mileage - first) / interval
        let previous = first + steps * interval
        return (previous, previous + interval)
    }
}

enum MaintenanceScheduleMath {
    struct Result {
        let status: MaintenanceStatus
        let dueMileage: Int?
        let description: String
    }

    /// Status for an item when we have no record of when it was last done.
    ///
    /// - `historyUnknown`: the user was asked about this kind of service and said
    ///   they don't know / it hasn't been done. Then a scheduled occurrence that has
    ///   already passed counts as needing attention.
    /// - Otherwise we assume past occurrences were done and look at the next one.
    static func scheduleStatus(
        for item: OEMScheduleItemInput,
        currentMileage: Int,
        historyUnknown: Bool
    ) -> Result {
        let (previous, next) = item.occurrences(around: currentMileage)
        let typicalNote = item.usesTypicalInterval
            ? " Your car has no fixed mileage for this, so this is a typical interval — follow your dashboard reminder if it comes up sooner."
            : ""

        if historyUnknown, let previous {
            return Result(
                status: .overdue,
                dueMileage: nil,
                description: "No record of this being done. It was scheduled at around \(previous.formatted()) miles — worth getting it checked." + typicalNote
            )
        }

        if let next {
            let remaining = next - currentMileage
            let interval = item.resolvedIntervalMiles ?? next
            let threshold = max(500, Int(Double(interval) * 0.15))
            let status: MaintenanceStatus = remaining <= threshold ? .dueSoon : .onTrack
            return Result(
                status: status,
                dueMileage: next,
                description: "Next due at around \(next.formatted()) miles (\(remaining.formatted()) miles to go)." + typicalNote
            )
        }

        if let previous {
            return Result(
                status: .onTrack,
                dueMileage: nil,
                description: "Scheduled once, at around \(previous.formatted()) miles. Nothing further is scheduled."
            )
        }

        return Result(
            status: .onTrack,
            dueMileage: nil,
            description: "No fixed schedule for this. Follow your car's dashboard maintenance reminder."
        )
    }
}
