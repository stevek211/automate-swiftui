import SwiftUI

extension Font {
    static func jakarta(_ style: JakartaStyle, size: CGFloat) -> Font {
        .system(size: size, weight: style.weight, design: .rounded)
    }

    static let jakartaLargeTitle: Font = .system(size: 28, weight: .bold, design: .rounded)
    static let jakartaTitle: Font = .system(size: 22, weight: .bold, design: .rounded)
    static let jakartaTitle2: Font = .system(size: 20, weight: .semibold, design: .rounded)
    static let jakartaTitle3: Font = .system(size: 18, weight: .semibold, design: .rounded)
    static let jakartaHeadline: Font = .system(size: 16, weight: .semibold, design: .rounded)
    static let jakartaBody: Font = .system(size: 15, weight: .regular, design: .rounded)
    static let jakartaCallout: Font = .system(size: 14, weight: .regular, design: .rounded)
    static let jakartaCaption: Font = .system(size: 12, weight: .medium, design: .rounded)
    static let jakartaCaption2: Font = .system(size: 11, weight: .regular, design: .rounded)
}

enum JakartaStyle {
    case regular, medium, semibold, bold

    var weight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}
