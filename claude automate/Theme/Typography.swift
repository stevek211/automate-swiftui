import SwiftUI

extension Font {
    static func poppins(_ weight: PoppinsWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

    static func quicksand(_ weight: QuicksandWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

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
