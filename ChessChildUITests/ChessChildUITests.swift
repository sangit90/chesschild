import XCTest

final class ChessChildUITests: XCTestCase {
    func testBoardAppearsOnLaunch() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["CỜ VUA CỦA BÉ"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Ô e2, Tốt trắng"].exists)
    }

    func testNewGameRequiresConfirmation() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Ô e2, Tốt trắng"].tap()
        app.buttons["Ô e4, trống"].tap()
        XCTAssertTrue(app.buttons["Ô e4, Tốt trắng"].waitForExistence(timeout: 5))

        app.buttons["Ván mới"].tap()
        let confirmation = app.alerts["Bắt đầu ván mới?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Hủy"].tap()
        XCTAssertTrue(app.buttons["Ô e4, Tốt trắng"].exists)

        app.buttons["Ván mới"].tap()
        app.alerts["Bắt đầu ván mới?"].buttons["Ván mới"].tap()
        XCTAssertTrue(app.buttons["Ô e2, Tốt trắng"].waitForExistence(timeout: 5))
    }
}
