import SwiftUI

struct ServiceLogRow: View {
    let log: ServiceLog

    var body: some View {
        HStack(spacing: AGSpacing.md) {
            Image(systemName: log.category.iconName)
                .font(.system(size: 16))
                .foregroundStyle(Color.agPrimary)
                .frame(width: 36, height: 36)
                .background(Color.agPrimary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AGSpacing.xs) {
                Text(log.name)
                    .font(.jakartaCallout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.agForeground)

                HStack(spacing: AGSpacing.sm) {
                    Text(log.date.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.jakartaCaption)
                        .foregroundStyle(Color.agMutedForeground)

                    if let shop = log.shop {
                        Text("·")
                            .foregroundStyle(Color.agMutedForeground)
                        Text(shop)
                            .font(.jakartaCaption)
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
            }

            Spacer()

            Text("$\(Int(log.cost))")
                .font(.jakartaHeadline)
                .foregroundStyle(Color.agForeground)
        }
        .padding(.vertical, AGSpacing.sm)
    }
}

#Preview {
    List {
        ServiceLogRow(log: DemoData.serviceLogs[0])
        ServiceLogRow(log: DemoData.serviceLogs[2])
    }
}
