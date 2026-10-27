import XCTest

final class ShelfVideoDriver: XCTestCase {
    let lab = LAB_NUMBER
    @MainActor func testDemonstration() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        if lab < 6 { app.launchArguments = ["--ui-testing"] }
        app.launch()
        if lab == 2 {
            let generate = app.buttons["generateButton"]
            XCTAssertTrue(generate.waitForExistence(timeout: 20))
            sleep(3); generate.tap(); sleep(3); generate.tap(); sleep(3)
            app.buttons["recommendationLink"].tap(); sleep(5)
            app.swipeUp(); sleep(3)
            app.navigationBars.buttons.element(boundBy: 0).tap(); sleep(2)
            return
        }
        if lab >= 6 {
            let search = app.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 20))
            search.tap(); search.typeText("Breaking Bad")
            app.keyboards.buttons["Search"].tap()
        }
        let show = app.buttons["show-169"]
        XCTAssertTrue(show.waitForExistence(timeout: 35)); sleep(3); show.tap()
        let add = app.buttons["addToLibrary"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        sleep(3)
        if add.isEnabled { add.tap() }
        app.swipeUp(); sleep(3)
        if lab >= 6 {
            let field = app.textFields["networkReview"]
            for _ in 0..<3 { if !field.isHittable { app.swipeUp() } }
            XCTAssertTrue(field.waitForExistence(timeout: 8)); field.tap()
            field.typeText("Great story and characters")
            app.buttons["sendReview"].tap()
            let receipt = app.staticTexts["postReceipt"]
            XCTAssertTrue(receipt.waitForExistence(timeout: 30))
            sleep(4)
        }
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Моя полка"].tap()
        let row = app.buttons["entry-169"]
        XCTAssertTrue(row.waitForExistence(timeout: 10)); sleep(2); row.tap()
        app.buttons["Изменить"].tap(); sleep(3)
        let picker = app.buttons["watchStatus"]
        if picker.exists {
            picker.tap(); app.buttons["Просмотрено"].tap()
        }
        let rating = app.steppers["personalRating"]
        if rating.exists {
            for _ in 0..<8 { rating.buttons.element(boundBy: 1).tap() }
        }
        let episodes = app.steppers["watchedEpisodes"]
        if episodes.exists { for _ in 0..<3 { episodes.buttons.element(boundBy: 1).tap() } }
        let review = app.textViews["reviewEditor"]
        XCTAssertTrue(review.waitForExistence(timeout: 5)); review.tap(); review.typeText("A story worth watching")
        sleep(2); app.buttons["Сохранить"].tap(); sleep(3)
        if lab >= 4 {
            app.terminate(); app.launch(); app.tabBars.buttons["Моя полка"].tap()
            XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap(); sleep(3)
        }
        app.navigationBars.buttons.element(boundBy: 0).tap()
        if lab >= 5 {
            app.tabBars.buttons["Статистика"].tap(); sleep(5)
            let search = app.searchFields.firstMatch
            if search.exists {
                search.tap(); search.typeText("Breaking"); sleep(3)
                if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
                else if app.buttons["Close"].exists { app.buttons["Close"].tap() }
                else if app.buttons["Отменить"].exists { app.buttons["Отменить"].tap() }
            }
        }
        app.tabBars.buttons["Настройки"].tap(); sleep(4)
        let control = app.switches["newestFirst"]
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap(); sleep(3)
        // CRUD deletion is already asserted by the normal suite; the video ends on settings.
    }
}
