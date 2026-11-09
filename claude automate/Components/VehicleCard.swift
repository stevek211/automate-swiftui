import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle
    var compact: Bool = false

    var body: some View {
        HStack(spacing: AGSpacing.lg) {
            // Vehicle image from IMAGIN.studio CDN
            VehicleImageView(vehicle: vehicle, size: compact ? 48 : 56)

            VStack(alignment: .leading, spacing: AGSpacing.xs) {
                Text(vehicle.fullDisplayName)
                    .font(compact ? .poppinsCallout : .poppinsHeadline)
                    .foregroundStyle(Color.agForeground)

                HStack(spacing: AGSpacing.sm) {
                    Label("\(vehicle.mileage.formatted()) mi", systemImage: "speedometer")
                        .font(.poppinsCaption)
                        .foregroundStyle(Color.agMutedForeground)

                    if !compact {
                        Text("·")
                            .foregroundStyle(Color.agMutedForeground)
                        Text(vehicle.color)
                            .font(.poppinsCaption)
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }
            }

            Spacer()

            if !compact {
                HealthScoreBadge(score: vehicle.healthScore)
            }
        }
        .padding(compact ? AGSpacing.md : AGSpacing.cardPadding)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadius))
        .shadow(color: .black.opacity(compact ? 0 : 0.05), radius: 8, x: 0, y: 2)
    }
}

struct HealthScoreBadge: View {
    let score: Int

    var color: Color {
        if score >= 90 { return .agSuccess }
        if score >= 70 { return .agWarning }
        return .agDestructive
    }

    var body: some View {
        Text("\(score)")
            .font(.poppinsHeadline)
            .foregroundStyle(color)
            .frame(width: 44, height: 44)
            .background(color.opacity(0.1))
            .clipShape(Circle())
    }
}

#Preview {
    VStack {
        VehicleCard(vehicle: DemoData.vehicles[0])
        VehicleCard(vehicle: DemoData.vehicles[1], compact: true)
    }
    .padding()
    .background(Color.agBackground)
}
