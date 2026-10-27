import XCTest
@testable import SerialShelf
final class RecommendationTests: XCTestCase {
    func testRandomNumberRange() { for _ in 0..<1000 { XCTAssertTrue((1...100).contains(NumberGenerator.generate())) } }
    func testShowRoundTrip() throws {
        let value = Show(id: 1, name: "Test", year: "2020", genres: [], summary: "", runtime: 45,
            rating: nil, imageURL: nil, sourceURL: "https://www.tvmaze.com")
        XCTAssertEqual(try JSONDecoder().decode(Show.self, from: JSONEncoder().encode(value)), value)
    }

}
