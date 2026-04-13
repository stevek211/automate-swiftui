import SwiftUI
import Charts

struct QuoteValidatorView: View {
    @State private var repairName = ""
    @State private var priceText = ""
    @State private var result: QuoteResult?
    @State private var showResult = false

    var repairSuggestions: [String] {
        guard !repairName.isEmpty, !showResult else { return [] }
        return ReferenceData.repairPrices
            .map(\.name)
            .filter { $0.localizedCaseInsensitiveContains(repairName) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if !showResult {
                    inputView
                } else if let result {
                    resultView(result)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color.agBackground)
    }

    // MARK: – Input View
    var inputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Quote Validator")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.agForeground)
                Text("Check if your repair quote is fair")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.agMutedForeground)
            }

            // Repair name
            VStack(alignment: .leading, spacing: 6) {
                Text("REPAIR NAME")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.agMutedForeground)

                ZStack(alignment: .topLeading) {
                    TextField("e.g. Oil Change, Brake Pads", text: $repairName)
                        .font(.system(size: 16))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.agCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.agBorder, lineWidth: 1)
                        )

                    // Suggestions dropdown
                    if !repairSuggestions.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(repairSuggestions, id: \.self) { suggestion in
                                Button {
                                    repairName = suggestion
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.agForeground)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                if suggestion != repairSuggestions.last {
                                    Divider()
                                }
                            }
                        }
                        .background(Color.agCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.agBorder, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        .offset(y: 48)
                        .zIndex(10)
                    }
                }
            }

            // Quoted price
            VStack(alignment: .leading, spacing: 6) {
                Text("QUOTED PRICE")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.agMutedForeground)

                HStack {
                    Text("$")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.agMutedForeground)
                    TextField("0", text: $priceText)
                        .font(.system(size: 16))
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.agCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.agBorder, lineWidth: 1)
                )
            }
            .padding(.top, repairSuggestions.isEmpty ? 0 : 40)

            // Submit button
            Button {
                guard let price = Double(priceText), !repairName.isEmpty else { return }
                withAnimation(.spring(duration: 0.3)) {
                    result = ReferenceData.validateQuote(repairName: repairName, price: price)
                    showResult = true
                }
            } label: {
                Text("Check My Quote")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.agPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(repairName.isEmpty || priceText.isEmpty)
            .opacity(repairName.isEmpty || priceText.isEmpty ? 0.4 : 1)

            // Upsell warnings
            if let repair = ReferenceData.repairPrices.first(where: { $0.name.lowercased() == repairName.lowercased() }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agAccent)
                        Text("Common upsells to watch for")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.agForeground)
                    }

                    ForEach(repair.upsellWarnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(Color.agAccent)
                            Text(warning)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.agMutedForeground)
                        }
                    }
                }
                .padding(14)
                .background(Color.agAccent10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.agAccent.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: – Result View
    func resultView(_ result: QuoteResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Back button
            Button {
                withAnimation { showResult = false }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12))
                    Text("Back")
                        .font(.system(size: 14))
                }
                .foregroundStyle(Color.agMutedForeground)
            }
            .buttonStyle(.plain)

            // Trust Score
            VStack(spacing: 4) {
                Text("Trust Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.agMutedForeground)
                Text("\(result.trustScore)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(trustColor(result.assessment))
                Text(result.assessment.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(trustColor(result.assessment))
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )

            // Price comparison
            VStack(alignment: .leading, spacing: 12) {
                Text("Price Comparison")
                    .font(.system(size: 14, weight: .semibold))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Quote")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                        Text("$\(Int(result.inputPrice))")
                            .font(.system(size: 20, weight: .bold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Fair Range")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                        Text(result.fairPriceDisplay)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.agSuccess)
                    }
                }

                // Price bar
                GeometryReader { geo in
                    let width = geo.size.width
                    let maxPrice = result.fairPriceHigh * 1.5
                    let fairStart = result.fairPriceLow / maxPrice * width
                    let fairEnd = result.fairPriceHigh / maxPrice * width
                    let userPos = min(result.inputPrice / maxPrice * width, width - 2)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.agMuted)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.agSuccess.opacity(0.3))
                            .frame(width: fairEnd - fairStart, height: 12)
                            .offset(x: fairStart)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.agForeground)
                            .frame(width: 3, height: 12)
                            .offset(x: userPos)
                    }
                }
                .frame(height: 12)
            }
            .padding(16)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )

            // Upsell warnings
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agAccent)
                    Text("Watch out for upsells")
                        .font(.system(size: 14, weight: .semibold))
                }

                ForEach(result.upsellWarnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(Color.agAccent)
                        Text(warning)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
            }
            .padding(14)
            .background(Color.agAccent10)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.agAccent.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Questions to ask
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.agPrimary)
                    Text("Questions to ask your mechanic")
                        .font(.system(size: 14, weight: .semibold))
                }

                let questions = [
                    "Can I see the old parts when you're done?",
                    "Is this repair urgent or can it wait?",
                    "Do you offer a warranty on this work?",
                ]
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.agPrimary)
                        Text(question)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
            }
            .padding(16)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )
        }
    }

    func trustColor(_ assessment: PriceAssessment) -> Color {
        switch assessment {
        case .great: return .agSuccess
        case .fair: return .agSuccess
        case .suspicious: return .agWarning
        case .overpriced: return .agDestructive
        }
    }
}

#Preview {
    NavigationStack {
        QuoteValidatorView()
    }
}
