import XCTest

final class SerialShelfUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor func testCollectionCRUDAndRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        app.tabBars.buttons["Каталог"].tap()
        let card = app.buttons["show-169"]
        XCTAssertTrue(card.waitForExistence(timeout: 15)); card.tap()
        let add = app.buttons["addToLibrary"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        if add.isEnabled {
            add.tap()
        }
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Моя полка"].tap()
        let row = app.buttons["entry-169"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        app.buttons["Изменить"].tap()
        let editor = app.textViews["reviewEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5)); editor.tap()
        editor.typeText("Great story")
        app.buttons["Сохранить"].tap()
        let review = app.staticTexts["savedReview"]
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        let expected = review.label
        app.terminate(); app.launch()
        app.tabBars.buttons["Моя полка"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()
        XCTAssertEqual(review.label, expected)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        row.swipeLeft(); app.buttons["Удалить"].tap()
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: row)
        wait(for: [removed], timeout: 5)
    }

    @MainActor func testSettingsPersistAfterRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch(); app.tabBars.buttons["Настройки"].tap()
        let control = app.switches["newestFirst"]
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        let original = try XCTUnwrap(control.value as? String)
        let changed = original == "1" ? "0" : "1"
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", changed),
            object: control
        )
        wait(for: [expectation], timeout: 5)
        XCUIDevice.shared.press(.home); app.terminate(); app.launch()
        app.tabBars.buttons["Настройки"].tap()
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        XCTAssertEqual(control.value as? String, changed)
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    }
}
