import Foundation
import Combine

@MainActor final class LibraryViewModel: ObservableObject {
    @Published private(set) var entries: [LibraryEntry] = []
    @Published var errorMessage: String?
    private let repository: any LibraryRepository

    init(repository: any LibraryRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            entries = try repository.fetch().sorted {
                $0.addedAt > $1.addedAt
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func contains(_ show: Show) -> Bool {
        entries.contains {
            $0.id == show.id
        }
    }

    @discardableResult func add(_ show: Show) -> Bool {
        guard !contains(show) else {
            errorMessage = LibraryError.duplicate.localizedDescription
            return false
        }
        return persist(LibraryEntry(show: show))
    }

    @discardableResult func update(_ draft: LibraryEntry) -> Bool {
        guard let original = entries.first(where: {
            $0.id == draft.id
        }) else {
            errorMessage = LibraryError.missing.localizedDescription
            return false
        }
        var entry = original
        entry.status = draft.status
        entry.personalRating = draft.personalRating
        entry.watchedEpisodes = draft.watchedEpisodes
        entry.review = draft.review.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.updatedAt = Date()
        return persist(entry)
    }

    private func persist(_ entry: LibraryEntry) -> Bool {
        do {
            try EntryValidator.validate(entry)
            try repository.save(entry)
            reload()
            return errorMessage == nil
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(id: Int) {
        do {
            try repository.delete(id: id)
            reload()
        }
        catch {
            errorMessage = error.localizedDescription
        }
    }
}
