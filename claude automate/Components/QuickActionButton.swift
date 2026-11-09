import SwiftUI

struct QuickActionButton: View {
    let title: String
    let iconName: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AGSpacing.sm) {
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())

                Text(title)
                    .font(.poppinsCaption)
                    .foregroundStyle(Color.agForeground)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        QuickActionButton(title: "Log Service", iconName: "plus.circle.fill", color: .agPrimary) {}
        QuickActionButton(title: "Chat", iconName: "message.fill", color: .agAccent) {}
        QuickActionButton(title: "Alerts", iconName: "bell.fill", color: .agWarning) {}
    }
    .padding()
}
