import Foundation
import UserNotifications

/// Shared rules for how fresh a car's odometer reading is, and what it probably reads now.
enum MileageReminder {
    /// After this many days without an update, Home asks the user to confirm the odometer
    /// and a reminder notification fires.
    static let staleAfterDays = 28

    /// Typical miles per year for the sign-up choice (ids from VehicleDatabase.annualMileageOptions).
    static func annualMiles(for vehicle: Vehicle) -> Int {
        switch vehicle.annualMileage {
        case "under5k": return 4_000
        case "5k-10k": return 7_500
        case "10k-15k": return 12_500
        case "15k-25k": return 20_000
        case "25k+": return 28_000
        default: return 12_000
        }
    }

    static func daysSinceUpdate(_ vehicle: Vehicle, now: Date = .now) -> Int? {
        guard let updated = vehicle.mileageUpdatedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: updated, to: now).day
    }

    /// Stale after `staleAfterDays`, or when we don't know when it was last updated.
    static func isStale(_ vehicle: Vehicle, now: Date = .now) -> Bool {
        guard let days = daysSinceUpdate(vehicle, now: now) else { return true }
        return days >= staleAfterDays
    }

    /// Last reading plus the typical daily distance since then, rounded to the nearest 100.
    /// nil when we don't know when the last reading was taken.
    static func estimatedMileage(for vehicle: Vehicle, now: Date = .now) -> Int? {
        guard let updated = vehicle.mileageUpdatedAt else { return nil }
        let days = max(0, now.timeIntervalSince(updated) / 86_400)
        let driven = Double(annualMiles(for: vehicle)) / 365 * days
        let rounded = Int(((Double(vehicle.mileage) + driven) / 100).rounded()) * 100
        return max(vehicle.mileage, rounded)
    }

    // MARK: - Debug launch flags

    #if DEBUG
    /// `-mileageAgeDays N`: backdate demo cars' last update by N days (UI testing).
    static var debugAgeDays: Int? { intArgument("-mileageAgeDays") }
    /// `-mileageReminderSeconds N`: fire reminders N seconds after scheduling (UI testing).
    static var debugReminderSeconds: Int? { intArgument("-mileageReminderSeconds") }

    private static func intArgument(_ flag: String) -> Int? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return nil }
        return Int(args[index + 1])
    }
    #endif
}

/// Schedules one local "update your odometer" notification per car, 28 days after
/// its last mileage update at 9:30am.
enum MileageReminderScheduler {
    static let identifierPrefix = "mileage-reminder-"
    static let vehicleIdKey = "vehicleId"
    private static let reminderHour = 9
    private static let reminderMinute = 30

    /// Asks for permission once (only while undecided), then schedules reminders.
    static func requestPermissionIfNeeded(thenSchedule vehicles: [Vehicle]) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                reschedule(for: vehicles)
                return
            }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                reschedule(for: vehicles)
            }
        }
    }

    /// Replaces all pending odometer reminders with one per vehicle.
    static func reschedule(for vehicles: [Vehicle], now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let old = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: old)

            for vehicle in vehicles {
                guard let trigger = trigger(for: vehicle, now: now) else { continue }
                let content = UNMutableNotificationContent()
                content.title = "How many miles on your \(vehicle.model)?"
                content.body = "Update your odometer to keep your service plan accurate."
                content.sound = .default
                content.userInfo = [vehicleIdKey: vehicle.id.uuidString]
                center.add(UNNotificationRequest(
                    identifier: identifierPrefix + vehicle.id.uuidString,
                    content: content,
                    trigger: trigger
                ))
            }
        }
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let ids = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func trigger(for vehicle: Vehicle, now: Date) -> UNNotificationTrigger? {
        #if DEBUG
        if let seconds = MileageReminder.debugReminderSeconds {
            return UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        }
        #endif
        let calendar = Calendar.current
        let base = vehicle.mileageUpdatedAt ?? now
        guard let dueDay = calendar.date(byAdding: .day, value: MileageReminder.staleAfterDays, to: base),
              var fireDate = calendar.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: dueDay)
        else { return nil }

        // Already overdue: remind at the next 9:30am instead.
        if fireDate <= now,
           let today = calendar.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: now) {
            fireDate = today > now ? today : calendar.date(byAdding: .day, value: 1, to: today) ?? today
        }
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
}

/// Routes taps on odometer reminders back into the app, and shows them while the app is open.
@Observable
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()

    /// Set when the user taps a reminder; RootView consumes it and opens the mileage sheet.
    var pendingMileageVehicleId: UUID?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        if let raw = info[MileageReminderScheduler.vehicleIdKey] as? String, let id = UUID(uuidString: raw) {
            DispatchQueue.main.async { self.pendingMileageVehicleId = id }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
