import XCTest

final class StudyNotesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor func testNoteCRUDAndPersistenceAfterRelaunch() throws {
        let app = launchApp()
        let title = "Lab7 " + UUID().uuidString.prefix(8)
        capture("01-list", app)

        app.buttons["Добавить заметку"].tap()
        let titleField = app.textFields["noteTitle"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(String(title))
        let body = app.textViews["noteBody"]
        body.tap()
        body.typeText("Original body")
        capture("02-editor", app)
        app.buttons["Сохранить"].tap()

        let row = app.staticTexts[String(title)]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.buttons["Изменить"].waitForExistence(timeout: 5))
        app.buttons["Изменить"].tap()
        let editor = app.textViews["noteBody"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(" updated")
        app.buttons["Сохранить"].tap()

        let detail = app.staticTexts["detailBody"]
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertTrue(detail.label.contains("updated"))
        let expectedBody = detail.label
        capture("03-updated-detail", app)

        app.terminate()
        app.launch()
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertEqual(detail.label, expectedBody)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Удалить"].tap()
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: row)
        wait(for: [removed], timeout: 5)
    }

    @MainActor func testSortSettingPersistsAfterRelaunch() throws {
        let app = launchApp()
        app.tabBars.buttons["Настройки"].tap()
        let control = app.switches["Сначала новые"]
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        let original = try XCTUnwrap(control.value as? String)
        XCTAssertTrue(["0", "1"].contains(original))
        let changedValue = original == "1" ? "0" : "1"
        setSwitch(control, expectedValue: changedValue)
        capture("04-settings-changed", app)

        // Reproduce normal closing: background the app, then terminate and launch it.
        XCUIDevice.shared.press(.home)
        app.terminate()
        app.launch()
        app.tabBars.buttons["Настройки"].tap()
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        XCTAssertEqual(control.value as? String, changedValue)
        capture("05-settings-restored", app)

        // This test leaves the original preference intact and can run independently.
        setSwitch(control, expectedValue: original)
    }

    @MainActor private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["StudyNotes"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor private func setSwitch(_ control: XCUIElement, expectedValue: String) {
        // SwiftUI exposes the label and thumb as one accessibility element.
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let changed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expectedValue), object: control)
        wait(for: [changed], timeout: 5)
        XCTAssertEqual(control.value as? String, expectedValue)
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
