import XCTest
@testable import StudyNotes
final class NotesTests: XCTestCase {
    func testTitleValidationTrimsWhitespace() throws {
        XCTAssertEqual(try NoteValidator.title("  Учёба \n"), "Учёба")
        XCTAssertEqual(try NoteValidator.title(String(repeating: "я", count: 100)).count, 100)
        XCTAssertThrowsError(try NoteValidator.title(" \n\t"))
        XCTAssertThrowsError(try NoteValidator.title(String(repeating: "я", count: 101)))
    }
    @MainActor func testCreateReadUpdateDelete() async throws {
        let repo = MemoryNoteRepository(), model = NotesViewModel(repository: MemoryNoteRepository())
        let vm = NotesViewModel(repository: repo)
        XCTAssertTrue(vm.notes.isEmpty)
        XCTAssertTrue(vm.save(title: "  Swift ", body: "one"))
        let note = try XCTUnwrap(vm.notes.first)
        XCTAssertEqual(note.title, "Swift")
        XCTAssertTrue(vm.save(id: note.id, title: "Updated", body: "two"))
        XCTAssertEqual(vm.notes.count, 1)
        XCTAssertEqual(vm.notes.first?.createdAt, note.createdAt)
        XCTAssertEqual(vm.notes.first?.body, "two")
        XCTAssertEqual(try repo.fetch().first?.title, "Updated")
        vm.delete(try XCTUnwrap(vm.notes.first))
        XCTAssertTrue(vm.notes.isEmpty)
        XCTAssertTrue(model.notes.isEmpty)
    }
    @MainActor func testInvalidNoteDoesNotReachRepository() async {
        let vm = NotesViewModel(repository: MemoryNoteRepository())
        XCTAssertFalse(vm.save(title: "   ", body: "test"))
        XCTAssertNotNil(vm.errorMessage); XCTAssertTrue(vm.notes.isEmpty)
    }
    @MainActor func testRepositoryFailuresArePresented() async {
        let vm = NotesViewModel(repository: FailingRepository())
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.save(title: "Valid", body: "body"))
        vm.delete(Note(title: "Test", body: ""))
        XCTAssertNotNil(vm.errorMessage)
    }
}
@MainActor private final class FailingRepository: NoteRepository {
    struct Failure: Error {}
    func fetch() throws -> [Note] { throw Failure() }
    func save(_ note: Note) throws { throw Failure() }
    func delete(id: UUID) throws { throw Failure() }
}
