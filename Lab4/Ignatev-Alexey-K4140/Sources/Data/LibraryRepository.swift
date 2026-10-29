import Foundation

@MainActor protocol LibraryRepository {
    func fetch() throws -> [LibraryEntry]
    func save(_ entry: LibraryEntry) throws
    func delete(id: Int) throws
}

@MainActor final class MemoryLibraryRepository: LibraryRepository {
    private var entries: [Int: LibraryEntry] = [:]
    func fetch() throws -> [LibraryEntry] {
        Array(entries.values)
    }

    func save(_ entry: LibraryEntry) throws {
        entries[entry.id] = entry
    }

    func delete(id: Int) throws {
        entries[id] = nil
    }
}
