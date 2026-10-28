import Foundation

func assertMove(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

var game = ChessPosition.initial()
assertMove(game.legalMoves().count == 20, "Initial position must have 20 legal moves")
assertMove(game.legalMoves(from: 52).contains(where: { $0.to == 36 }), "White pawn e2-e4")

func play(_ from: Int, _ to: Int) {
    guard let move = game.legalMoves(from: from).first(where: { $0.to == to }) else {
        fatalError("Illegal test move \(from)-\(to)")
    }
    game.apply(move)
}

// Fool's mate: f3, e5, g4, Qh4#.
play(53, 45)
play(12, 28)
play(54, 38)
play(3, 39)
assertMove(game.inCheck(.white), "White king should be in check")
assertMove(game.legalMoves().isEmpty, "Fool's mate should have no legal replies")
assertMove(game.result != nil, "Checkmate should finish the game")

var special = ChessPosition()
special.squares[60] = Piece(side: .white, kind: .king)
special.squares[63] = Piece(side: .white, kind: .rook)
special.squares[4] = Piece(side: .black, kind: .king)
assertMove(special.legalMoves(from: 60).contains(where: { $0.to == 62 && $0.isCastle }), "Castling")

special = ChessPosition()
special.squares[60] = Piece(side: .white, kind: .king)
special.squares[4] = Piece(side: .black, kind: .king)
special.squares[28] = Piece(side: .white, kind: .pawn)
special.squares[27] = Piece(side: .black, kind: .pawn)
special.enPassant = 19
assertMove(special.legalMoves(from: 28).contains(where: { $0.to == 19 && $0.isEnPassant }), "En passant")

special = ChessPosition()
special.squares[60] = Piece(side: .white, kind: .king)
special.squares[4] = Piece(side: .black, kind: .king)
special.squares[8] = Piece(side: .white, kind: .pawn)
assertMove(special.legalMoves(from: 8).contains(where: { $0.to == 0 && $0.promotion == .queen }), "Promotion")

print("Chess rules verified")
