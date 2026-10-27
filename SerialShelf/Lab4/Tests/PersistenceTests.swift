import XCTest
@testable import SerialShelf

final class PersistenceTests: XCTestCase {
    @MainActor func testSwiftDataCreateUpdateDelete() async throws {
        let repository = try SwiftDataLibraryRepository(inMemory: true)
        let show = Show(id: 42, name: "Test", year: "2020", genres: [], summary: "",
            runtime: 40, rating: nil, imageURL: nil, sourceURL: "https://www.tvmaze.com")
        var entry = LibraryEntry(show: show)
        try repository.save(entry)
        XCTAssertEqual(try repository.fetch(), [entry])
        entry.personalRating = 7; entry.status = .watching
        try repository.save(entry)
        XCTAssertEqual(try repository.fetch(), [entry])
        try repository.delete(id: entry.id)
        XCTAssertTrue(try repository.fetch().isEmpty)
    }

    @MainActor func testSettingsRecreation() async throws {
        let name = "SerialShelfTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.newestFirst)
        store.newestFirst = false; store.darkMode = false
        let reopened = SettingsStore(defaults: defaults)
        XCTAssertFalse(reopened.newestFirst); XCTAssertFalse(reopened.darkMode)
    }
}
