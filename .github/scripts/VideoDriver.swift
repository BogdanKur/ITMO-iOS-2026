// Used only by the disposable recording project on the cloud Mac.
// This drives the unchanged app through its actual controls.
import XCTest

final class VideoDriver: XCTestCase {
    let lab = LAB_NUMBER
    @MainActor func testRecordApplicationFlow() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        sleep(4)
        if lab == 2 {
            XCTAssertTrue(app.buttons["generateButton"].waitForExistence(timeout: 15))
            app.buttons["generateButton"].tap(); sleep(3)
            app.buttons["generateButton"].tap(); sleep(3)
            app.buttons["На второй экран"].tap(); sleep(5)
            app.navigationBars.buttons.element(boundBy: 0).tap(); sleep(3)
            return
        }
        XCTAssertTrue(app.navigationBars["StudyNotes"].waitForExistence(timeout: 15))
        let title = "Swift Lab \(lab)"
        app.buttons["Добавить заметку"].tap()
        let titleField = app.textFields["noteTitle"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap(); titleField.typeText(title)
        let body = app.textViews["noteBody"]
        body.tap(); body.typeText("Swift notes and application architecture")
        sleep(2)
        app.buttons["Сохранить"].tap(); sleep(3)
        let row = app.staticTexts[title]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap(); sleep(3)
        app.buttons["Изменить"].tap()
        let editor = app.textViews["noteBody"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap(); editor.typeText(" updated")
        app.buttons["Сохранить"].tap(); sleep(3)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        if lab >= 4 {
            XCUIDevice.shared.press(.home); sleep(2)
            app.terminate(); app.launch()
            XCTAssertTrue(row.waitForExistence(timeout: 10)); sleep(3)
            row.tap(); sleep(3)
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "updated")).firstMatch.exists)
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        app.tabBars.buttons["Настройки"].tap(); sleep(3)
        let sort = app.switches["Сначала новые"]
        XCTAssertTrue(sort.waitForExistence(timeout: 5))
        sort.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap(); sleep(3)
        if lab >= 4 {
            XCUIDevice.shared.press(.home); app.terminate(); app.launch()
            app.tabBars.buttons["Настройки"].tap(); sleep(3)
        }
        if lab >= 5 {
            app.tabBars.buttons["Анализ"].tap(); sleep(4)
            let search = app.searchFields.firstMatch
            if !search.exists { app.swipeDown() }
            if search.waitForExistence(timeout: 5) {
                search.tap(); search.typeText("Swift"); sleep(4)
                if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
                else if app.buttons["Отменить"].exists { app.buttons["Отменить"].tap() }
            }
        }
        if lab >= 6 {
            app.tabBars.buttons["Лента"].tap(); sleep(8)
            let firstPost = app.staticTexts["sunt aut facere repellat provident occaecati excepturi optio reprehenderit"]
            if firstPost.waitForExistence(timeout: 20) {
                firstPost.tap(); sleep(4)
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            let postTitle = app.textFields["Название"]
            XCTAssertTrue(postTitle.waitForExistence(timeout: 5))
            postTitle.tap(); postTitle.typeText("Swift network lab")
            let postBody = app.textFields["Текст"]
            if postBody.exists { postBody.tap(); postBody.typeText("GET and POST from iOS") }
            app.buttons["Отправить"].tap()
            let response = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Получен ответ:"))
            _ = response.firstMatch.waitForExistence(timeout: 25)
            sleep(5)
        }
        app.tabBars.buttons["Заметки"].tap(); sleep(2)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft(); sleep(2)
        app.buttons["Удалить"].tap(); sleep(4)
        XCTAssertFalse(row.exists)
    }
}
