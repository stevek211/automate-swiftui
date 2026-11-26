import SwiftUI

/// Displays a stock vehicle image from IMAGIN.studio CDN via AsyncImage.
/// Falls back to a styled SF Symbol on failure or nil URL.
struct VehicleImageView: View {
    let vehicle: Vehicle
    var size: CGFloat = 56

    private var imageURL: URL? {
        VehicleImageService.vehicleImageURL(
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            color: vehicle.color,
            bodyStyle: vehicle.bodyStyle
        )
    }

    var body: some View {
        if let url = imageURL {
            AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.2))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size > 48 ? 14 : 10))
                case .failure:
                    fallbackIcon
                case .empty:
                    placeholder
                @unknown default:
                    fallbackIcon
                }
            }
        } else {
            fallbackIcon
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size > 48 ? 14 : 10)
                .fill(Color.agPrimary.opacity(0.06))
                .frame(width: size, height: size)
            ProgressView()
                .controlSize(.small)
        }
    }

    private var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size > 48 ? 14 : 10)
                .fill(Color.agPrimary10)
                .frame(width: size, height: size)
            Image(systemName: "car.fill")
                .font(.system(size: size * 0.38))
                .foregroundStyle(Color.agPrimary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        VehicleImageView(
            vehicle: Vehicle(
                id: UUID(), year: 2021, make: "Toyota", model: "Camry",
                trim: nil, mileage: 30000, color: "White", vin: nil,
                healthScore: 90, lastService: nil, nextService: nil,
                maintenanceCurrent: 0, maintenanceTotal: 0,
                usage: [], conditions: [], annualMileage: nil
            ),
            size: 64
        )
        VehicleImageView(
            vehicle: Vehicle(
                id: UUID(), year: 2019, make: "Honda", model: "CR-V",
                trim: "EX-L", mileage: 47000, color: "Black", vin: nil,
                healthScore: 85, lastService: nil, nextService: nil,
                maintenanceCurrent: 0, maintenanceTotal: 0,
                usage: [], conditions: [], annualMileage: nil
            ),
            size: 48
        )
    }
    .padding()
}
