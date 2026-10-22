import XCTest
@testable import StudyNotes
final class NumberGeneratorTests: XCTestCase {
    func testNumbersBelongToDocumentedRange() {
        for _ in 0..<1000 { XCTAssertTrue((1...100).contains(NumberGenerator.generate())) }
    }
}
