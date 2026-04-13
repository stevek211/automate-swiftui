import SwiftUI

/// After adding a vehicle during onboarding, asks 5 baseline service questions
/// (oil, tires, brakes, air filter, battery) to build initial maintenance history.
/// Matches React's PostVehicleServiceSetupFlow.tsx
struct PostVehicleServiceSetupFlow: View {
    @Environment(AppState.self) private var appState
    let vehicle: Vehicle
    let onFinish: () -> Void

    @State private var currentScreen = 0
    @State private var answers: [String: String] = [:]
    @State private var oilMileage = ""
    @State private var brakeMileage = ""
    @State private var isAnalyzing = false

    private let screens = ["oil", "tire", "brake", "air", "battery"]

    private var progress: Double {
        Double(currentScreen + 1) / Double(screens.count)
    }

    var body: some View {
        let _ = print("🚗 [ServiceSetup] Showing for \(vehicle.displayName) — screen \(currentScreen)/\(screens.count), isAnalyzing=\(isAnalyzing)")
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    if currentScreen > 0 {
                        Button {
                            withAnimation(.spring(duration: 0.2)) { currentScreen -= 1 }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14))
                                Text("Back")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(Color.agMutedForeground)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Text("Service History")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.agForeground)
                    Spacer()
                    // Spacer for symmetry
                    Color.clear.frame(width: 50, height: 32)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.agMuted)
                            .frame(height: 4)
                        Capsule()
                            .fill(Color.agPrimary)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 4)

                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(Color.agBackground)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Info card on first screen
                    if currentScreen == 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Let's build your service baseline")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.agForeground)
                            Text("Answer a few quick questions so we can track your maintenance schedule. Don't worry if you're not sure — estimates are fine!")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.agMutedForeground)
                        }
                        .padding(16)
                        .background(Color.agPrimary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.agPrimary.opacity(0.1), lineWidth: 1)
                        )
                    }

                    // Question
                    questionView(for: screens[currentScreen])
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }

            // Bottom CTA
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Button {
                        skipAndAdvance()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.agMutedForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.agMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        advance()
                    } label: {
                        Text(currentScreen == screens.count - 1 ? "Finish Setup" : "Next")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.agPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(answers[screens[currentScreen]] == nil)
                    .opacity(answers[screens[currentScreen]] != nil ? 1 : 0.3)
                }
            }
            .padding(16)
            .background(Color.agBackground.opacity(0.95))
        }
        .background(Color.agBackground)
        .allowsHitTesting(!isAnalyzing)
        .overlay {
            if isAnalyzing {
                ZStack {
                    Color.agBackground.opacity(0.92)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(Color.agPrimary)
                        Text("Analyzing your vehicle's\nmaintenance needs...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.agForeground)
                            .multilineTextAlignment(.center)
                        Text("This takes a few seconds")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
            }
        }
    }

    // MARK: - Questions

    @ViewBuilder
    private func questionView(for screen: String) -> some View {
        switch screen {
        case "oil":
            questionSection(
                icon: "drop.fill",
                iconColor: Color.agPrimary,
                title: "Last Oil Change",
                subtitle: "When was the last time you changed the oil?",
                options: [
                    ("within-3m", "Within the last 3 months"),
                    ("3-6m", "3–6 months ago"),
                    ("6-12m", "6–12 months ago"),
                    ("over-1y", "Over a year ago"),
                ],
                key: "oil"
            )

            // Optional mileage
            VStack(alignment: .leading, spacing: 8) {
                Text("Estimated mileage at last oil change (optional)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.agMutedForeground)
                TextField("e.g. 44,000", text: $oilMileage)
                    .font(.system(size: 16, weight: .medium))
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(Color.agCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.agBorder, lineWidth: 1)
                    )
            }

        case "tire":
            questionSection(
                icon: "tire",
                iconColor: .gray,
                title: "Last Tire Rotation",
                subtitle: "When were your tires last rotated?",
                options: [
                    ("within-6m", "Within the last 6 months"),
                    ("6-12m", "6–12 months ago"),
                    ("over-1y", "Over a year ago"),
                    ("with-oil", "Done with my last oil change"),
                    ("unknown", "Don't know"),
                ],
                key: "tire"
            )

        case "brake":
            questionSection(
                icon: "brake.signal",
                iconColor: Color.agDestructive,
                title: "Last Brake Pad Replacement",
                subtitle: "When were your brake pads last replaced?",
                options: [
                    ("within-1y", "Within the last year"),
                    ("1-2y", "1–2 years ago"),
                    ("2-3y", "2–3 years ago"),
                    ("over-3y", "Over 3 years ago / not sure"),
                ],
                key: "brake"
            )

            // Optional mileage
            VStack(alignment: .leading, spacing: 8) {
                Text("Estimated mileage at last brake replacement (optional)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.agMutedForeground)
                TextField("e.g. 38,000", text: $brakeMileage)
                    .font(.system(size: 16, weight: .medium))
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(Color.agCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.agBorder, lineWidth: 1)
                    )
            }

        case "air":
            questionSection(
                icon: "air.purifier.fill",
                iconColor: Color.agSuccess,
                title: "Engine Air Filter",
                subtitle: "Has the engine air filter been replaced?",
                options: [
                    ("within-2y", "Yes — within the last 2 years"),
                    ("unknown", "Not that I know of"),
                    ("at-service", "It came up at my last service"),
                ],
                key: "air"
            )

        case "battery":
            questionSection(
                icon: "battery.100percent",
                iconColor: Color.agAccent,
                title: "Battery",
                subtitle: "When was your car battery last replaced?",
                options: [
                    ("recent", "Replaced in 2025 or 2026"),
                    ("2023-2024", "Replaced in 2023 or 2024"),
                    ("before-2023", "Replaced before 2023"),
                    ("original", "Original battery / not sure"),
                ],
                key: "battery"
            )

        default:
            EmptyView()
        }
    }

    private func questionSection(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        options: [(id: String, label: String)],
        key: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with icon
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.agForeground)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.agMutedForeground)
                }
            }

            // Options
            VStack(spacing: 6) {
                ForEach(options, id: \.id) { option in
                    let selected = answers[key] == option.id
                    Button {
                        answers[key] = option.id
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.agForeground)
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.agPrimary)
                            }
                        }
                        .padding(12)
                        .background(selected ? Color.agPrimary.opacity(0.1) : Color.agMuted.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selected ? Color.agPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        if currentScreen < screens.count - 1 {
            withAnimation(.spring(duration: 0.2)) { currentScreen += 1 }
        } else {
            finishSetup()
        }
    }

    private func skipAndAdvance() {
        answers[screens[currentScreen]] = "unknown"
        advance()
    }

    private func finishSetup() {
        let entries = buildBaselineEntries()
        isAnalyzing = true

        Task {
            do {
                let items = try await AIMaintenanceAnalyzer.analyze(
                    vehicle: vehicle,
                    answers: answers,
                    oilMileage: oilMileage,
                    brakeMileage: brakeMileage
                )
                await MainActor.run {
                    appState.storeBaselineServiceLogsWithAI(entries, items: items, for: vehicle.id)
                    isAnalyzing = false
                    onFinish()
                }
            } catch {
                print("🔧 [AIAnalyzer] ❌ Failed: \(error.localizedDescription) — using fallback")
                await MainActor.run {
                    appState.storeBaselineServiceLogs(entries, for: vehicle.id)
                    isAnalyzing = false
                    onFinish()
                }
            }
        }
    }

    // MARK: - Build Baseline Entries

    private func buildBaselineEntries() -> [ServiceLog] {
        let now = Date()
        let currentMileage = vehicle.mileage
        // Estimate annual mileage (default 12,000)
        let annualMiles = estimateAnnualMiles()

        var entries: [ServiceLog] = []

        // Oil Change
        let oilAnswer = answers["oil"] ?? "unknown"
        let oilDate = estimateDate(answer: oilAnswer, mapping: [
            "within-3m": -2, "3-6m": -5, "6-12m": -9, "over-1y": -15
        ], from: now)
        let oilMiles: Int
        if let parsed = Int(oilMileage.replacingOccurrences(of: ",", with: "")), parsed > 0 {
            oilMiles = parsed
        } else {
            let monthsAgo = Calendar.current.dateComponents([.month], from: oilDate, to: now).month ?? 0
            oilMiles = max(1000, currentMileage - (annualMiles * monthsAgo / 12))
        }
        entries.append(ServiceLog(
            id: UUID(), vehicleId: vehicle.id,
            name: "[Baseline] Oil Change",
            date: oilDate, mileage: oilMiles, cost: 0,
            shop: "AutoGuard Baseline",
            notes: oilAnswer == "unknown" ? "Status: unknown" : "Status: known",
            category: .oil
        ))

        // Tire Rotation
        let tireAnswer = answers["tire"] ?? "unknown"
        let tireDate: Date
        if tireAnswer == "with-oil" {
            tireDate = oilDate
        } else {
            tireDate = estimateDate(answer: tireAnswer, mapping: [
                "within-6m": -3, "6-12m": -9, "over-1y": -15
            ], from: now)
        }
        let tireMonthsAgo = Calendar.current.dateComponents([.month], from: tireDate, to: now).month ?? 0
        let tireMiles = max(1000, currentMileage - (annualMiles * tireMonthsAgo / 12))
        entries.append(ServiceLog(
            id: UUID(), vehicleId: vehicle.id,
            name: "[Baseline] Tire Rotation",
            date: tireDate, mileage: tireMiles, cost: 0,
            shop: "AutoGuard Baseline",
            notes: tireAnswer == "unknown" ? "Status: unknown" : "Status: known",
            category: .tires
        ))

        // Brake Pads
        let brakeAnswer = answers["brake"] ?? "unknown"
        let brakeDate = estimateDate(answer: brakeAnswer, mapping: [
            "within-1y": -6, "1-2y": -18, "2-3y": -30, "over-3y": -42
        ], from: now)
        let brakeMiles: Int
        if let parsed = Int(brakeMileage.replacingOccurrences(of: ",", with: "")), parsed > 0 {
            brakeMiles = parsed
        } else {
            let monthsAgo = Calendar.current.dateComponents([.month], from: brakeDate, to: now).month ?? 0
            brakeMiles = max(1000, currentMileage - (annualMiles * monthsAgo / 12))
        }
        entries.append(ServiceLog(
            id: UUID(), vehicleId: vehicle.id,
            name: "[Baseline] Brake Pads",
            date: brakeDate, mileage: brakeMiles, cost: 0,
            shop: "AutoGuard Baseline",
            notes: brakeAnswer == "over-3y" ? "Status: unknown" : "Status: known",
            category: .brakes
        ))

        // Air Filter
        let airAnswer = answers["air"] ?? "unknown"
        let airDate = estimateDate(answer: airAnswer, mapping: [
            "within-2y": -12, "at-service": -6
        ], from: now)
        let airMonthsAgo = Calendar.current.dateComponents([.month], from: airDate, to: now).month ?? 0
        let airMiles = max(1000, currentMileage - (annualMiles * airMonthsAgo / 12))
        entries.append(ServiceLog(
            id: UUID(), vehicleId: vehicle.id,
            name: "[Baseline] Engine Air Filter",
            date: airDate, mileage: airMiles, cost: 0,
            shop: "AutoGuard Baseline",
            notes: airAnswer == "unknown" ? "Status: unknown" : "Status: known",
            category: .filters
        ))

        // Battery
        let batteryAnswer = answers["battery"] ?? "unknown"
        let batteryDate = estimateDate(answer: batteryAnswer, mapping: [
            "recent": -6, "2023-2024": -24, "before-2023": -42
        ], from: now)
        let batteryMonthsAgo = Calendar.current.dateComponents([.month], from: batteryDate, to: now).month ?? 0
        let batteryMiles = max(1000, currentMileage - (annualMiles * batteryMonthsAgo / 12))
        entries.append(ServiceLog(
            id: UUID(), vehicleId: vehicle.id,
            name: "[Baseline] Battery",
            date: batteryDate, mileage: batteryMiles, cost: 0,
            shop: "AutoGuard Baseline",
            notes: batteryAnswer == "original" ? "Status: unknown" : "Status: known",
            category: .battery
        ))

        return entries
    }

    private func estimateAnnualMiles() -> Int {
        switch vehicle.annualMileage {
        case "under-5k": return 4000
        case "5k-10k": return 7500
        case "10k-15k": return 12500
        case "15k-20k": return 17500
        case "over-20k": return 25000
        default: return 12000
        }
    }

    private func estimateDate(answer: String, mapping: [String: Int], from date: Date) -> Date {
        let monthsBack = mapping[answer] ?? -12
        return Calendar.current.date(byAdding: .month, value: monthsBack, to: date) ?? date
    }
}

#Preview {
    PostVehicleServiceSetupFlow(
        vehicle: Vehicle(
            id: UUID(), year: 2019, make: "Honda", model: "CR-V",
            trim: "EX-L", mileage: 47230, color: "White", vin: nil,
            healthScore: 85, lastService: nil, nextService: nil,
            maintenanceCurrent: 0, maintenanceTotal: 0,
            usage: ["Daily commute"], conditions: ["City driving"],
            annualMileage: "10k-15k"
        ),
        onFinish: {}
    )
    .environment(AppState())
}
