import XCTest
@testable import SerialShelf

final class AnalysisTests: XCTestCase {
    private func entry() -> LibraryEntry {
        let show = Show(id: 1, name: "Swift", year: "2020", genres: [], summary: "",
            runtime: 45, rating: nil, imageURL: nil, sourceURL: "https://www.tvmaze.com")
        var entry = LibraryEntry(show: show)
        entry.status = .finished; entry.personalRating = 8; entry.watchedEpisodes = 10
        return entry
    }
    func testStatisticsAndSearch() throws {
        let values = [entry()]
        XCTAssertEqual(try ShelfAnalysis.statistics(values), ShelfStatistics(total: 1, finished: 1, minutes: 450, average: 8))
        XCTAssertNil(try ShelfAnalysis.statistics([]).average)
        XCTAssertEqual(try ShelfAnalysis.search(values, query: " swift ").count, 1)
        XCTAssertTrue(try ShelfAnalysis.search(values, query: "absent").isEmpty)
    }
    @MainActor func testWorkersReturnResults() async {
        let model = AnalysisViewModel()
        await model.calculate([entry()]); await model.search([entry()], query: "swift")
        XCTAssertEqual(model.statistics?.minutes, 450)
        XCTAssertEqual(model.matches.count, 1)
        XCTAssertFalse(model.searching); XCTAssertFalse(model.calculating)
    }
}
