import XCTest
@testable import SerialShelf

final class LibraryTests: XCTestCase {
    let show = Show(id: 1, name: "Test Show", year: "2020", genres: ["Drama"],
        summary: "Story", runtime: 45, rating: 8, imageURL: nil, sourceURL: "https://www.tvmaze.com")

    @MainActor func testCRUDAndDuplicateProtection() async throws {
        let repository = MemoryLibraryRepository()
        let model = LibraryViewModel(repository: repository)
        XCTAssertTrue(model.add(show))
        XCTAssertFalse(model.add(show))
        var draft = try XCTUnwrap(model.entries.first)
        let addedAt = draft.addedAt
        draft.status = .finished; draft.personalRating = 9
        draft.watchedEpisodes = 12; draft.review = "  Great story  "
        XCTAssertTrue(model.update(draft))
        let saved = try XCTUnwrap(model.entries.first)
        XCTAssertEqual(model.entries.count, 1)
        XCTAssertEqual(saved.id, show.id)
        XCTAssertEqual(saved.addedAt, addedAt)
        XCTAssertEqual(saved.review, "Great story")
        XCTAssertEqual(LibraryViewModel(repository: repository).entries, [saved])
        model.delete(id: show.id)
        XCTAssertTrue(try repository.fetch().isEmpty)
        XCTAssertTrue(model.entries.isEmpty)
    }

    @MainActor func testValidationBoundaries() async throws {
        let repository = MemoryLibraryRepository()
        let model = LibraryViewModel(repository: repository)
        XCTAssertTrue(model.add(show))
        var draft = try XCTUnwrap(model.entries.first)
        for value in [-1, 11] {
            draft.personalRating = value
            XCTAssertFalse(model.update(draft))
            XCTAssertEqual(model.entries.first?.personalRating, 0)
        }
        draft.personalRating = 10; draft.watchedEpisodes = -1
        XCTAssertFalse(model.update(draft))
        draft.watchedEpisodes = 10001
        XCTAssertFalse(model.update(draft))
        draft.watchedEpisodes = 10000; draft.review = String(repeating: "я", count: 2001)
        XCTAssertFalse(model.update(draft))
        draft.review = String(repeating: "я", count: 2000)
        XCTAssertTrue(model.update(draft))
        XCTAssertNil(model.errorMessage)
    }

    @MainActor func testRepositoryErrorsAndRecovery() async throws {
        let repository = FaultRepository()
        repository.failure = .read
        let model = LibraryViewModel(repository: repository)
        XCTAssertNotNil(model.errorMessage)
        repository.failure = nil; model.reload()
        XCTAssertNil(model.errorMessage)
        repository.failure = .save
        XCTAssertFalse(model.add(show)); XCTAssertTrue(model.entries.isEmpty)
        repository.failure = nil
        XCTAssertTrue(model.add(show))
        repository.failure = .delete
        model.delete(id: show.id)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.entries.count, 1)
        repository.failure = nil
        model.delete(id: show.id)
        XCTAssertTrue(model.entries.isEmpty)
        XCTAssertNil(model.errorMessage)
    }
}

@MainActor private final class FaultRepository: LibraryRepository {
    enum Operation { case read, save, delete }
    struct Failure: Error {}
    var failure: Operation?
    private var records: [Int: LibraryEntry] = [:]
    func fetch() throws -> [LibraryEntry] {
        if failure == .read { throw Failure() }; return Array(records.values)
    }
    func save(_ entry: LibraryEntry) throws {
        if failure == .save { throw Failure() }; records[entry.id] = entry
    }
    func delete(id: Int) throws {
        if failure == .delete { throw Failure() }; records[id] = nil
    }
}
