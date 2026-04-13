import SwiftUI

struct MaintenanceTimelineCard: View {
    let item: MaintenanceItem

    var statusColor: Color {
        Color.statusColor(item.status)
    }

    var body: some View {
        HStack(spacing: AGSpacing.md) {
            // Status indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: AGSpacing.xs) {
                HStack {
                    Text(item.name)
                        .font(.jakartaHeadline)
                        .foregroundStyle(Color.agForeground)

                    Spacer()

                    StatusBadge(status: item.status)
                }

                Text(item.description)
                    .font(.jakartaCaption)
                    .foregroundStyle(Color.agMutedForeground)
                    .lineLimit(1)

                HStack(spacing: AGSpacing.lg) {
                    if let dueDate = item.dueDate {
                        Label(dueDate.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
                            .font(.jakartaCaption)
                            .foregroundStyle(Color.agMutedForeground)
                    }

                    if let dueMileage = item.dueMileage {
                        Label("\(dueMileage.formatted()) mi", systemImage: "speedometer")
                            .font(.jakartaCaption)
                            .foregroundStyle(Color.agMutedForeground)
                    }

                    Spacer()

                    Text(item.estimatedCostDisplay)
                        .font(.jakartaCaption)
                        .foregroundStyle(Color.agMutedForeground)
                }
            }
        }
        .padding(AGSpacing.cardPadding)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct StatusBadge: View {
    let status: MaintenanceStatus

    var body: some View {
        Text(status.rawValue)
            .font(.jakartaCaption2)
            .foregroundStyle(Color.statusColor(status))
            .padding(.horizontal, AGSpacing.sm)
            .padding(.vertical, AGSpacing.xs)
            .background(Color.statusColor(status).opacity(0.1))
            .clipShape(Capsule())
    }
}

#Preview {
    VStack {
        MaintenanceTimelineCard(item: DemoData.maintenanceItems[0])
        MaintenanceTimelineCard(item: DemoData.maintenanceItems[3])
    }
    .padding()
    .background(Color.agBackground)
}
