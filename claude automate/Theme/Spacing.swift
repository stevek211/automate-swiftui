import SwiftUI

enum AGSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusSm: CGFloat = 8
    static let cornerRadiusLg: CGFloat = 16
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AGSpacing.cardPadding)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.poppinsHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AGSpacing.md)
            .background(Color.agPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadiusSm))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.poppinsHeadline)
            .foregroundStyle(Color.agPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AGSpacing.md)
            .background(Color.agPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadiusSm))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
