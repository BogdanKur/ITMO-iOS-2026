import SwiftData
import Foundation
@Model final class StoredNote {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date
    init(_ note: Note) {
        id = note.id; title = note.title; body = note.body
        createdAt = note.createdAt; updatedAt = note.updatedAt
    }
    var value: Note { Note(id: id, title: title, body: body, createdAt: createdAt, updatedAt: updatedAt) }
}
@MainActor final class SwiftDataNoteRepository: NoteRepository {
    let container: ModelContainer
    private let context: ModelContext
    init(inMemory: Bool = false) throws {
        container = try ModelContainer(for: StoredNote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory))
        context = ModelContext(container)
        context.autosaveEnabled = false
    }
    func fetch() throws -> [Note] { try context.fetch(FetchDescriptor<StoredNote>()).map(\.value) }
    func save(_ note: Note) throws {
        do {
            if let stored = try find(note.id) {
                stored.title = note.title; stored.body = note.body; stored.updatedAt = note.updatedAt
            } else { context.insert(StoredNote(note)) }
            try context.save()
        } catch { context.rollback(); throw error }
    }
    func delete(id: UUID) throws {
        do {
            if let stored = try find(id) { context.delete(stored); try context.save() }
        } catch { context.rollback(); throw error }
    }
    private func find(_ id: UUID) throws -> StoredNote? {
        let descriptor = FetchDescriptor<StoredNote>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}
