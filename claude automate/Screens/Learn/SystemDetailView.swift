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
                            .font(.jakartaTitle)
                        Text(system.description)
                            .font(.jakartaCallout)
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }

                // Overview
                VStack(alignment: .leading, spacing: AGSpacing.sm) {
                    Text("Overview")
                        .font(.jakartaTitle3)
                    Text(system.overview)
                        .font(.jakartaBody)
                        .foregroundStyle(Color.agMutedForeground)
                }

                // Components
                VStack(alignment: .leading, spacing: AGSpacing.md) {
                    Text("Key Components")
                        .font(.jakartaTitle3)

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
                                    .font(.jakartaHeadline)
                                Text(component.description)
                                    .font(.jakartaCallout)
                                    .foregroundStyle(Color.agMutedForeground)
                            }
                        }
                    }
                }

                // How it works
                VStack(alignment: .leading, spacing: AGSpacing.md) {
                    Text("How It Works")
                        .font(.jakartaTitle3)

                    ForEach(Array(system.howItWorks.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: AGSpacing.md) {
                            Text("\(index + 1)")
                                .font(.jakartaCaption)
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.agPrimary)
                                .clipShape(Circle())

                            Text(step)
                                .font(.jakartaBody)
                                .foregroundStyle(Color.agForeground)
                        }
                    }
                }

                // Common Issues
                VStack(alignment: .leading, spacing: AGSpacing.md) {
                    Text("Common Issues")
                        .font(.jakartaTitle3)

                    ForEach(system.commonIssues) { issue in
                        VStack(alignment: .leading, spacing: AGSpacing.sm) {
                            HStack {
                                Text(issue.name)
                                    .font(.jakartaHeadline)
                                Spacer()
                                Text(issue.estimatedCost)
                                    .font(.jakartaCaption)
                                    .foregroundStyle(Color.agPrimary)
                            }

                            Text("Symptoms: \(issue.symptoms.joined(separator: ", "))")
                                .font(.jakartaCaption)
                                .foregroundStyle(Color.agMutedForeground)

                            Text("Causes: \(issue.causes.joined(separator: ", "))")
                                .font(.jakartaCaption)
                                .foregroundStyle(Color.agMutedForeground)
                        }
                        .cardStyle()
                    }
                }

                // Service Schedule
                VStack(alignment: .leading, spacing: AGSpacing.md) {
                    Text("Service Schedule")
                        .font(.jakartaTitle3)

                    ForEach(system.serviceSchedule, id: \.self) { schedule in
                        HStack(spacing: AGSpacing.md) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(Color.agPrimary)
                            Text(schedule)
                                .font(.jakartaBody)
                                .foregroundStyle(Color.agForeground)
                        }
                    }
                }
            }
            .padding(AGSpacing.screenPadding)
        }
        .background(Color.agBackground)
        .navigationTitle(system.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SystemDetailView(system: DemoData.carSystems[0])
    }
}
