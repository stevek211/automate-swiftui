import SwiftUI
import UIKit

/// Shows a "Done" bar just above the keyboard while it's open, so number pads
/// (which have no return key) can be closed. Works on any screen or sheet:
/// it tracks the keyboard itself and closes whichever field is active.
struct KeyboardDoneBar: ViewModifier {
    /// Extra work on Done, e.g. clearing the screen's own @FocusState so
    /// SwiftUI doesn't put the keyboard back.
    var onDone: (() -> Void)? = nil
    @State private var keyboardVisible = false

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if keyboardVisible {
                    HStack {
                        Spacer()
                        Button("Done") {
                            onDone?()
                            dismissKeyboard()
                        }
                            .font(.quicksand(.semibold, size: 16))
                            .foregroundStyle(ServicePlanPalette.textPrimary)
                            .padding(.horizontal, 20)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                            .buttonStyle(.plain)
                    }
                    .background(.white)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(ServicePlanPalette.borderLight)
                            .frame(height: 0.75)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardVisible = false
            }
    }
}

extension View {
    /// Adds a "Done" bar above the keyboard while it's open. See `KeyboardDoneBar`.
    func keyboardDoneBar(onDone: (() -> Void)? = nil) -> some View {
        modifier(KeyboardDoneBar(onDone: onDone))
    }
}

/// Closes the keyboard, whichever text field has it.
func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
