import XCTest
@testable import ChessChild

final class ChessChildTests: XCTestCase {
    @MainActor
    func testPlayingBlackLetsComputerOpen() {
        let game = GameSession()
        game.setPlayerSide(.black)

        XCTAssertEqual(game.position.turn, .white)
        XCTAssertNotNil(game.computerMove())
        XCTAssertNil(game.select(52))
        XCTAssertFalse(game.canUndo)
    }
}
