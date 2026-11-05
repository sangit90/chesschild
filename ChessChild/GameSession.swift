import Combine
import Foundation

enum GameMode: Equatable {
    case computer
    case twoPlayers
}

@MainActor
final class GameSession: ObservableObject {
    private struct Snapshot {
        let position: ChessPosition
        let lessonStage: Int
        let stars: Int
    }
    @Published private(set) var position = ChessPosition.initial()
    @Published var selected: Int? = nil
    @Published var suggested: Move? = nil
    @Published var message = (AppLanguage.isVietnamese ? "Chạm vào một quân trắng để xem các nước đi nhé!" : "Tap a white piece to see its moves!")
    @Published var difficulty = 0
    @Published private(set) var mode: GameMode = .computer
    @Published private(set) var playerSide: Side = .white
    @Published private(set) var wins = UserDefaults.standard.integer(forKey: "chesschild.wins")
    @Published private(set) var games = UserDefaults.standard.integer(forKey: "chesschild.games")
    @Published private(set) var lessonStage = UserDefaults.standard.integer(forKey: "chesschild.lessonStage")
    @Published private(set) var stars = UserDefaults.standard.integer(forKey: "chesschild.stars")
    private var snapshots: [Snapshot] = []
    private var recordedResult = false
    private var hintChoices: [Move] = []
    private var nextHintIndex = 0

    var legalSelection: [Move] { selected.map { position.legalMoves(from: $0) } ?? [] }
    var canUndo: Bool {
        !snapshots.isEmpty && !(mode == .computer && playerSide == .black && snapshots.count == 1 && position.turn == .black)
    }
    var isFinished: Bool { position.result != nil }
    var resultMessage: String? {
        guard let result = position.result else { return nil }
        guard position.legalMoves().isEmpty && position.inCheck(position.turn) else { return result }
        if mode == .twoPlayers {
            return (AppLanguage.isVietnamese ? "Chiếu hết! Người chơi \(position.turn.opponent == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) thắng! 🎉" : "Checkmate! Player \(position.turn.opponent == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) wins! 🎉")
        }
        return position.turn.opponent == playerSide ? (AppLanguage.isVietnamese ? "Chiếu hết! Bé đã thắng rồi! 🎉" : "Checkmate! You won! 🎉") : (AppLanguage.isVietnamese ? "Máy thắng ván này. Mình thử lại nhé!" : "The computer won this game. Try again!")
    }
    var missionTitle: String {
        switch lessonStage {
        case 0: return (AppLanguage.isVietnamese ? "Đưa Tốt vào trung tâm" : "Move a pawn to the center")
        case 1: return (AppLanguage.isVietnamese ? "Đưa Mã ra khỏi hàng đầu" : "Develop a knight")
        case 2: return (AppLanguage.isVietnamese ? "Ăn một quân của máy" : "Capture a computer piece")
        case 3: return (AppLanguage.isVietnamese ? "Nhập thành để bảo vệ Vua" : "Castle to protect your king")
        default: return (AppLanguage.isVietnamese ? "Bé đã hoàn thành các thử thách đầu tiên!" : "You completed the first challenges!")
        }
    }
    var missionDetail: String {
        switch lessonStage {
        case 0: return playerSide == .white ? (AppLanguage.isVietnamese ? "Thử đưa Tốt đến ô d4 hoặc e4." : "Try moving a pawn to d4 or e4.") : (AppLanguage.isVietnamese ? "Thử đưa Tốt đến ô d5 hoặc e5." : "Try moving a pawn to d5 or e5.")
        case 1: return (AppLanguage.isVietnamese ? "Mã đi hình chữ L. Hãy đưa Mã vào cuộc chơi." : "Knights move in an L shape. Bring one into play.")
        case 2: return (AppLanguage.isVietnamese ? "Quan sát quân nào của máy đang không được bảo vệ." : "Look for an unprotected computer piece.")
        case 3: return (AppLanguage.isVietnamese ? "Dọn đường giữa Vua và Xe, rồi nhập thành." : "Clear the path between your king and rook, then castle.")
        default: return (AppLanguage.isVietnamese ? "Tiếp tục luyện tập và thử mức Thử thách nhé!" : "Keep practicing and try Challenge mode!")
        }
    }

    func reset() {
        position = .initial()
        snapshots = []
        selected = nil
        suggested = nil
        recordedResult = false
        clearHints()
        message = mode == .computer ? (AppLanguage.isVietnamese ? "Ván mới bắt đầu. Bé cầm quân \(playerSide == .white ? (AppLanguage.isVietnamese ? "Trắng và đi trước" : "White and move first") : (AppLanguage.isVietnamese ? "Đen, máy đi trước" : "Black; the computer moves first"))!" : "New game. You play \(playerSide == .white ? (AppLanguage.isVietnamese ? "Trắng và đi trước" : "White and move first") : (AppLanguage.isVietnamese ? "Đen, máy đi trước" : "Black; the computer moves first"))!") : (AppLanguage.isVietnamese ? "Ván mới bắt đầu. Người chơi Trắng đi trước!" : "New game. White moves first!")
    }

    func setPlayerSide(_ side: Side) {
        guard playerSide != side else { return }
        playerSide = side
        reset()
    }

    func setMode(_ newMode: GameMode) {
        guard mode != newMode else { return }
        mode = newMode
        reset()
    }

    func select(_ index: Int) -> Move? {
        guard !isFinished, mode == .twoPlayers || position.turn == playerSide else { return nil }
        if let selected, let move = position.legalMoves(from: selected).first(where: { $0.to == index }) {
            return move
        }
        if let piece = position.squares[index], piece.side == position.turn {
            selected = index
            suggested = nil
            let count = position.legalMoves(from: index).count
            message = (AppLanguage.isVietnamese ? "\(piece.kind.name): \(piece.kind.lesson) Có \(count) ô hợp lệ." : "\(piece.kind.name): \(piece.kind.lesson) Legal squares: \(count).")
        } else {
            selected = nil
            message = mode == .computer ? (AppLanguage.isVietnamese ? "Hãy chọn một quân \(playerSide == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) của bé." : "Select a \(playerSide == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) piece of yours.") : (AppLanguage.isVietnamese ? "Hãy chọn quân \(position.turn == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) để đi." : "Select a \(position.turn == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) piece to move.")
        }
        return nil
    }

    func play(_ move: Move) {
        guard position.legalMoves(from: move.from).contains(move) else { return }
        let piece = position.squares[move.from]!
        let captured = position.squares[move.to] != nil || move.isEnPassant
        snapshots.append(Snapshot(position: position, lessonStage: lessonStage, stars: stars))
        position.apply(move)
        if mode == .computer && piece.side == playerSide && completesMission(move, piece: piece, captured: captured) {
            lessonStage += 1
            stars += 1
            UserDefaults.standard.set(lessonStage, forKey: "chesschild.lessonStage")
            UserDefaults.standard.set(stars, forKey: "chesschild.stars")
            message = (AppLanguage.isVietnamese ? "Hoàn thành thử thách! Bé nhận được một ngôi sao ⭐" : "Challenge complete! You earned a star ⭐")
        }
        selected = nil
        suggested = nil
        clearHints()
        if let result = position.result {
            message = resultMessage ?? result
            if mode == .computer { record(message) }
        } else if mode == .twoPlayers {
            if position.inCheck(position.turn) {
                message = (AppLanguage.isVietnamese ? "Vua \(position.turn == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) đang bị chiếu! Hãy tìm nước bảo vệ Vua." : "King \(position.turn == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) is in check! Find a move to protect your king.")
            } else {
                message = (AppLanguage.isVietnamese ? "Đến lượt người chơi \(position.turn == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black"))." : "Player to move: \(position.turn == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")).")
            }
        } else if position.inCheck(position.turn) {
            message = piece.side == playerSide ? (AppLanguage.isVietnamese ? "Hay lắm! Bé đang chiếu Vua của máy." : "Well done! You checked the computer's king.") : (AppLanguage.isVietnamese ? "Vua của bé đang bị chiếu. Hãy tìm cách bảo vệ Vua!" : "Your king is in check. Find a way to protect it!")
        } else if move.isCastle {
            message = (AppLanguage.isVietnamese ? "Nhập thành! Vua đã được đưa về nơi an toàn hơn." : "Castled! Your king is safer now.")
        } else if move.promotion != nil {
            message = (AppLanguage.isVietnamese ? "Tốt đã đến cuối bàn cờ và hóa thành Hậu!" : "Your pawn reached the last rank and became a queen!")
        } else if captured {
            message = piece.side == playerSide ? (AppLanguage.isVietnamese ? "Bé vừa ăn một quân. Nhớ xem quân của mình có an toàn không nhé!" : "You captured a piece. Check that your pieces are safe!") : (AppLanguage.isVietnamese ? "Máy vừa ăn quân. Bé có thể tìm nước đáp trả." : "The computer captured a piece. Look for a reply.")
        } else {
            message = piece.side == playerSide ? (AppLanguage.isVietnamese ? "Đẹp lắm! Đến lượt máy suy nghĩ..." : "Nice move! The computer is thinking...") : (AppLanguage.isVietnamese ? "Đến lượt bé. Chọn quân và thử một kế hoạch mới!" : "Your turn. Pick a piece and try a new plan!")
        }
        if mode == .computer && piece.side == playerSide && lessonStage > snapshots.last!.lessonStage && position.result == nil {
            message = (AppLanguage.isVietnamese ? "Hoàn thành thử thách! Bé nhận được một ngôi sao ⭐" : "Challenge complete! You earned a star ⭐")
        }
    }

    func undo() {
        guard canUndo else { return }
        if recordedResult {
            games = max(0, games - 1)
            if position.legalMoves().isEmpty && position.inCheck(position.turn) && position.turn.opponent == playerSide { wins = max(0, wins - 1) }
            UserDefaults.standard.set(games, forKey: "chesschild.games")
            UserDefaults.standard.set(wins, forKey: "chesschild.wins")
        }
        // Against the computer, return to the child's previous turn. In two-player mode, undo one move.
        if mode == .computer && position.turn == playerSide && snapshots.count >= 2 { snapshots.removeLast() }
        let snapshot = snapshots.removeLast()
        position = snapshot.position
        lessonStage = snapshot.lessonStage
        stars = snapshot.stars
        UserDefaults.standard.set(lessonStage, forKey: "chesschild.lessonStage")
        UserDefaults.standard.set(stars, forKey: "chesschild.stars")
        selected = nil
        suggested = nil
        clearHints()
        recordedResult = false
        message = mode == .computer ? (AppLanguage.isVietnamese ? "Mình thử một cách khác nhé. Chạm quân \(playerSide == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) để đi tiếp!" : "Try another idea. Tap a \(playerSide == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")) piece to continue!") : (AppLanguage.isVietnamese ? "Đi lại! Đến lượt người chơi \(position.turn == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black"))." : "Undone! Player to move: \(position.turn == .white ? (AppLanguage.isVietnamese ? "Trắng" : "White") : (AppLanguage.isVietnamese ? "Đen" : "Black")).")
    }

    func hint() {
        guard (mode == .twoPlayers || position.turn == playerSide), !isFinished else { return }
        if hintChoices.isEmpty {
            let ranked = ChessCoach.rankedMoves(in: position, for: position.turn)
            if mode == .computer {
                let mission = position.legalMoves().filter { move in
                    guard let piece = position.squares[move.from] else { return false }
                    return completesMission(move, piece: piece, captured: position.squares[move.to] != nil || move.isEnPassant)
                }
                hintChoices = Array((mission + ranked.filter { !mission.contains($0) }).prefix(8))
            } else {
                hintChoices = ranked
            }
        }
        guard !hintChoices.isEmpty else { return }
        let move = hintChoices[nextHintIndex]
        nextHintIndex = (nextHintIndex + 1) % hintChoices.count
        selected = move.from
        suggested = move
        let piece = position.squares[move.from]!
        let anotherHint = hintChoices.count > 1 ? (AppLanguage.isVietnamese ? " Nhấn tiếp để xem cách khác!" : " Tap again for another idea!") : (AppLanguage.isVietnamese ? " Đây là nước hợp lệ duy nhất." : " This is the only legal move.")
        message = (AppLanguage.isVietnamese ? "Gợi ý \(nextHintIndex == 0 ? hintChoices.count : nextHintIndex)/\(hintChoices.count): đưa \(piece.kind.name) từ \(ChessPosition.coordinate(move.from)) đến \(ChessPosition.coordinate(move.to)).\(anotherHint)" : "Hint \(nextHintIndex == 0 ? hintChoices.count : nextHintIndex)/\(hintChoices.count): move \(piece.kind.name) from \(ChessPosition.coordinate(move.from)) to \(ChessPosition.coordinate(move.to)).\(anotherHint)")
    }

    func computerMove() -> Move? {
        guard mode == .computer, position.turn == playerSide.opponent, !isFinished else { return nil }
        return ChessCoach.bestMove(in: position, for: playerSide.opponent, difficulty: difficulty)
    }

    private func record(_ result: String) {
        guard !recordedResult else { return }
        recordedResult = true
        games += 1
        if position.legalMoves().isEmpty && position.inCheck(position.turn) && position.turn.opponent == playerSide { wins += 1 }
        UserDefaults.standard.set(games, forKey: "chesschild.games")
        UserDefaults.standard.set(wins, forKey: "chesschild.wins")
    }

    private func clearHints() {
        hintChoices = []
        nextHintIndex = 0
    }

    private func completesMission(_ move: Move, piece: Piece, captured: Bool) -> Bool {
        switch lessonStage {
        case 0: return piece.kind == .pawn && (playerSide == .white ? [35, 36] : [27, 28]).contains(move.to)
        case 1: return piece.kind == .knight && (playerSide == .white ? [57, 62] : [1, 6]).contains(move.from)
        case 2: return captured
        case 3: return move.isCastle
        default: return false
        }
    }
}

enum ChessCoach {
    static func rankedMoves(in position: ChessPosition, for side: Side) -> [Move] {
        guard position.turn == side else { return [] }
        let candidates = position.legalMoves().map { move -> (Move, Int) in
            var next = position
            next.apply(move)
            return (move, evaluate(next, for: side))
        }.sorted { left, right in
            if left.1 != right.1 { return left.1 > right.1 }
            return left.0.from == right.0.from ? left.0.to < right.0.to : left.0.from < right.0.from
        }

        // Search the strongest candidates one reply ahead and offer those as alternatives.
        let strongest = candidates.prefix(8).map { entry -> (Move, Int) in
            var after = position
            after.apply(entry.0)
            let score = after.legalMoves().map { reply -> Int in
                var further = after
                further.apply(reply)
                return evaluate(further, for: side)
            }.min() ?? entry.1
            return (entry.0, score)
        }.sorted { $0.1 > $1.1 }
        return strongest.map { $0.0 }
    }

    static func bestMove(in position: ChessPosition, for side: Side, difficulty: Int) -> Move? {
        guard position.turn == side else { return nil }
        let moves = position.legalMoves()
        guard !moves.isEmpty else { return nil }
        let ranked = moves.map { move -> (Move, Int) in
            var next = position
            next.apply(move)
            let score = evaluate(next, for: side) + Int.random(in: -8...8)
            return (move, score)
        }.sorted { $0.1 > $1.1 }

        if difficulty == 0 {
            return Array(ranked.prefix(5)).randomElement()?.0
        }
        // Search the promising moves one reply ahead, keeping the older iPad responsive.
        return ranked.prefix(8).map { entry -> (Move, Int) in
            var after = position
            after.apply(entry.0)
            let replies = after.legalMoves()
            let worstReply = replies.map { reply -> Int in
                var further = after
                further.apply(reply)
                return evaluate(further, for: side)
            }.min() ?? entry.1
            return (entry.0, worstReply)
        }.max { $0.1 < $1.1 }?.0
    }

    private static func evaluate(_ position: ChessPosition, for side: Side) -> Int {
        if let result = position.result {
            if position.legalMoves().isEmpty && position.inCheck(position.turn) {
                return position.turn.opponent == side ? 100_000 : -100_000
            }
            return 0
        }
        var score = 0
        for index in 0..<64 {
            guard let piece = position.squares[index] else { continue }
            let center = 6 - abs(3 - index / 8) - abs(3 - index % 8)
            let bonus = piece.kind == .pawn || piece.kind == .knight ? center * 3 : 0
            score += (piece.side == side ? 1 : -1) * (piece.kind.value + bonus)
        }
        if position.inCheck(side.opponent) { score += 15 }
        return score
    }
}
