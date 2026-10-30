import XCTest

final class ChessChildUITests: XCTestCase {
    func testBoardAppearsOnLaunch() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["CỜ VUA CỦA BÉ"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Ô e2, Tốt trắng"].exists)
    }
}
