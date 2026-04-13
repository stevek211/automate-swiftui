import SwiftUI

struct MileageUpdaterSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var mileageText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: AGSpacing.xl) {
                if let vehicle = appState.selectedVehicle {
                    VehicleCard(vehicle: vehicle, compact: true)

                    VStack(alignment: .leading, spacing: AGSpacing.sm) {
                        Text("Current Mileage")
                            .font(.jakartaCallout)
                        Text("\(vehicle.mileage.formatted()) miles")
                            .font(.jakartaTitle2)
                            .foregroundStyle(Color.agMutedForeground)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: AGSpacing.sm) {
                        Text("New Mileage")
                            .font(.jakartaCallout)
                        TextField("Enter new mileage", text: $mileageText)
                            .font(.jakartaBody)
                            .keyboardType(.numberPad)
                            .padding(AGSpacing.md)
                            .background(Color.agMuted)
                            .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadiusSm))
                    }

                    Spacer()

                    Button {
                        if let mileage = Int(mileageText) {
                            appState.updateMileage(mileage)
                        }
                        dismiss()
                    } label: {
                        Text("Update Mileage")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(mileageText.isEmpty)
                }
            }
            .padding(AGSpacing.screenPadding)
            .background(Color.agBackground)
            .navigationTitle("Update Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    MileageUpdaterSheet()
        .environment(AppState())
}
