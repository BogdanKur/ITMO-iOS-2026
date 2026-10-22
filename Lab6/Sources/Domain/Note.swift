import Foundation
struct Note: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var body: String
    let createdAt: Date
    var updatedAt: Date
    init(id: UUID = UUID(), title: String, body: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.title = title; self.body = body
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}
enum NoteValidationError: LocalizedError {
    case emptyTitle, titleTooLong
    var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Введите название заметки."
        case .titleTooLong: return "Название должно содержать не более 100 символов."
        }
    }
}
enum NoteValidator {
    static func title(_ text: String) throws -> String {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw NoteValidationError.emptyTitle }
        guard value.count <= 100 else { throw NoteValidationError.titleTooLong }
        return value
    }
}
@MainActor protocol NoteRepository {
    func fetch() throws -> [Note]
    func save(_ note: Note) throws
    func delete(id: UUID) throws
}
@MainActor final class MemoryNoteRepository: NoteRepository {
    private var notes: [UUID: Note] = [:]
    func fetch() throws -> [Note] { Array(notes.values) }
    func save(_ note: Note) throws { notes[note.id] = note }
    func delete(id: UUID) throws { notes[id] = nil }
}
