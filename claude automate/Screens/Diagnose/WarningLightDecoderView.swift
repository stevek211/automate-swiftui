import SwiftUI

struct WarningLightDecoderView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedLight: DiagnosticLight?

    var filteredLights: [DiagnosticLight] {
        if searchText.isEmpty { return appState.diagnosticLights }
        return appState.diagnosticLights.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedLights: [(String, [DiagnosticLight])] {
        let grouped = Dictionary(grouping: filteredLights, by: { $0.category.rawValue })
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AGSpacing.xl) {
                ForEach(groupedLights, id: \.0) { category, lights in
                    VStack(alignment: .leading, spacing: AGSpacing.md) {
                        Text(category)
                            .font(.poppinsTitle3)
                            .foregroundStyle(Color.agForeground)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AGSpacing.md) {
                            ForEach(lights) { light in
                                Button {
                                    selectedLight = light
                                } label: {
                                    VStack(spacing: AGSpacing.sm) {
                                        Image(systemName: light.iconName)
                                            .font(.system(size: 24))
                                            .foregroundStyle(Color.severityColor(light.severity))
                                            .frame(width: 48, height: 48)
                                            .background(Color.severityColor(light.severity).opacity(0.1))
                                            .clipShape(Circle())

                                        Text(light.name)
                                            .font(.poppinsCaption)
                                            .foregroundStyle(Color.agForeground)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AGSpacing.sm)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(AGSpacing.screenPadding)
        }
        .appBackground()
        .navigationTitle("Warning Lights")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search warning lights")
        .sheet(item: $selectedLight) { light in
            DiagnosticLightDetailView(light: light)
        }
    }
}

struct DiagnosticLightDetailView: View {
    let light: DiagnosticLight
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AGSpacing.xl) {
                    // Header
                    HStack(spacing: AGSpacing.lg) {
                        Image(systemName: light.iconName)
                            .font(.system(size: 36))
                            .foregroundStyle(Color.severityColor(light.severity))
                            .frame(width: 64, height: 64)
                            .background(Color.severityColor(light.severity).opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: AGSpacing.xs) {
                            Text(light.name)
                                .font(.poppinsTitle2)
                                .foregroundStyle(Color.agForeground)
                            StatusPill(text: light.severity.rawValue, color: Color.severityColor(light.severity))
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: AGSpacing.sm) {
                        Text("What it means")
                            .font(.poppinsHeadline)
                        Text(light.description)
                            .font(.poppinsBody)
                            .foregroundStyle(Color.agMutedForeground)
                    }

                    // Action
                    VStack(alignment: .leading, spacing: AGSpacing.sm) {
                        Text("What to do")
                            .font(.poppinsHeadline)
                        Text(light.action)
                            .font(.poppinsBody)
                            .foregroundStyle(Color.agMutedForeground)
                    }

                    // Estimated cost
                    HStack {
                        Text("Estimated Cost")
                            .font(.poppinsHeadline)
                        Spacer()
                        Text(light.estimatedCost)
                            .font(.poppinsTitle3)
                            .foregroundStyle(Color.agPrimary)
                    }
                    .cardStyle()

                    // Common causes
                    VStack(alignment: .leading, spacing: AGSpacing.md) {
                        Text("Common Causes")
                            .font(.poppinsHeadline)
                        ForEach(light.causes, id: \.self) { cause in
                            HStack(spacing: AGSpacing.md) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(Color.agMutedForeground)
                                Text(cause)
                                    .font(.poppinsBody)
                                    .foregroundStyle(Color.agForeground)
                            }
                        }
                    }
                }
                .padding(AGSpacing.screenPadding)
            }
            .appBackground()
            .navigationTitle(light.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.poppinsCaption2)
            .foregroundStyle(color)
            .padding(.horizontal, AGSpacing.sm)
            .padding(.vertical, AGSpacing.xs)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        WarningLightDecoderView()
    }
    .environment(AppState())
}
