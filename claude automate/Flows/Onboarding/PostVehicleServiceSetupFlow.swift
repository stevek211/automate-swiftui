import SwiftUI
import Lottie

/// After adding a vehicle, asks 5 baseline service questions (oil, tires,
/// brakes, air filter, transmission) to build initial maintenance history.
struct PostVehicleServiceSetupFlow: View {
    @Environment(AppState.self) private var appState
    let vehicle: Vehicle
    let onFinish: () -> Void

    @State private var currentScreen = -1  // -1 = entry; 0...4 = questions
    @State private var answers: [String: String] = [:]
    @State private var oilMileage = ""
    @State private var isAnalyzing = false
    @State private var navigationDirection = 1

    private let screens = ["oil", "tire", "brake", "air", "transmission"]

    private var questionAnimation: Animation {
        .easeInOut(duration: 0.28)
    }

    private var questionTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: navigationDirection >= 0 ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: navigationDirection >= 0 ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    var body: some View {
        Group {
            if currentScreen == -1 {
                entryScreen
                    .id("entry")
                    .transition(questionTransition)
            } else {
                questionFlow
                    .id(currentScreen)
                    .transition(questionTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .keyboardDoneBar()
        .background(Color.agBackground.ignoresSafeArea())
        .allowsHitTesting(!isAnalyzing)
        .overlay { if isAnalyzing { analyzingOverlay } }
    }

    // MARK: - Entry Screen

    private var entryScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 44)

            Spacer().frame(height: 24)  // instead of open-ended Spacer()

            ZStack {
                Image("car-illustration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .scaleEffect(x: 1.75, y: 2.0, anchor: .center) // visual width only
            }
            .frame(height: 180)              // fixed layout space
                .frame(maxWidth: .infinity)   // full width
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                Text("\(vehicle.year, format: .number.grouping(.never)) \(vehicle.make) \(vehicle.model)")
                    .font(Font.custom("Quicksand", size: 14))
                    .foregroundStyle(Color.theme.mutedText)
                    .padding(.bottom, 12)

                Text("Let's protect you\nat the shop")
                    .font(Font.custom("Quicksand", size: 28).weight(.medium))
                    .foregroundStyle(Color.theme.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
                    .padding(.bottom, 20)

                Text("Tell us what's been done and we'll tell you exactly what your \(vehicle.model) needs")
                    .font(Font.custom("Quicksand", size: 16))
                    .foregroundStyle(Color.theme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 28)

                HStack(spacing: 6) {
                    Circle().fill(Color.theme.secondary).frame(width: 10, height: 10)
                    ForEach(0..<4, id: \.self) { _ in
                        Circle().fill(Color.black.opacity(0.1)).frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 28)

                VStack(spacing: 12) {
                    Button {
                        navigationDirection = 1
                        withAnimation(questionAnimation) { currentScreen = 0 }
                    } label: {
                        Text("Get started — takes 60 seconds")
                            .font(Font.custom("Quicksand", size: 14).weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.theme.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.black.opacity(0.25), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
            .offset(y: -18)
        }
    }

    // MARK: - Question Flow

    @ViewBuilder
    private var questionFlow: some View {
        if screens[currentScreen] == "oil" {
            oilQuestionFlow
        } else if screens[currentScreen] == "tire" {
            tireQuestionFlow
        } else {
            defaultQuestionFlow
        }
    }

    private var defaultQuestionFlow: some View {
        VStack(spacing: 0) {
            questionHeader
            ScrollView {
                VStack(spacing: 20) {
                    heroIcon(for: screens[currentScreen])
                        .padding(.top, 38)
                    Text(questionTitle(for: screens[currentScreen]))
                        .font(.quicksandScaled(.medium, size: 22))
                        .foregroundStyle(Color.agForeground)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 20)
                    Text(questionSubtitle(for: screens[currentScreen]))
                        .font(.quicksandScaled(.regular, size: 14))
                        .foregroundStyle(Color.agMutedForeground)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 20)

                    questionBody(for: screens[currentScreen])
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                .padding(.bottom, 120)
            }
            bottomCTA
        }
    }

    private var oilQuestionFlow: some View {
        VStack(spacing: 0) {
            questionHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    oilIllustrationPlaceholder
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 38)

                    VStack(alignment: .center, spacing: 12) {
                        Text(questionTitle(for: "oil"))
                            .font(Font.custom("Quicksand", size: 22).weight(.medium))
                            .foregroundStyle(Color.theme.ink)
                            .multilineTextAlignment(.center)
                            .frame(width: 324, alignment: .top)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(questionSubtitle(for: "oil"))
                            .font(Font.custom("Quicksand", size: 14))
                            .foregroundStyle(Color.theme.mutedText)
                            .multilineTextAlignment(.center)
                            .frame(width: 367, alignment: .top)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    triStateRow(key: "oil", options: [("yes", "Yes"), ("no", "No"), ("unsure", "Not sure")])

                    if answers["oil"] == "yes" {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("How recent?")
                            optionList([
                                ("within-3m", "Within the last 3 months", "You're in great shape"),
                                ("3-6m", "3–6 months ago", "Might be coming up soon"),
                                ("6-12m", "6–12 months ago", "Probably getting close for a change")
                            ], key: "oilRecency")
                        }

                        mileageInputField(
                            label: "Mileage at last oil change (optional)",
                            context: vehicleMileageSummary,
                            placeholder: "e.g., 45,000",
                            text: $oilMileage
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            bottomCTA
        }
        .background(Color.white)
    }

    private var tireQuestionFlow: some View {
        VStack(spacing: 0) {
            questionHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    tireIllustrationPlaceholder
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 38)

                    VStack(alignment: .center, spacing: 12) {
                        Text(questionTitle(for: "tire"))
                            .font(Font.custom("Quicksand", size: 22).weight(.medium))
                            .foregroundStyle(Color.theme.ink)
                            .multilineTextAlignment(.center)
                            .frame(width: 354, alignment: .top)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(questionSubtitle(for: "tire"))
                            .font(Font.custom("Quicksand", size: 14))
                            .foregroundStyle(Color.theme.mutedText)
                            .multilineTextAlignment(.center)
                            .frame(width: 354, alignment: .top)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    optionList([
                        ("within-6m", "Within the last 6 months", "Right on schedule"),
                        ("6-12m", "6–12 months ago", "Probably due soon"),
                        ("over-1y", "More than a year ago", "Likely overdue"),
                        ("unknown", "I'm not sure", "We'll keep an eye on it")
                    ], key: "tire")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            bottomCTA
        }
        .background(Color.white)
    }

    private var questionHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                HStack {
                    Button {
                        navigationDirection = -1
                        withAnimation(questionAnimation) {
                            if currentScreen == 0 { currentScreen = -1 }
                            else { currentScreen -= 1 }
                        }
                    } label: {
                        Text("← Back")
                            .font(.quicksandScaled(.medium, size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        skipAndAdvance()
                    } label: {
                        Text("Skip")
                            .font(.quicksandScaled(.medium, size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    .buttonStyle(.plain)
                }

                Text("\(currentScreen + 1) of \(screens.count)")
                    .font(.quicksandScaled(.regular, size: 12))
                    .foregroundStyle(Color.agMutedForeground)
            }

            // Segmented progress bar — 5 pills
            HStack(spacing: 6) {
                ForEach(0..<screens.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentScreen ? Color.theme.secondary : Color.agForeground.opacity(0.04))
                        .frame(height: 6)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Per-screen content

    private func heroIconName(for screen: String) -> String {
        switch screen {
        case "oil": return "drop.fill"
        case "tire": return "tire"
        case "brake": return "circle.hexagongrid.fill"
        case "air": return "wind"
        case "transmission": return "gearshape.2.fill"
        default: return "wrench.and.screwdriver.fill"
        }
    }

    private func heroIcon(for screen: String) -> some View {
        Group {
            if screen == "brake" {
                Image("Brake")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 83, height: 83)
            } else if screen == "air" {
                Image("AirFilter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 83, height: 83)
            } else if screen == "transmission" {
                Image("Transmission")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 83, height: 83)
            } else {
                Image(systemName: heroIconName(for: screen))
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Color.agPrimary)
                    .frame(height: 80)
            }
        }
    }

    private var oilIllustrationPlaceholder: some View {
        Image("OilChange")
            .resizable()
            .scaledToFit()
            .frame(width: 83, height: 83)
    }

    private var tireIllustrationPlaceholder: some View {
        Image("Tire")
            .resizable()
            .scaledToFit()
            .frame(width: 83, height: 83)
    }

    private func questionTitle(for screen: String) -> String {
        switch screen {
        case "oil": return "Has your oil been changed in the last year?"
        case "tire": return "When did you last rotate your tires?"
        case "brake": return "Have your brakes been serviced?"
        case "air": return "When was your air filter replaced?"
        case "transmission": return "Has your transmission fluid ever been serviced or changed?"
        default: return ""
        }
    }

    private func questionSubtitle(for screen: String) -> String {
        switch screen {
        case "oil": return "Check the sticker on your windshield, your dash reminder, or your last service receipt."
        case "tire": return "Usually done every 5,000–7,500 miles, depending on your car"
        case "brake": return "Pads, rotors, or fluid — any brake work counts"
        case "air": return "Engine or cabin — either one counts here"
        case "transmission": return "This depends on your vehicle and transmission type. If you're not sure, that's okay!"
        default: return ""
        }
    }

    @ViewBuilder
    private func questionBody(for screen: String) -> some View {
        switch screen {
        case "oil":
            VStack(spacing: 16) {
                triStateRow(key: "oil", options: [("yes", "Yes"), ("no", "No"), ("unsure", "Not sure")])

                if answers["oil"] == "yes" {
                    sectionHeader("HOW RECENT?")
                    optionList([
                        ("within-3m", "Within the last 3 months", "You're in great shape"),
                        ("3-6m", "3–6 months ago", "Might be coming up soon"),
                        ("6-12m", "6–12 months ago", "Probably getting close for a change")
                    ], key: "oilRecency")
                }

                mileageInputField(
                    label: "Mileage at last oil change (optional)",
                    context: vehicleMileageSummary,
                    placeholder: "e.g., 45,000",
                    text: $oilMileage
                )
            }
        case "tire":
            optionList([
                ("within-6m", "Within the last 6 months", "Right on schedule"),
                ("6-12m", "6–12 months ago", "Probably due soon"),
                ("over-1y", "More than a year ago", "Likely overdue"),
                ("unknown", "I'm not sure", "We'll keep an eye on it")
            ], key: "tire")
        case "brake":
            optionList([
                ("within-1y", "Within the last year", "Should be in good shape"),
                ("1-2y", "1–2 years ago", "Worth inspecting soon"),
                ("over-2y", "More than 2 years ago", "Overdue for inspection"),
                ("unknown", "I'm not sure", "We'll flag it")
            ], key: "brake")
        case "air":
            optionList([
                ("within-1y", "Within the last year", "Likely still good"),
                ("1-2y", "1–2 years ago", "Probably due"),
                ("over-2y", "More than 2 years / never", "Definitely time"),
                ("unknown", "I'm not sure", "We'll estimate for you")
            ], key: "air")
        case "transmission":
            optionList([
                ("recent", "Yes, recently", "Likely still good"),
                ("not-recent", "Yes, but not recently", "May need attention"),
                ("no", "No / not that I know of", "Worth checking"),
                ("unknown", "I'm not sure", "We'll factor in mileage")
            ], key: "transmission")
        default:
            EmptyView()
        }
    }

    // MARK: - Reusable bits

    private func triStateRow(key: String, options: [(id: String, label: String)]) -> some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.id) { opt in
                let selected = answers[key] == opt.id
                Button {
                    answers[key] = opt.id
                    if key == "oil" && opt.id != "yes" {
                        answers["oilRecency"] = nil
                    }
                } label: {
                    Text(opt.label)
                        .font(Font.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(selected ? Color.theme.secondary : Color.theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 49)
                        .background(selected ? Color.theme.secondary.opacity(0.1) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(selected ? Color.theme.secondary.opacity(0.3) : Color.black.opacity(0.1), lineWidth: 0.5)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .shadow(color: .black.opacity(0.21), radius: 3, x: 0, y: 2)
    }

    private func optionList(_ options: [(id: String, title: String, subtitle: String)],
                            key: String) -> some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.id) { opt in
                let selected = answers[key] == opt.id
                Button {
                    answers[key] = opt.id
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(opt.title)
                                .font(Font.custom("Quicksand", size: 14).weight(.medium))
                                .foregroundStyle(Color.theme.ink)
                            Text(opt.subtitle)
                                .font(Font.custom("Quicksand", size: 12).weight(.medium))
                                .foregroundStyle(Color.theme.mutedText)
                        }
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.agPrimary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 67)
                    .background(selected ? Color.theme.secondary.opacity(0.08) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? Color.theme.secondary.opacity(0.4) : Color.black.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Font.custom("Quicksand", size: 13))
            .tracking(0.3)
            .foregroundStyle(Color.theme.mutedText)
            .textCase(.none)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var vehicleMileageSummary: String {
        "\(vehicle.displayName) • \(vehicle.mileage.formatted()) miles"
    }

    private func mileageInputField(
        label: String,
        context: String? = nil,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Font.custom("Quicksand", size: 14).weight(.medium))
                .foregroundStyle(Color.theme.ink)
            if let context {
                Text(context)
                    .font(Font.custom("Quicksand", size: 11))
                    .underline()
                    .foregroundStyle(Color.theme.mutedText)
            }
            let exceedsOdometer = mileageExceedsOdometer(text.wrappedValue)
            TextField(placeholder, text: text)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let formatted = formattedMileageInput(newValue)
                    if formatted != newValue {
                        text.wrappedValue = formatted
                    }
                }
                .font(Font.custom("Quicksand", size: 16))
                .keyboardType(.numberPad)
                .padding(.horizontal, 16)
                .frame(height: 49)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            exceedsOdometer ? Color.agWarning : Color.black.opacity(0.2),
                            lineWidth: exceedsOdometer ? 1 : 0.5
                        )
                )

            // A past service can't be at more miles than the car has now — usually a typo.
            if exceedsOdometer {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12, weight: .medium))
                    Text("Are you sure? That's higher than your car's current mileage of \(vehicle.mileage.formatted()) miles. Check the number on your receipt or sticker.")
                        .font(Font.custom("Quicksand", size: 12))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Color.agWarning)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: mileageExceedsOdometer(text.wrappedValue))
    }

    /// True when a "mileage at last service" entry is above the car's current odometer.
    private func mileageExceedsOdometer(_ text: String) -> Bool {
        guard let value = Int(text.filter(\.isNumber)) else { return false }
        return value > vehicle.mileage
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 0) {
            Divider().background(Color.agBorder)
            Button {
                advance()
            } label: {
                HStack(spacing: 8) {
                    Text(currentScreen == screens.count - 1 ? "See my service plan" : "Continue")
                        .font(Font.custom("Quicksand", size: 14).weight(.medium))
                        .lineSpacing(20)
                        .foregroundStyle(.black)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.theme.secondary)
                        .shadow(color: .black, radius: 0, x: 4, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.black, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!canAdvance || isAnalyzing)
            .opacity(canAdvance && !isAnalyzing ? 1 : 0.3)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.white.opacity(0.95))
    }

    private var canAdvance: Bool {
        guard !isAnalyzing else { return false }
        let screen = screens[currentScreen]
        if screen == "oil", answers["oil"] == "yes" {
            return answers["oilRecency"] != nil
        }
        return answers[screen] != nil
    }

    // MARK: - Navigation + analyzing

    private func advance() {
        guard !isAnalyzing else { return }
        if currentScreen < screens.count - 1 {
            navigationDirection = 1
            withAnimation(questionAnimation) { currentScreen += 1 }
        } else {
            finishSetup()
        }
    }

    private func skipAndAdvance() {
        answers[screens[currentScreen]] = "unknown"
        advance()
    }

    private var analyzingOverlay: some View {
        ZStack {
            Color.agBackground.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 12) {
                LottieView(animation: .named("carr"))
                    .playing(loopMode: .loop)
                    .frame(width: 220, height: 220)
                VStack(spacing: 10) {
                    Text("Analyzing your vehicle's\nmaintenance needs...")
                        .font(.quicksand(.semibold, size: 16))
                        .foregroundStyle(Color.agForeground)
                        .multilineTextAlignment(.center)
                    Text("This takes a few seconds")
                        .font(.quicksand(.regular, size: 13))
                        .foregroundStyle(Color.agMutedForeground)
                }
                .padding(.top, -28)
            }
        }
    }

    private func finishSetup() {
        guard !isAnalyzing else { return }
        let entries = buildBaselineEntries()
        let submittedAnswers = answers
        let submittedOilMileage = oilMileage
        isAnalyzing = true
        Task {
            do {
                let result = try await AIMaintenanceAnalyzer.analyze(
                    vehicle: vehicle,
                    answers: submittedAnswers,
                    oilMileage: submittedOilMileage,
                    brakeMileage: ""
                )
                await MainActor.run {
                    appState.storeBaselineServiceLogsWithAI(
                        entries,
                        items: result.items,
                        schedule: result.schedule,
                        sources: result.sources,
                        for: vehicle.id
                    )
                    isAnalyzing = false
                    onFinish()
                }
            } catch {
                await MainActor.run {
                    appState.storeBaselineServiceLogs(entries, for: vehicle.id)
                    isAnalyzing = false
                    onFinish()
                }
            }
        }
    }

    // MARK: - Build baseline entries

    private func buildBaselineEntries() -> [ServiceLog] {
        let now = Date()
        let currentMileage = vehicle.mileage
        let annualMiles = estimateAnnualMiles()
        var entries: [ServiceLog] = []

        // Oil — recency depends on tri-state + detailed recency bucket
        let oilRecency = answers["oilRecency"] ?? (answers["oil"] == "no" ? "over-1y" : "unknown")
        let oilDate = estimateDate(answer: oilRecency, mapping: [
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
            notes: answers["oil"] == "unsure" ? "Status: unknown" : "Status: known",
            category: .oil
        ))

        // Tire rotation
        let tireAnswer = answers["tire"] ?? "unknown"
        let tireDate = estimateDate(answer: tireAnswer, mapping: [
            "within-6m": -3, "6-12m": -9, "over-1y": -15
        ], from: now)
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

        // Brakes
        let brakeAnswer = answers["brake"] ?? "unknown"
        let brakeDate = estimateDate(answer: brakeAnswer, mapping: [
            "within-1y": -6, "1-2y": -18, "over-2y": -30
        ], from: now)
        let brakeMonthsAgo = Calendar.current.dateComponents([.month], from: brakeDate, to: now).month ?? 0
        let brakeMiles = max(1000, currentMileage - (annualMiles * brakeMonthsAgo / 12))
        entries.append(ServiceLog(
            id: UUID(), vehicleId: vehicle.id,
            name: "[Baseline] Brake Service",
            date: brakeDate, mileage: brakeMiles, cost: 0,
            shop: "AutoGuard Baseline",
            notes: brakeAnswer == "unknown" ? "Status: unknown" : "Status: known",
            category: .brakes
        ))

        // Air filter
        let airAnswer = answers["air"] ?? "unknown"
        let airDate = estimateDate(answer: airAnswer, mapping: [
            "within-1y": -6, "1-2y": -18, "over-2y": -30
        ], from: now)
        let airMonthsAgo = Calendar.current.dateComponents([.month], from: airDate, to: now).month ?? 0
        let airMiles = max(1000, currentMileage - (annualMiles * airMonthsAgo / 12))
        entries.append(ServiceLog(
            id: UUID(), vehicleId: vehicle.id,
            name: "[Baseline] Air Filter",
            date: airDate, mileage: airMiles, cost: 0,
            shop: "AutoGuard Baseline",
            notes: airAnswer == "unknown" ? "Status: unknown" : "Status: known",
            category: .filters
        ))

        // Transmission
        let transAnswer = answers["transmission"] ?? "unknown"
        let transDate = estimateDate(answer: transAnswer, mapping: [
            "recent": -6, "not-recent": -36, "no": -60
        ], from: now)
        let transMonthsAgo = Calendar.current.dateComponents([.month], from: transDate, to: now).month ?? 0
        let transMiles = max(1000, currentMileage - (annualMiles * transMonthsAgo / 12))
        entries.append(ServiceLog(
            id: UUID(), vehicleId: vehicle.id,
            name: "[Baseline] Transmission Fluid",
            date: transDate, mileage: transMiles, cost: 0,
            shop: "AutoGuard Baseline",
            notes: transAnswer == "unknown" ? "Status: unknown" : "Status: known",
            category: .transmission
        ))

        return entries
    }

    /// Uses the shared mapping so it matches the ids the sign-up options actually save
    /// (the old switch checked ids like "under-5k" that were never stored).
    private func estimateAnnualMiles() -> Int {
        MileageReminder.annualMiles(for: vehicle)
    }

    private func estimateDate(answer: String, mapping: [String: Int], from date: Date) -> Date {
        let monthsBack = mapping[answer] ?? -12
        return Calendar.current.date(byAdding: .month, value: monthsBack, to: date) ?? date
    }
}

#Preview {
    PostVehicleServiceSetupFlow(
        vehicle: Vehicle(
            id: UUID(), year: 2026, make: "Audi", model: "A4",
            trim: nil, mileage: 47230, color: "White", vin: nil,
            healthScore: 85, lastService: nil, nextService: nil,
            maintenanceCurrent: 0, maintenanceTotal: 0,
            usage: ["Daily commute"], conditions: ["City traffic"],
            annualMileage: "10k-15k"
        ),
        onFinish: {}
    )
    .environment(AppState())
}
