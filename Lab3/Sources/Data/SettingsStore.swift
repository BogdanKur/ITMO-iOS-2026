import Foundation
import Combine
@MainActor final class SettingsStore: ObservableObject {
    @Published var newestFirst: Bool = true
}
