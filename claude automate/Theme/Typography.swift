import SwiftUI

extension Font {
    static func poppins(_ weight: PoppinsWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

    static func quicksand(_ weight: QuicksandWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

    /// Quicksand at `size` by default, scaling with the user's Dynamic Type
    /// setting like the system text style closest to that size.
    static func quicksandScaled(_ weight: QuicksandWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size, relativeTo: TextStyle.closest(to: size))
    }
}

private extension Font.TextStyle {
    /// Nearest iOS text style by default point size, so custom sizes scale
    /// on the same curve as system text.
    static func closest(to size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<11.5: return .caption2      // 11
        case ..<12.5: return .caption       // 12
        case ..<14.5: return .footnote      // 13
        case ..<15.5: return .subheadline   // 15
        case ..<16.5: return .callout       // 16
        case ..<18.5: return .body          // 17
        case ..<21:   return .title3        // 20
        case ..<25:   return .title2        // 22
        case ..<31:   return .title         // 28
        default:      return .largeTitle    // 34
        }
    }
}

extension Font {

    static let poppinsLargeTitle: Font = .custom("Poppins-Bold", size: 28)
    static let poppinsTitle: Font     = .custom("Poppins-Bold", size: 22)
    static let poppinsTitle2: Font    = .custom("Poppins-SemiBold", size: 20)
    static let poppinsTitle3: Font    = .custom("Poppins-SemiBold", size: 18)
    static let poppinsHeadline: Font  = .custom("Poppins-SemiBold", size: 16)
    static let poppinsBody: Font      = .custom("Poppins-Regular", size: 15)
    static let poppinsCallout: Font   = .custom("Poppins-Regular", size: 14)
    static let poppinsCaption: Font   = .custom("Poppins-Medium", size: 12)
    static let poppinsCaption2: Font  = .custom("Poppins-Regular", size: 11)
}

enum PoppinsWeight {
    case light, regular, medium, semibold, bold

    var fontName: String {
        switch self {
        case .light:    return "Poppins-Light"
        case .regular:  return "Poppins-Regular"
        case .medium:   return "Poppins-Medium"
        case .semibold: return "Poppins-SemiBold"
        case .bold:     return "Poppins-Bold"
        }
    }
}

enum QuicksandWeight {
    case light, regular, medium, semibold, bold

    var fontName: String {
        switch self {
        case .light:    return "Quicksand-Light"
        case .regular:  return "Quicksand-Regular"
        case .medium:   return "Quicksand-Medium"
        case .semibold: return "Quicksand-SemiBold"
        case .bold:     return "Quicksand-Bold"
        }
    }
}
