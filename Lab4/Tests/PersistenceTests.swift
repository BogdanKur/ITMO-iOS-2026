import XCTest
@testable import StudyNotes
final class PersistenceTests: XCTestCase {
    @MainActor func testSwiftDataCRUD() async throws {
        let repo = try SwiftDataNoteRepository(inMemory: true)
        var note = Note(title: "Original", body: "one")
        try repo.save(note)
        XCTAssertEqual(try repo.fetch(), [note])
        note.title = "Changed"; note.body = "two"
        try repo.save(note)
        XCTAssertEqual(try repo.fetch(), [note])
        try repo.delete(id: note.id)
        XCTAssertTrue(try repo.fetch().isEmpty)
        try repo.delete(id: note.id)
    }
    @MainActor func testSettingsSurviveStoreRecreation() async throws {
        let suite = "StudyNotesTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = SettingsStore(defaults: defaults)
        XCTAssertTrue(first.newestFirst)
        first.newestFirst = false
        XCTAssertFalse(SettingsStore(defaults: defaults).newestFirst)
    }
}
