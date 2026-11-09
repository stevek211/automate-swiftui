import SwiftUI

/// Onboarding entry point for the Add Vehicle flow. Renders the shared
/// AddVehicleFlowView with onboarding-specific config (no dismiss, custom CTA).
struct OnboardingAddVehicleView: View {
    let onVehicleAdded: () -> Void

    var body: some View {
        AddVehicleFlowView(
            allowDismiss: false,
            primaryCTA: "Add Vehicle & Get Started",
            onComplete: onVehicleAdded
        )
    }
}

#Preview {
    OnboardingAddVehicleView(onVehicleAdded: {})
        .environment(AppState())
        .environment(AuthState())
}
