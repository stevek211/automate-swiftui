import Foundation
import AmplitudeSwift
import AmplitudeSessionReplay
import AmplitudeSwiftSessionReplayPlugin

// MARK: - Analytics Events

enum AnalyticsEvent {
    case appLaunched
    case onboardingViewed
    case signUpMethodSelected(method: String)   // "apple", "google", "email"
    case emailSignUpStarted
    case emailSignUpCompleted
    case emailSignUpFailed(reason: String)
    case logInCompleted(method: String)         // "apple", "google", "email"
    case onboardingVehicleAdded
    case onboardingCompleted
    case perplexityCallSucceeded(durationMs: Int)
    case perplexityCallFailed(reason: String)
    case oemScheduleDecodeFailed(
        errorType: String,        // "keyNotFound" | "typeMismatch" | "valueNotFound" | "dataCorrupted" | "unknown"
        path: String,             // e.g. "maintenance_items.0.interval_miles"
        details: String,          // human-readable debug description
        vehicleKey: String,       // e.g. "2020_jeep_wrangler_unlimited-sport"
        jsonSample: String        // first 500 chars of the raw JSON
    )

    var name: String {
        switch self {
        case .appLaunched:              return "App Launched"
        case .onboardingViewed:         return "Onboarding Viewed"
        case .signUpMethodSelected:     return "Sign Up Method Selected"
        case .emailSignUpStarted:       return "Email Sign Up Started"
        case .emailSignUpCompleted:     return "Email Sign Up Completed"
        case .emailSignUpFailed:        return "Email Sign Up Failed"
        case .logInCompleted:           return "Log In Completed"
        case .onboardingVehicleAdded:       return "Onboarding Vehicle Added"
        case .onboardingCompleted:          return "Onboarding Completed"
        case .perplexityCallSucceeded:      return "Perplexity Call Succeeded"
        case .perplexityCallFailed:         return "Perplexity Call Failed"
        case .oemScheduleDecodeFailed:      return "OEM Schedule Decode Failed"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .signUpMethodSelected(let method):
            return ["method": method]
        case .emailSignUpFailed(let reason):
            return ["reason": reason]
        case .logInCompleted(let method):
            return ["method": method]
        case .perplexityCallSucceeded(let durationMs):
            return ["duration_ms": durationMs]
        case .perplexityCallFailed(let reason):
            return ["reason": reason]
        case .oemScheduleDecodeFailed(let errorType, let path, let details, let vehicleKey, let jsonSample):
            return [
                "error_type": errorType,
                "path": path,
                "details": details,
                "vehicle_key": vehicleKey,
                "json_sample": jsonSample
            ]
        default:
            return [:]
        }
    }
}

// MARK: - Analytics Service

final class AnalyticsService {
    static let shared = AnalyticsService()

    // Set to true when ready to start tracking (e.g. before launch or testing)
    private let isEnabled = false

    private let amplitude: Amplitude?

    private init() {
        if PreviewSupport.isRunningForPreviews {
            amplitude = nil
            return
        }

        // Note: Configuration.autocapture has an internal setter in the current SDK; configuring it here causes "setter is inaccessible". We'll use the SDK defaults and Session Replay plugin.
        let config = Configuration(apiKey: "23322c9e2767bc2cfa022461c08d1e67")
        let amplitude = Amplitude(configuration: config)
        amplitude.add(plugin: AmplitudeSwiftSessionReplayPlugin(sampleRate: 1.0))
        self.amplitude = amplitude
        print("📊 [Analytics] Amplitude + Session Replay initialized (enabled: \(isEnabled))")
    }

    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        let props = event.properties.isEmpty ? nil : event.properties
        amplitude?.track(eventType: event.name, eventProperties: props)
    }

    func identify(userId: String) {
        guard isEnabled else { return }
        amplitude?.setUserId(userId: userId)
    }

    func reset() {
        guard isEnabled else { return }
        amplitude?.reset()
    }
}
