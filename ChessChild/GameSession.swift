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
    @Published var message = "Chạm vào một quân trắng để xem các nước đi nhé!"
    @Published var difficulty = 0
    @Published private(set) var mode: GameMode = .computer
    @Published private(set) var wins = UserDefaults.standard.integer(forKey: "chesschild.wins")
    @Published private(set) var games = UserDefaults.standard.integer(forKey: "chesschild.games")
    @Published private(set) var lessonStage = UserDefaults.standard.integer(forKey: "chesschild.lessonStage")
    @Published private(set) var stars = UserDefaults.standard.integer(forKey: "chesschild.stars")
    private var snapshots: [Snapshot] = []
    private var recordedResult = false
    private var hintChoices: [Move] = []
    private var nextHintIndex = 0

    var legalSelection: [Move] { selected.map { position.legalMoves(from: $0) } ?? [] }
    var canUndo: Bool { !snapshots.isEmpty }
    var isFinished: Bool { position.result != nil }
    var resultMessage: String? {
        guard let result = position.result else { return nil }
        guard mode == .twoPlayers, result.contains("thắng") || result.contains("Chiếu hết") else { return result }
        return "Chiếu hết! Người chơi \(position.turn.opponent == .white ? "Trắng" : "Đen") thắng! 🎉"
    }
    var missionTitle: String {
        switch lessonStage {
        case 0: return "Đưa Tốt vào trung tâm"
        case 1: return "Đưa Mã ra khỏi hàng đầu"
        case 2: return "Ăn một quân của máy"
        case 3: return "Nhập thành để bảo vệ Vua"
        default: return "Bé đã hoàn thành các thử thách đầu tiên!"
        }
    }
    var missionDetail: String {
        switch lessonStage {
        case 0: return "Thử đưa Tốt đến ô d4 hoặc e4."
        case 1: return "Mã đi hình chữ L. Hãy đưa Mã vào cuộc chơi."
        case 2: return "Quan sát quân nào của máy đang không được bảo vệ."
        case 3: return "Dọn đường giữa Vua và Xe, rồi nhập thành."
        default: return "Tiếp tục luyện tập và thử mức Thử thách nhé!"
        }
    }

    func reset() {
        position = .initial()
        snapshots = []
        selected = nil
        suggested = nil
        recordedResult = false
        clearHints()
        message = mode == .computer ? "Ván mới bắt đầu. Bé cầm quân trắng và đi trước!" : "Ván mới bắt đầu. Người chơi Trắng đi trước!"
    }

    func setMode(_ newMode: GameMode) {
        guard mode != newMode else { return }
        mode = newMode
        reset()
    }

    func select(_ index: Int) -> Move? {
        guard !isFinished, mode == .twoPlayers || position.turn == .white else { return nil }
        if let selected, let move = position.legalMoves(from: selected).first(where: { $0.to == index }) {
            return move
        }
        if let piece = position.squares[index], piece.side == position.turn {
            selected = index
            suggested = nil
            let count = position.legalMoves(from: index).count
            message = "\(piece.kind.name): \(piece.kind.lesson) Có \(count) ô hợp lệ."
        } else {
            selected = nil
            message = mode == .computer ? "Hãy chọn một quân trắng của bé." : "Hãy chọn quân \(position.turn == .white ? "Trắng" : "Đen") để đi."
        }
        return nil
    }

    func play(_ move: Move) {
        guard position.legalMoves(from: move.from).contains(move) else { return }
        let piece = position.squares[move.from]!
        let captured = position.squares[move.to] != nil || move.isEnPassant
        snapshots.append(Snapshot(position: position, lessonStage: lessonStage, stars: stars))
        position.apply(move)
        if mode == .computer && piece.side == .white && completesMission(move, piece: piece, captured: captured) {
            lessonStage += 1
            stars += 1
            UserDefaults.standard.set(lessonStage, forKey: "chesschild.lessonStage")
            UserDefaults.standard.set(stars, forKey: "chesschild.stars")
            message = "Hoàn thành thử thách! Bé nhận được một ngôi sao ⭐"
        }
        selected = nil
        suggested = nil
        clearHints()
        if let result = position.result {
            message = resultMessage ?? result
            if mode == .computer { record(result) }
        } else if mode == .twoPlayers {
            if position.inCheck(position.turn) {
                message = "Vua \(position.turn == .white ? "Trắng" : "Đen") đang bị chiếu! Hãy tìm nước bảo vệ Vua."
            } else {
                message = "Đến lượt người chơi \(position.turn == .white ? "Trắng" : "Đen")."
            }
        } else if position.inCheck(position.turn) {
            message = piece.side == .white ? "Hay lắm! Bé đang chiếu Vua của máy." : "Vua của bé đang bị chiếu. Hãy tìm cách bảo vệ Vua!"
        } else if move.isCastle {
            message = "Nhập thành! Vua đã được đưa về nơi an toàn hơn."
        } else if move.promotion != nil {
            message = "Tốt đã đến cuối bàn cờ và hóa thành Hậu!"
        } else if captured {
            message = piece.side == .white ? "Bé vừa ăn một quân. Nhớ xem quân của mình có an toàn không nhé!" : "Máy vừa ăn quân. Bé có thể tìm nước đáp trả."
        } else {
            message = piece.side == .white ? "Đẹp lắm! Đến lượt máy suy nghĩ..." : "Đến lượt bé. Chọn quân và thử một kế hoạch mới!"
        }
        if mode == .computer && piece.side == .white && lessonStage > snapshots.last!.lessonStage && position.result == nil {
            message = "Hoàn thành thử thách! Bé nhận được một ngôi sao ⭐"
        }
    }

    func undo() {
        guard !snapshots.isEmpty else { return }
        if recordedResult {
            games = max(0, games - 1)
            if position.result?.contains("Bé đã thắng") == true { wins = max(0, wins - 1) }
            UserDefaults.standard.set(games, forKey: "chesschild.games")
            UserDefaults.standard.set(wins, forKey: "chesschild.wins")
        }
        // Against the computer, return to the child's previous turn. In two-player mode, undo one move.
        if mode == .computer && position.turn == .white && snapshots.count >= 2 { snapshots.removeLast() }
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
        message = mode == .computer ? "Mình thử một cách khác nhé. Chạm quân trắng để đi tiếp!" : "Đi lại! Đến lượt người chơi \(position.turn == .white ? "Trắng" : "Đen")."
    }

    func hint() {
        guard (mode == .twoPlayers || position.turn == .white), !isFinished else { return }
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
        let anotherHint = hintChoices.count > 1 ? " Nhấn tiếp để xem cách khác!" : " Đây là nước hợp lệ duy nhất."
        message = "Gợi ý \(nextHintIndex == 0 ? hintChoices.count : nextHintIndex)/\(hintChoices.count): đưa \(piece.kind.name) từ \(ChessPosition.coordinate(move.from)) đến \(ChessPosition.coordinate(move.to)).\(anotherHint)"
    }

    func computerMove() -> Move? {
        guard mode == .computer, position.turn == .black, !isFinished else { return nil }
        return ChessCoach.bestMove(in: position, for: .black, difficulty: difficulty)
    }

    private func record(_ result: String) {
        guard !recordedResult else { return }
        recordedResult = true
        games += 1
        if result.contains("Bé đã thắng") { wins += 1 }
        UserDefaults.standard.set(games, forKey: "chesschild.games")
        UserDefaults.standard.set(wins, forKey: "chesschild.wins")
    }

    private func clearHints() {
        hintChoices = []
        nextHintIndex = 0
    }

    private func completesMission(_ move: Move, piece: Piece, captured: Bool) -> Bool {
        switch lessonStage {
        case 0: return piece.kind == .pawn && (move.to == 35 || move.to == 36)
        case 1: return piece.kind == .knight && (move.from == 57 || move.from == 62)
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

        if difficulty == 0 && side == .black {
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
            if result.contains("Chiếu hết") { return side == .white ? 100_000 : -100_000 }
            if result.contains("Máy thắng") { return side == .black ? 100_000 : -100_000 }
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
