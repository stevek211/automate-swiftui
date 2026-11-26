import SwiftUI

struct SystemDetailView: View {
    let system: CarSystem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AGSpacing.xl) {
                // Header
                HStack(spacing: AGSpacing.lg) {
                    Image(systemName: system.iconName)
                        .font(.system(size: 36))
                        .foregroundStyle(Color.agPrimary)
                        .frame(width: 64, height: 64)
                        .background(Color.agPrimary.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: AGSpacing.xs) {
                        Text(system.name)
                            .font(.quicksandScaled(.bold, size: 22))
                        Text(system.description)
                            .font(.quicksandScaled(.regular, size: 14))
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }

                // Overview
                VStack(alignment: .leading, spacing: AGSpacing.sm) {
                    Text("Overview")
                        .font(.quicksandScaled(.semibold, size: 18))
                    Text(system.overview)
                        .font(.quicksandScaled(.regular, size: 15))
                        .foregroundStyle(Color.agMutedForeground)
                }

                // Components
                VStack(alignment: .leading, spacing: AGSpacing.md) {
                    Text("Key Components")
                        .font(.quicksandScaled(.semibold, size: 18))

                    ForEach(system.components, id: \.name) { component in
                        HStack(alignment: .top, spacing: AGSpacing.md) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.agPrimary)
                                .frame(width: 28, height: 28)
                                .background(Color.agPrimary.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: AGSpacing.xs) {
                                Text(component.name)
                                    .font(.quicksandScaled(.semibold, size: 16))
                                Text(component.description)
                                    .font(.quicksandScaled(.regular, size: 14))
                                    .foregroundStyle(Color.agMutedForeground)
                            }
                        }
                    }
                }

                // How it works
                VStack(alignment: .leading, spacing: AGSpacing.md) {
                    Text("How It Works")
                        .font(.quicksandScaled(.semibold, size: 18))

                    ForEach(Array(system.howItWorks.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: AGSpacing.md) {
                            Text("\(index + 1)")
                                .font(.quicksandScaled(.medium, size: 12))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.agPrimary)
                                .clipShape(Circle())

                            Text(step)
                                .font(.quicksandScaled(.regular, size: 15))
                                .foregroundStyle(Color.agForeground)
                        }
                    }
                }

                // Common Issues
                VStack(alignment: .leading, spacing: AGSpacing.md) {
                    Text("Common Issues")
                        .font(.quicksandScaled(.semibold, size: 18))

                    ForEach(system.commonIssues) { issue in
                        VStack(alignment: .leading, spacing: AGSpacing.sm) {
                            HStack {
                                Text(issue.name)
                                    .font(.quicksandScaled(.semibold, size: 16))
                                Spacer()
                                Text(issue.estimatedCost)
                                    .font(.quicksandScaled(.medium, size: 12))
                                    .foregroundStyle(Color.agPrimary)
                            }

                            Text("Symptoms: \(issue.symptoms.joined(separator: ", "))")
                                .font(.quicksandScaled(.medium, size: 12))
                                .foregroundStyle(Color.agMutedForeground)

                            Text("Causes: \(issue.causes.joined(separator: ", "))")
                                .font(.quicksandScaled(.medium, size: 12))
                                .foregroundStyle(Color.agMutedForeground)
                        }
                        .cardStyle()
                    }
                }

                // Service Schedule
                VStack(alignment: .leading, spacing: AGSpacing.md) {
                    Text("Service Schedule")
                        .font(.quicksandScaled(.semibold, size: 18))

                    ForEach(system.serviceSchedule, id: \.self) { schedule in
                        HStack(spacing: AGSpacing.md) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(Color.agPrimary)
                            Text(schedule)
                                .font(.quicksandScaled(.regular, size: 15))
                                .foregroundStyle(Color.agForeground)
                        }
                    }
                }
            }
            .padding(AGSpacing.screenPadding)
        }
        .appBackground()
        .navigationTitle(system.name)
        .navigationBarTitleDisplayMode(.inline)
        .standardBackButton()
    }
}

#Preview {
    NavigationStack {
        SystemDetailView(system: DemoData.carSystems[0])
    }
}
