import Foundation

enum UploadMode: String, Codable {
    case batch
    case immediate
}

class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    @Published var wifiOnly: Bool {
        didSet { UserDefaults.standard.set(wifiOnly, forKey: "wifiOnly") }
    }

    @Published var requireCharging: Bool {
        didSet { UserDefaults.standard.set(requireCharging, forKey: "requireCharging") }
    }

    @Published var uploadMode: UploadMode {
        didSet { UserDefaults.standard.set(uploadMode.rawValue, forKey: "uploadMode") }
    }

    @Published var chunkDuration: Int {
        didSet { UserDefaults.standard.set(chunkDuration, forKey: "chunkDuration") }
    }

    private init() {
        self.wifiOnly = UserDefaults.standard.object(forKey: "wifiOnly") as? Bool ?? true
        self.requireCharging = UserDefaults.standard.object(forKey: "requireCharging") as? Bool ?? false
        self.uploadMode = UploadMode(rawValue: UserDefaults.standard.string(forKey: "uploadMode") ?? "") ?? .batch
        self.chunkDuration = UserDefaults.standard.object(forKey: "chunkDuration") as? Int ?? 600
    }
}
