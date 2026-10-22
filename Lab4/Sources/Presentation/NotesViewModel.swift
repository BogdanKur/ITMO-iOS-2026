import Foundation
import Combine
@MainActor final class NotesViewModel: ObservableObject {
    @Published private(set) var notes: [Note] = []
    @Published var errorMessage: String?
    private let repository: any NoteRepository
    init(repository: any NoteRepository) { self.repository = repository; reload() }
    func reload() {
        do { notes = try repository.fetch().sorted { $0.updatedAt > $1.updatedAt }; errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
    @discardableResult func save(id: UUID? = nil, title: String, body: String) -> Bool {
        do {
            let title = try NoteValidator.title(title)
            let existing = notes.first { $0.id == id }
            let note = Note(id: id ?? UUID(), title: title, body: body,
                createdAt: existing?.createdAt ?? Date(), updatedAt: Date())
            try repository.save(note); reload()
            return errorMessage == nil
        } catch { errorMessage = error.localizedDescription; return false }
    }
    func delete(_ note: Note) {
        do { try repository.delete(id: note.id); reload() }
        catch { errorMessage = error.localizedDescription }
    }
}
