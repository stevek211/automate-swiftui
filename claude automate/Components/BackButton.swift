import SwiftUI
import UIKit

/// The app's one back button: a 44pt Liquid Glass circle with a 16pt chevron,
/// matching the toolbar back button on the sign-in screens.
///
/// Use `BackButton()` in screens that draw their own header, and
/// `.standardBackButton()` on screens that keep the navigation bar.
struct BackButton: View {
    /// Runs instead of `dismiss()` when set (e.g. stepping back inside a flow).
    var action: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            if let action { action() } else { dismiss() }
        } label: {
            BackChevron()
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel("Back")
    }
}

/// The chevron glyph shared by both back-button forms.
struct BackChevron: View {
    var body: some View {
        Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.theme.ink)
    }
}

extension View {
    /// Replaces the system back button with the app's back button in the
    /// navigation bar. iOS draws the glass circle around toolbar items, so it
    /// looks the same as `BackButton`. Swipe-to-go-back keeps working.
    func standardBackButton(action: (() -> Void)? = nil) -> some View {
        modifier(StandardBackButtonModifier(action: action))
    }
}

private struct StandardBackButtonModifier: ViewModifier {
    var action: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let action { action() } else { dismiss() }
                    } label: {
                        BackChevron()
                    }
                    .accessibilityLabel("Back")
                }
            }
    }
}

/// Hiding the system back button (or the whole navigation bar) turns off the
/// edge swipe that pops a screen. This keeps the swipe working on every
/// pushed screen.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
