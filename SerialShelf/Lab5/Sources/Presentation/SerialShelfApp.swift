import SwiftUI

@main @MainActor struct SerialShelfApp: App {
    @StateObject private var settings: SettingsStore
    @StateObject private var library: LibraryViewModel
    private let shows: [Show]
    private let startupError: String?

    init() {
        _settings = StateObject(wrappedValue: SettingsStore(defaults: .standard))
        do {
            let loaded = try LocalCatalog.load()
            let repository = try SwiftDataLibraryRepository()
            shows = loaded
            _library = StateObject(wrappedValue: LibraryViewModel(repository: repository))
            startupError = nil
        } catch {
            shows = []
            _library = StateObject(wrappedValue: LibraryViewModel(repository: MemoryLibraryRepository()))
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let startupError {
                    ContentUnavailableView("Не удалось открыть данные", systemImage: "externaldrive.badge.exclamationmark",
                        description: Text(startupError + " Данные не удалены. Перезапусти приложение."))
                } else { RootView(library: library, shows: shows) }
            }
            .environmentObject(settings).tint(ShelfStyle.accent)
            .preferredColorScheme(settings.darkMode ? .dark : .light)
        }
    }
}

struct RootView: View {
    @ObservedObject var library: LibraryViewModel
    let shows: [Show]
    var body: some View {
        TabView {
            NavigationStack {
                CatalogView(library: library, shows: shows)
            }.tabItem { Label("Каталог", systemImage: "square.grid.2x2") }
            NavigationStack { LibraryView(model: library) }
                .tabItem { Label("Моя полка", systemImage: "bookmark") }
            NavigationStack { AnalysisView(entries: library.entries) }.tabItem { Label("Статистика", systemImage: "chart.bar") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Настройки", systemImage: "slider.horizontal.3") }
        }
        .alert("Не удалось выполнить действие", isPresented: Binding(get: { library.errorMessage != nil },
            set: { if !$0 { library.errorMessage = nil } })) {
                Button("OK") { library.errorMessage = nil }
            } message: { Text(library.errorMessage ?? "") }
    }
}
