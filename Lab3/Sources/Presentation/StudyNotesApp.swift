import SwiftUI
@main @MainActor struct StudyNotesApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var model: NotesViewModel
    private let startupError: String?
    init() {
        do {
            let repository = MemoryNoteRepository()
            _model = StateObject(wrappedValue: NotesViewModel(repository: repository))
            startupError = nil
        }
    }
    var body: some Scene {
        WindowGroup {
            if let startupError {
                ContentUnavailableView("Хранилище недоступно", systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(startupError + " Перезапустите приложение. Данные не удалены."))
            } else { RootView(model: model).environmentObject(settings) }
        }
    }
}
