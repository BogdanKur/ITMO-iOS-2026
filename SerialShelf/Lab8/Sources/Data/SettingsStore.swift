import Combine
import Foundation

@MainActor final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults?
    @Published var newestFirst: Bool {
        didSet { defaults?.set(newestFirst, forKey: "library.newestFirst") }
    }

    @Published var darkMode: Bool {
        didSet { defaults?.set(darkMode, forKey: "appearance.darkMode") }
    }

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
        defaults?.register(defaults: ["library.newestFirst": true, "appearance.darkMode": true])
        newestFirst = defaults?.bool(forKey: "library.newestFirst") ?? true
        darkMode = defaults?.bool(forKey: "appearance.darkMode") ?? true
    }
}
