import SwiftUI

struct NoiseDiagnosisView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedLocation: String?
    @State private var selectedTiming: String?
    @State private var selectedSound: String?
    @State private var showResult = false

    var diagnosis: NoiseDiagnosis? {
        guard let location = selectedLocation,
              let timing = selectedTiming,
              let sound = selectedSound else { return nil }
        return appState.noiseDiagnoses.first {
            $0.location == location && $0.timing == timing && $0.sound == sound
        } ?? NoiseDiagnosis(
            id: UUID(), location: location, timing: timing, sound: sound,
            diagnosis: "Possible Issue Detected", severity: .medium,
            estimatedCost: "$100–$500",
            description: "Based on your description, this could be several things. We recommend having a mechanic inspect the \(location.lowercased()) area, especially when \(timing.lowercased())."
        )
    }

    var currentStep: Int {
        if selectedLocation == nil { return 1 }
        if selectedTiming == nil { return 2 }
        if selectedSound == nil { return 3 }
        return 4
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AGSpacing.xl) {
                // Progress
                HStack(spacing: AGSpacing.sm) {
                    ForEach(1...3, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color.agPrimary : Color.agMuted)
                            .frame(height: 4)
                    }
                }

                if !showResult {
                    // Step 1: Location
                    if currentStep >= 1 {
                        questionSection(
                            title: "Where is the noise coming from?",
                            options: ReferenceData.noiseLocations,
                            selected: $selectedLocation
                        )
                    }

                    // Step 2: Timing
                    if currentStep >= 2 {
                        questionSection(
                            title: "When does it happen?",
                            options: ReferenceData.noiseTimings,
                            selected: $selectedTiming
                        )
                    }

                    // Step 3: Sound
                    if currentStep >= 3 {
                        questionSection(
                            title: "What does it sound like?",
                            options: ReferenceData.noiseSounds,
                            selected: $selectedSound
                        )
                    }

                    if currentStep == 4 {
                        Button {
                            withAnimation { showResult = true }
                        } label: {
                            Text("Get Diagnosis")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                } else if let diagnosis {
                    // Result
                    VStack(alignment: .leading, spacing: AGSpacing.xl) {
                        HStack(spacing: AGSpacing.lg) {
                            Image(systemName: "ear.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.severityColor(diagnosis.severity))
                                .frame(width: 56, height: 56)
                                .background(Color.severityColor(diagnosis.severity).opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: AGSpacing.xs) {
                                Text(diagnosis.diagnosis)
                                    .font(.poppinsTitle2)
                                StatusPill(text: diagnosis.severity.rawValue + " Severity", color: Color.severityColor(diagnosis.severity))
                            }
                        }

                        Text(diagnosis.description)
                            .font(.poppinsBody)
                            .foregroundStyle(Color.agMutedForeground)

                        HStack {
                            Text("Estimated Repair Cost")
                                .font(.poppinsHeadline)
                            Spacer()
                            Text(diagnosis.estimatedCost)
                                .font(.poppinsTitle3)
                                .foregroundStyle(Color.agPrimary)
                        }
                        .cardStyle()

                        Button {
                            withAnimation {
                                selectedLocation = nil
                                selectedTiming = nil
                                selectedSound = nil
                                showResult = false
                            }
                        } label: {
                            Text("Start Over")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
            .padding(AGSpacing.screenPadding)
        }
        .appBackground()
        .navigationTitle("Noise Diagnosis")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(duration: 0.3), value: currentStep)
    }

    func questionSection(title: String, options: [String], selected: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: AGSpacing.md) {
            Text(title)
                .font(.poppinsTitle3)
                .foregroundStyle(Color.agForeground)

            FlowLayout(spacing: AGSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation { selected.wrappedValue = option }
                    } label: {
                        Text(option)
                            .font(.poppinsCallout)
                            .foregroundStyle(selected.wrappedValue == option ? .white : Color.agForeground)
                            .padding(.horizontal, AGSpacing.lg)
                            .padding(.vertical, AGSpacing.md)
                            .background(selected.wrappedValue == option ? Color.agPrimary : Color.agCard)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(selected.wrappedValue == option ? Color.clear : Color.agBorder)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NoiseDiagnosisView()
    }
    .environment(AppState())
}
