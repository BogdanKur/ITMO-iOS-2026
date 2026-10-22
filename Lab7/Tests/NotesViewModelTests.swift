import XCTest
@testable import StudyNotes

final class NotesViewModelTests: XCTestCase {
    @MainActor func testCRUDPreservesIdentityAndReloadsSavedData() async throws {
        // Arrange: a real in-memory repository, without SwiftUI or a database.
        let repository = MemoryNoteRepository()
        let model = NotesViewModel(repository: repository)
        XCTAssertTrue(model.notes.isEmpty)

        // Act and assert: create, read through another ViewModel, update, delete.
        XCTAssertTrue(model.save(title: "  Swift  ", body: "Original"))
        let created = try XCTUnwrap(model.notes.first)
        XCTAssertEqual(created.title, "Swift")
        XCTAssertEqual(NotesViewModel(repository: repository).notes, [created])

        XCTAssertTrue(model.save(id: created.id, title: "Updated", body: "Changed"))
        let updated = try XCTUnwrap(model.notes.first)
        XCTAssertEqual(model.notes.count, 1)
        XCTAssertEqual(updated.id, created.id)
        XCTAssertEqual(updated.createdAt, created.createdAt)
        XCTAssertEqual(updated.title, "Updated")
        XCTAssertEqual(updated.body, "Changed")
        XCTAssertEqual(try repository.fetch(), [updated])

        model.delete(updated)
        XCTAssertTrue(model.notes.isEmpty)
        XCTAssertTrue(try repository.fetch().isEmpty)
        XCTAssertNil(model.errorMessage)
    }

    @MainActor func testValidationRejectsInvalidTitlesAndAcceptsBoundary() async throws {
        let repository = MemoryNoteRepository()
        let model = NotesViewModel(repository: repository)

        XCTAssertFalse(model.save(title: " \n\t", body: "Text"))
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(try repository.fetch().isEmpty)

        XCTAssertFalse(model.save(title: String(repeating: "я", count: 101), body: "Text"))
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.notes.isEmpty)
        XCTAssertTrue(try repository.fetch().isEmpty)

        XCTAssertTrue(model.save(title: String(repeating: "я", count: 100), body: "Text"))
        XCTAssertEqual(model.notes.count, 1)
        XCTAssertEqual(model.notes.first?.title.count, 100)
        XCTAssertNil(model.errorMessage)
    }

    @MainActor func testStorageErrorsAreReportedAndRecoveryKeepsDataConsistent() async throws {
        let repository = FaultInjectingRepository()
        repository.failingOperation = .read
        let model = NotesViewModel(repository: repository)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.notes.isEmpty)

        repository.failingOperation = nil
        model.reload()
        XCTAssertNil(model.errorMessage)

        repository.failingOperation = .save
        XCTAssertFalse(model.save(title: "Valid", body: "Text"))
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.notes.isEmpty)
        XCTAssertTrue(repository.records.isEmpty)

        repository.failingOperation = nil
        XCTAssertTrue(model.save(title: "Valid", body: "Text"))
        let saved = try XCTUnwrap(model.notes.first)
        repository.failingOperation = .delete
        model.delete(saved)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.notes, [saved])
        XCTAssertEqual(repository.records[saved.id], saved)

        repository.failingOperation = nil
        model.delete(saved)
        XCTAssertTrue(model.notes.isEmpty)
        XCTAssertTrue(repository.records.isEmpty)
        XCTAssertNil(model.errorMessage)
    }
}

@MainActor private final class FaultInjectingRepository: NoteRepository {
    enum Operation: Equatable { case read, save, delete }
    struct StorageFailure: LocalizedError {
        var errorDescription: String? { "Тестовая ошибка хранилища" }
    }
    var failingOperation: Operation?
    private(set) var records: [UUID: Note] = [:]

    func fetch() throws -> [Note] {
        if failingOperation == .read { throw StorageFailure() }
        return Array(records.values)
    }
    func save(_ note: Note) throws {
        if failingOperation == .save { throw StorageFailure() }
        records[note.id] = note
    }
    func delete(id: UUID) throws {
        if failingOperation == .delete { throw StorageFailure() }
        records[id] = nil
    }
}
