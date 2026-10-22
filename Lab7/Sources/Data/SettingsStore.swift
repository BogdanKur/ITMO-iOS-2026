import Foundation
import Combine
@MainActor final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults
    static let sortKey = "notes.newestFirst"
    @Published var newestFirst: Bool {
        didSet { defaults.set(newestFirst, forKey: Self.sortKey) }
    }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Self.sortKey: true])
        newestFirst = defaults.bool(forKey: Self.sortKey)
    }
}
