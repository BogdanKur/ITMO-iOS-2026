import XCTest
@testable import StudyNotes
final class AnalysisTests: XCTestCase {
    let notes = [Note(title: "Swift", body: "hello world"), Note(title: "Учёба", body: "Swift async")]
    func testSearchMatchesTitleAndBodyIgnoringCaseAndWhitespace() throws {
        XCTAssertEqual(try NoteAnalysis.search(notes, query: " swift ").count, 2)
        XCTAssertEqual(try NoteAnalysis.search(notes, query: "HELLO").first?.title, "Swift")
        XCTAssertEqual(try NoteAnalysis.search(notes, query: "absent"), [])
        XCTAssertEqual(try NoteAnalysis.search(notes, query: " ").count, 2)
    }
    func testStatisticsEmptyAndNonEmpty() throws {
        XCTAssertEqual(try NoteAnalysis.statistics([]), NoteStatistics(noteCount: 0, wordCount: 0, characterCount: 0))
        XCTAssertEqual(try NoteAnalysis.statistics(notes), NoteStatistics(noteCount: 2, wordCount: 6, characterCount: 32))
    }
    @MainActor func testResultsReturnToMainActor() async {
        let vm = AnalysisViewModel()
        await vm.search(notes: notes, query: "hello")
        XCTAssertEqual(vm.matches.count, 1); XCTAssertFalse(vm.searching)
        await vm.calculate(notes: notes)
        XCTAssertEqual(vm.statistics?.noteCount, 2); XCTAssertFalse(vm.calculating)
    }
    func testCancelledWorkerStops() async {
        let task = Task.detached {
            withUnsafeCurrentTask { $0?.cancel() }
            return try NoteAnalysis.statistics([Note(title: "a", body: "b")])
        }
        do { _ = try await task.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
    }
}
