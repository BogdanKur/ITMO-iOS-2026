import Foundation
import SwiftData

@Model final class StoredEntry {
    @Attribute(.unique) var showID: Int
    var payload: Data
    init(entry: LibraryEntry) throws {
        showID = entry.id
        payload = try JSONEncoder().encode(entry)
    }
}

@MainActor final class SwiftDataLibraryRepository: LibraryRepository {
    let container: ModelContainer
    private let context: ModelContext

    init(inMemory: Bool = false) throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(for: StoredEntry.self, configurations: config)
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    func fetch() throws -> [LibraryEntry] {
        try context.fetch(FetchDescriptor<StoredEntry>()).map {
            try JSONDecoder().decode(LibraryEntry.self, from: $0.payload)
        }
    }

    func save(_ entry: LibraryEntry) throws {
        try EntryValidator.validate(entry)
        do {
            let id = entry.id
            let query = FetchDescriptor<StoredEntry>(predicate: #Predicate { $0.showID == id })
            if let stored = try context.fetch(query).first {
                stored.payload = try JSONEncoder().encode(entry)
            } else {
                context.insert(try StoredEntry(entry: entry))
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func delete(id: Int) throws {
        do {
            let query = FetchDescriptor<StoredEntry>(predicate: #Predicate { $0.showID == id })
            if let stored = try context.fetch(query).first {
                context.delete(stored)
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
