import SwiftUI

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(.jakartaTitle3)
                .foregroundStyle(Color.agForeground)

            Spacer()

            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.jakartaCallout)
                        .foregroundStyle(Color.agPrimary)
                }
            }
        }
    }
}

#Preview {
    VStack {
        SectionHeader(title: "Maintenance")
        SectionHeader(title: "Service History", action: {}, actionLabel: "View All")
    }
    .padding()
}
