import SwiftUI

@Observable
class AppState {
    // MARK: - Data Mode

    /// When true, the app shows demo sample data. When false (default), all user
    /// data arrays start empty — only data the user has personally added is shown.
    /// Demo mode is explicitly opt-in (e.g. from an empty garage "Explore demo" button).
    var isDemo: Bool = false {
        didSet {
            if isDemo {
                loadDemoData()
            } else {
                clearDemoData()
            }
        }
    }

    // MARK: - Active User

    /// The currently authenticated user's ID. All persistence is scoped to this.
    /// nil means no user is logged in — all user data arrays are empty.
    private(set) var activeUserId: UUID? = nil

    // Onboarding — scoped to user
    var hasCompletedOnboarding: Bool {
        get {
            guard let uid = activeUserId else { return false }
            return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding_\(uid.uuidString)")
        }
        set {
            guard let uid = activeUserId else { return }
            UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding_\(uid.uuidString)")
        }
    }
    var showOnboarding = false

    // MARK: - User Data (starts EMPTY for new users)

    // Vehicles
    var vehicles: [Vehicle] = [] {
        didSet {
            if !isDemo && activeUserId != nil { persistVehicles() }
        }
    }
    var selectedVehicleId: UUID? = nil {
        didSet {
            guard let uid = activeUserId else { return }
            UserDefaults.standard.set(selectedVehicleId?.uuidString, forKey: "selectedVehicleId_\(uid.uuidString)")
        }
    }

    var selectedVehicle: Vehicle? {
        vehicles.first { $0.id == selectedVehicleId }
    }

    // Service Logs
    var serviceLogs: [ServiceLog] = [] {
        didSet {
            if !isDemo && activeUserId != nil { persistServiceLogs() }
        }
    }

    func serviceLogs(for vehicleId: UUID) -> [ServiceLog] {
        serviceLogs.filter { $0.vehicleId == vehicleId }
            .sorted { $0.date > $1.date }
    }

    // Maintenance Items
    var maintenanceItems: [MaintenanceItem] = [] {
        didSet {
            if !isDemo && activeUserId != nil { persistMaintenanceItems() }
        }
    }

    // Per-vehicle OEM maintenance schedule (flat list with recurrence metadata)
    // from Perplexity. Keyed by vehicle.id. Drives the Service Plan timeline.
    var oemSchedules: [UUID: [OEMScheduleItemInput]] = [:] {
        didSet {
            if !isDemo && activeUserId != nil { persistOEMSchedules() }
        }
    }

    func oemSchedule(for vehicleId: UUID) -> [OEMScheduleItemInput]? {
        oemSchedules[vehicleId]
    }

    // Per-vehicle OEM sources (manufacturer PDFs, dealer pages, etc.) —
    // rendered as clickable links in the Service Plan footer.
    var oemSources: [UUID: [OEMScheduleSource]] = [:] {
        didSet {
            if !isDemo && activeUserId != nil { persistOEMSources() }
        }
    }

    func oemSources(for vehicleId: UUID) -> [OEMScheduleSource] {
        oemSources[vehicleId] ?? []
    }

    func maintenanceItems(for vehicleId: UUID) -> [MaintenanceItem] {
        maintenanceItems.filter { $0.vehicleId == vehicleId }
    }

    func overdueItems(for vehicleId: UUID) -> [MaintenanceItem] {
        maintenanceItems(for: vehicleId).filter { $0.status == .overdue }
    }

    func dueSoonItems(for vehicleId: UUID) -> [MaintenanceItem] {
        maintenanceItems(for: vehicleId).filter { $0.status == .dueSoon }
    }

    var alertCount: Int {
        guard let id = selectedVehicleId else { return 0 }
        return overdueItems(for: id).count + dueSoonItems(for: id).count
    }

    // MARK: - Reference / Knowledge Data (always available, NOT user-specific)

    var diagnosticLights: [DiagnosticLight] { ReferenceData.diagnosticLights }
    var noiseDiagnoses: [NoiseDiagnosis] { ReferenceData.noiseDiagnoses }
    var carSystems: [CarSystem] { ReferenceData.carSystems }
    var articles: [LearningArticle] { ReferenceData.articles }

    // Sheet presentation state
    var showQuickLog = false
    var showSettings = false
    var showAddVehicle = false
    var showMileageUpdater = false
    var showEditVehicle = false
    var showServiceAlerts = false
    var showDemoWriteAlert = false

    // Tab selection
    var selectedTab: AppTab = .home

    // MARK: - Init

    init() {
        // Start empty — data loads when configure(for:) is called after auth
    }

    // MARK: - User Scoping

    /// Called after login/signup to load data for the authenticated user.
    /// All persistence files are scoped to this userId.
    func configure(for userId: UUID) {
        activeUserId = userId

        // Load this user's persisted data (empty arrays if new user)
        vehicles = loadVehicles() ?? []
        serviceLogs = loadServiceLogs() ?? []
        maintenanceItems = loadMaintenanceItems() ?? []
        oemSchedules = loadOEMSchedules() ?? [:]
        oemSources = loadOEMSources() ?? [:]

        // Restore this user's selected vehicle
        if let savedId = UserDefaults.standard.string(forKey: "selectedVehicleId_\(userId.uuidString)"),
           let uuid = UUID(uuidString: savedId),
           vehicles.contains(where: { $0.id == uuid }) {
            selectedVehicleId = uuid
        } else {
            selectedVehicleId = vehicles.first?.id
        }

    }

    /// Called on logout — wipes all in-memory user data, no files touched.
    func clear() {
        activeUserId = nil
        vehicles = []
        serviceLogs = []
        maintenanceItems = []
        oemSchedules = [:]
        oemSources = [:]
        selectedVehicleId = nil
        isDemo = false
        selectedTab = .home
        showQuickLog = false
        showSettings = false
        showAddVehicle = false
        showMileageUpdater = false
        showEditVehicle = false
        showServiceAlerts = false
    }

    // MARK: - Demo Write Guard

    /// Returns true if in demo mode (write should be blocked).
    /// Sets showDemoWriteAlert to present the prompt to the user.
    func guardWrite() -> Bool {
        if isDemo {
            showDemoWriteAlert = true
            return true
        }
        return false
    }

    // MARK: - Actions

    func addVehicle(_ vehicle: Vehicle) {
        var vehicle = vehicle
        // The odometer reading entered when adding the car is the first update.
        if vehicle.mileageUpdatedAt == nil { vehicle.mileageUpdatedAt = .now }
        vehicles.append(vehicle)
        selectedVehicleId = vehicle.id
    }

    /// Replaces a vehicle's details (edit sheet). Stamps the mileage date when
    /// the odometer value changed.
    func updateVehicle(_ updated: Vehicle) {
        guard let index = vehicles.firstIndex(where: { $0.id == updated.id }) else { return }
        var updated = updated
        if updated.mileage != vehicles[index].mileage { updated.mileageUpdatedAt = .now }
        vehicles[index] = updated
    }

    func removeVehicle(_ vehicle: Vehicle) {
        vehicles.removeAll { $0.id == vehicle.id }
        serviceLogs.removeAll { $0.vehicleId == vehicle.id }
        maintenanceItems.removeAll { $0.vehicleId == vehicle.id }
        oemSchedules.removeValue(forKey: vehicle.id)
        oemSources.removeValue(forKey: vehicle.id)
        if selectedVehicleId == vehicle.id {
            selectedVehicleId = vehicles.first?.id
        }
    }

    func addServiceLog(_ log: ServiceLog) {
        serviceLogs.insert(log, at: 0)
        if let index = vehicles.firstIndex(where: { $0.id == log.vehicleId }) {
            vehicles[index].lastService = log.date
        }
    }

    /// Store baseline service entries from onboarding setup.
    /// Also generates maintenance items for skipped/unknown entries.
    func storeBaselineServiceLogs(_ entries: [ServiceLog], for vehicleId: UUID) {
        serviceLogs.removeAll { log in
            log.vehicleId == vehicleId && log.shop == "AutoGuard Baseline"
        }
        serviceLogs.insert(contentsOf: entries, at: 0)

        // Remove any existing baseline maintenance items for this vehicle
        maintenanceItems.removeAll { $0.vehicleId == vehicleId && $0.category.hasPrefix("baseline-") }

        // Generate "needs attention" items for skipped/unknown entries
        for entry in entries {
            let isUnknown = entry.notes?.contains("Status: unknown") == true
            guard isUnknown else { continue }

            let (name, description, _) = baselineAttentionInfo(for: entry.category)
            let item = MaintenanceItem(
                id: UUID(),
                vehicleId: vehicleId,
                name: name,
                status: .overdue,
                dueDate: nil,
                dueMileage: nil,
                description: description,
                estimatedCostLow: 0,
                estimatedCostHigh: 0,
                category: "baseline-\(entry.category.rawValue)",
                diyDifficulty: 1
            )
            maintenanceItems.append(item)
        }
    }

    /// Store baseline service logs with AI-generated maintenance items and
    /// the raw OEM schedule (used to drive the Service Plan timeline).
    func storeBaselineServiceLogsWithAI(
        _ entries: [ServiceLog],
        items: [MaintenanceItem],
        schedule: [OEMScheduleItemInput] = [],
        sources: [OEMScheduleSource] = [],
        for vehicleId: UUID
    ) {
        serviceLogs.removeAll { $0.vehicleId == vehicleId && $0.shop == "AutoGuard Baseline" }
        serviceLogs.insert(contentsOf: entries, at: 0)
        maintenanceItems.removeAll { $0.vehicleId == vehicleId && ($0.category.hasPrefix("baseline-") || $0.category.hasPrefix("ai-")) }
        maintenanceItems.append(contentsOf: items)
        if !schedule.isEmpty {
            oemSchedules[vehicleId] = schedule
        }
        if !sources.isEmpty {
            oemSources[vehicleId] = sources
        }
    }

    /// Returns (name, description, category) for a skipped baseline service category.
    private func baselineAttentionInfo(for category: ServiceCategory) -> (String, String, String) {
        switch category {
        case .oil:
            return (
                "Oil Change",
                "Since you weren't sure when your last oil change was, check your dipstick and oil level before your next drive.",
                "baseline-oil"
            )
        case .tires:
            return (
                "Tire Rotation",
                "Since tire rotation timing is unclear, ask your shop to inspect wear pattern before recommending new tires.",
                "baseline-tires"
            )
        case .brakes:
            return (
                "Brake Pads",
                "Since brake pad history is unknown, request a pad thickness measurement before approving brake work.",
                "baseline-brakes"
            )
        case .filters:
            return (
                "Engine Air Filter",
                "Since air filter status is unclear, ask the shop to show the filter condition before replacing it.",
                "baseline-filters"
            )
        case .battery:
            return (
                "Battery",
                "Since battery age is unknown, get a quick battery health test so you can avoid an unnecessary replacement.",
                "baseline-battery"
            )
        default:
            return (
                category.rawValue,
                "Service history is unknown. Have this checked at your next visit.",
                "baseline-\(category.rawValue)"
            )
        }
    }

    func updateMileage(_ mileage: Int) {
        guard let index = vehicles.firstIndex(where: { $0.id == selectedVehicleId }) else { return }
        vehicles[index].mileage = mileage
        vehicles[index].mileageUpdatedAt = .now
    }

    // MARK: - Demo Mode

    private func loadDemoData() {
        vehicles = DemoData.vehicles
        serviceLogs = DemoData.serviceLogs
        maintenanceItems = DemoData.maintenanceItems
        selectedVehicleId = DemoData.vehicleHondaId
    }

    private func clearDemoData() {
        vehicles = loadVehicles() ?? []
        serviceLogs = loadServiceLogs() ?? []
        maintenanceItems = loadMaintenanceItems() ?? []
        oemSchedules = loadOEMSchedules() ?? [:]
        oemSources = loadOEMSources() ?? [:]
        selectedVehicleId = vehicles.first?.id
    }

    // MARK: - Persistence (scoped to activeUserId)

    private static let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    private func fileURL(for filename: String) -> URL {
        guard let uid = activeUserId else {
            // Fallback — should never persist without a user, but prevent crashes
            return Self.docsDir.appendingPathComponent("\(filename).json")
        }
        return Self.docsDir.appendingPathComponent("\(filename)_\(uid.uuidString).json")
    }

    private func persistVehicles() {
        do {
            let data = try JSONEncoder().encode(vehicles)
            try data.write(to: fileURL(for: "autoguard_vehicles"), options: .atomic)
        } catch {
            print("Failed to persist vehicles: \(error)")
        }
    }

    private func persistServiceLogs() {
        do {
            let data = try JSONEncoder().encode(serviceLogs)
            try data.write(to: fileURL(for: "autoguard_service_logs"), options: .atomic)
        } catch {
            print("Failed to persist service logs: \(error)")
        }
    }

    private func persistMaintenanceItems() {
        do {
            let data = try JSONEncoder().encode(maintenanceItems)
            try data.write(to: fileURL(for: "autoguard_maintenance_items"), options: .atomic)
        } catch {
            print("Failed to persist maintenance items: \(error)")
        }
    }

    private func loadVehicles() -> [Vehicle]? {
        guard activeUserId != nil else { return nil }
        guard let data = try? Data(contentsOf: fileURL(for: "autoguard_vehicles")) else { return nil }
        return try? JSONDecoder().decode([Vehicle].self, from: data)
    }

    private func loadServiceLogs() -> [ServiceLog]? {
        guard activeUserId != nil else { return nil }
        guard let data = try? Data(contentsOf: fileURL(for: "autoguard_service_logs")) else { return nil }
        return try? JSONDecoder().decode([ServiceLog].self, from: data)
    }

    private func loadMaintenanceItems() -> [MaintenanceItem]? {
        guard activeUserId != nil else { return nil }
        guard let data = try? Data(contentsOf: fileURL(for: "autoguard_maintenance_items")) else { return nil }
        return try? JSONDecoder().decode([MaintenanceItem].self, from: data)
    }

    private func persistOEMSchedules() {
        do {
            let data = try JSONEncoder().encode(oemSchedules)
            try data.write(to: fileURL(for: "autoguard_oem_schedules"), options: .atomic)
        } catch {
            print("Failed to persist OEM schedules: \(error)")
        }
    }

    private func loadOEMSchedules() -> [UUID: [OEMScheduleItemInput]]? {
        guard activeUserId != nil else { return nil }
        guard let data = try? Data(contentsOf: fileURL(for: "autoguard_oem_schedules")) else { return nil }
        return try? JSONDecoder().decode([UUID: [OEMScheduleItemInput]].self, from: data)
    }

    private func persistOEMSources() {
        do {
            let data = try JSONEncoder().encode(oemSources)
            try data.write(to: fileURL(for: "autoguard_oem_sources"), options: .atomic)
        } catch {
            print("Failed to persist OEM sources: \(error)")
        }
    }

    private func loadOEMSources() -> [UUID: [OEMScheduleSource]]? {
        guard activeUserId != nil else { return nil }
        guard let data = try? Data(contentsOf: fileURL(for: "autoguard_oem_sources")) else { return nil }
        return try? JSONDecoder().decode([UUID: [OEMScheduleSource]].self, from: data)
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case diagnose = "Diagnose"
    case learn = "Learn"
    case garage = "Garage"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .diagnose: return "exclamationmark.triangle.fill"
        case .learn: return "book.fill"
        case .garage: return "car.fill"
        }
    }
}
