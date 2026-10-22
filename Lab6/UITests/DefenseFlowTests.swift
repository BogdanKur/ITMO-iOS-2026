import XCTest

final class DefenseFlowTests: XCTestCase {
    @MainActor func testDefenseFlowAndPersistentStorage() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["StudyNotes"].waitForExistence(timeout: 15))
        capture("01-list", app)

        let title = "Defense " + UUID().uuidString.prefix(8)
        app.buttons["Добавить заметку"].tap()
        let titleField = app.textFields["noteTitle"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap(); titleField.typeText(String(title))
        let body = app.textViews["noteBody"]
        body.tap(); body.typeText("Swift concurrency and persistent notes")
        capture("02-editor", app)
        app.buttons["Сохранить"].tap()
        XCTAssertTrue(app.staticTexts[String(title)].waitForExistence(timeout: 5))
        app.staticTexts[String(title)].tap()
        XCTAssertTrue(app.buttons["Изменить"].waitForExistence(timeout: 5))
        capture("03-detail", app)
        app.buttons["Изменить"].tap()
        let editBody = app.textViews["noteBody"]
        XCTAssertTrue(editBody.waitForExistence(timeout: 5))
        editBody.tap(); editBody.typeText(" updated")
        app.buttons["Сохранить"].tap()
        XCTAssertTrue(app.staticTexts["Swift concurrency and persistent notes updated"].waitForExistence(timeout: 5))

        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts[String(title)].waitForExistence(timeout: 10))
        app.tabBars.buttons["Настройки"].tap()
        XCTAssertTrue(app.switches["Сначала новые"].waitForExistence(timeout: 5))
        capture("04-settings", app)
        let sort = app.switches["Сначала новые"]
        let previous = sort.value as? String
        sort.tap()
        app.terminate(); app.launch()
        app.tabBars.buttons["Настройки"].tap()
        XCTAssertTrue(sort.waitForExistence(timeout: 5))
        XCTAssertNotEqual(sort.value as? String, previous)
        sort.tap()

        app.tabBars.buttons["Анализ"].tap()
        XCTAssertTrue(app.navigationBars["Анализ"].waitForExistence(timeout: 5))
        capture("05-analysis", app)
        app.tabBars.buttons["Лента"].tap()
        XCTAssertTrue(app.navigationBars["Лента"].waitForExistence(timeout: 5))
        capture("06-network", app)

        app.tabBars.buttons["Заметки"].tap()
        let row = app.staticTexts[String(title)]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Удалить"].tap()
        XCTAssertFalse(row.exists)
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
