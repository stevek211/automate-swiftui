import SwiftUI

struct OnboardingGarageIntroView: View {
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geo in
            let horizontalPadding: CGFloat = 24
            let imageWidth = min(geo.size.width - 31, 362)
            let imageHeight = min(geo.size.height * 0.385, 328)
            let imageTop = min(max(geo.safeAreaInsets.top + 24, geo.size.height * 0.063), 54)
            let contentWidth = min(geo.size.width - (horizontalPadding * 2), 354)

            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    Image(uiImage: .garageIntroIllustration)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFill()
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                        .padding(.top, imageTop)

                    Text("LET'S BUILD YOUR GARAGE")
                        .font(.custom("Quicksand-SemiBold", size: 16))
                        .tracking(1.28)
                        .foregroundStyle(Color.theme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.theme.accent.opacity(0.08))
                        .clipShape(Capsule())
                        .padding(.top, 19)

                    Text("A few quick details about your first car")
                        .font(.custom("Quicksand-Bold", size: 28))
                        .tracking(-1.12)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .foregroundStyle(Color.theme.ink)
                        .frame(width: contentWidth)
                        .padding(.top, 18)

                    Text("We'll ask about your make, model, mileage, and how you drive - so your service plan and reminders are tuned to your car!")
                        .font(.custom("Quicksand-Light", size: 16))
                        .tracking(-0.64)
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)
                        .foregroundStyle(.black)
                        .frame(width: min(geo.size.width - 72, 321))
                        .padding(.top, 20)

                    Spacer(minLength: 24)

                    Button(action: onContinue) {
                        Text("Add my car")
                            .font(.custom("Quicksand-SemiBold", size: 14))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.agOnboardingBrown)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(OnboardingScaleStylePublic())
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom + 8, 24))
                }
            }
        }
    }
}

#Preview {
    OnboardingGarageIntroView(onContinue: {})
        .environment(AppState())
        .environment(AuthState())
}
