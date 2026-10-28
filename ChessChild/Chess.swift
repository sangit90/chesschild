import Foundation

enum Side: String, Codable {
    case white, black
    var opponent: Side { self == .white ? .black : .white }
    var direction: Int { self == .white ? -1 : 1 }
}

enum Kind: String, Codable, CaseIterable {
    case king, queen, rook, bishop, knight, pawn

    var name: String {
        switch self {
        case .king: return "Vua"
        case .queen: return "Hậu"
        case .rook: return "Xe"
        case .bishop: return "Tượng"
        case .knight: return "Mã"
        case .pawn: return "Tốt"
        }
    }

    var lesson: String {
        switch self {
        case .king: return "Vua đi một ô theo mọi hướng. Hãy luôn giữ Vua an toàn!"
        case .queen: return "Hậu đi ngang, dọc hoặc chéo bao nhiêu ô cũng được."
        case .rook: return "Xe đi ngang hoặc dọc, không nhảy qua quân khác."
        case .bishop: return "Tượng đi theo đường chéo và luôn ở cùng màu ô."
        case .knight: return "Mã đi hình chữ L và có thể nhảy qua các quân."
        case .pawn: return "Tốt tiến lên một ô, ăn chéo. Ở nước đầu có thể tiến hai ô."
        }
    }

    var value: Int {
        switch self {
        case .king: return 0
        case .queen: return 900
        case .rook: return 500
        case .bishop: return 330
        case .knight: return 320
        case .pawn: return 100
        }
    }
}

struct Piece: Equatable, Codable {
    let side: Side
    let kind: Kind
}

struct Move: Equatable {
    let from: Int
    let to: Int
    var promotion: Kind? = nil
    var isCastle = false
    var isEnPassant = false
}

struct ChessPosition: Equatable {
    var squares: [Piece?] = Array(repeating: nil, count: 64)
    var turn: Side = .white
    var whiteKingCastle = true
    var whiteQueenCastle = true
    var blackKingCastle = true
    var blackQueenCastle = true
    var enPassant: Int? = nil
    var halfmoveClock = 0

    static func initial() -> ChessPosition {
        var p = ChessPosition()
        let back: [Kind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for col in 0..<8 {
            p.squares[col] = Piece(side: .black, kind: back[col])
            p.squares[8 + col] = Piece(side: .black, kind: .pawn)
            p.squares[48 + col] = Piece(side: .white, kind: .pawn)
            p.squares[56 + col] = Piece(side: .white, kind: back[col])
        }
        return p
    }

    static func index(_ row: Int, _ col: Int) -> Int? {
        (0..<8).contains(row) && (0..<8).contains(col) ? row * 8 + col : nil
    }

    func attacked(_ square: Int, by side: Side) -> Bool {
        for from in 0..<64 where squares[from]?.side == side {
            if pseudoMoves(from: from, attacksOnly: true).contains(where: { $0.to == square }) { return true }
        }
        return false
    }

    func inCheck(_ side: Side) -> Bool {
        guard let king = squares.firstIndex(where: { $0?.side == side && $0?.kind == .king }) else { return true }
        return attacked(king, by: side.opponent)
    }

    func legalMoves(from: Int? = nil) -> [Move] {
        let indices = from.map { [$0] } ?? Array(0..<64)
        return indices.flatMap { index -> [Move] in
            guard squares[index]?.side == turn else { return [] }
            return pseudoMoves(from: index).filter { move in
                var copy = self
                copy.apply(move)
                return !copy.inCheck(turn)
            }
        }
    }

    func pseudoMoves(from: Int, attacksOnly: Bool = false) -> [Move] {
        guard let piece = squares[from] else { return [] }
        let row = from / 8, col = from % 8
        var result: [Move] = []

        func add(_ r: Int, _ c: Int, captureOnly: Bool = false) {
            guard let to = Self.index(r, c) else { return }
            if attacksOnly { result.append(Move(from: from, to: to)); return }
            if let occupant = squares[to] {
                if occupant.side != piece.side && occupant.kind != .king {
                    result.append(Move(from: from, to: to, promotion: piece.kind == .pawn && (r == 0 || r == 7) ? .queen : nil))
                }
            } else if !captureOnly {
                result.append(Move(from: from, to: to, promotion: piece.kind == .pawn && (r == 0 || r == 7) ? .queen : nil))
            }
        }

        func slide(_ dr: Int, _ dc: Int) {
            var r = row + dr, c = col + dc
            while let to = Self.index(r, c) {
                add(r, c)
                if squares[to] != nil { break }
                r += dr; c += dc
            }
        }

        switch piece.kind {
        case .pawn:
            for dc in [-1, 1] { add(row + piece.side.direction, col + dc, captureOnly: true) }
            if attacksOnly { break }
            if let one = Self.index(row + piece.side.direction, col), squares[one] == nil {
                add(row + piece.side.direction, col)
                let start = piece.side == .white ? 6 : 1
                if row == start, let two = Self.index(row + 2 * piece.side.direction, col), squares[two] == nil {
                    add(row + 2 * piece.side.direction, col)
                }
            }
            for dc in [-1, 1] {
                if let target = Self.index(row + piece.side.direction, col + dc), target == enPassant {
                    result.append(Move(from: from, to: target, isEnPassant: true))
                }
            }
        case .knight:
            for (dr, dc) in [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)] { add(row + dr, col + dc) }
        case .bishop:
            for (dr, dc) in [(-1,-1),(-1,1),(1,-1),(1,1)] { slide(dr, dc) }
        case .rook:
            for (dr, dc) in [(-1,0),(1,0),(0,-1),(0,1)] { slide(dr, dc) }
        case .queen:
            for (dr, dc) in [(-1,-1),(-1,1),(1,-1),(1,1),(-1,0),(1,0),(0,-1),(0,1)] { slide(dr, dc) }
        case .king:
            for dr in -1...1 { for dc in -1...1 where dr != 0 || dc != 0 { add(row + dr, col + dc) } }
            if attacksOnly || inCheck(piece.side) { break }
            let home = piece.side == .white ? 7 : 0
            guard row == home && col == 4 else { break }
            let kingSide = piece.side == .white ? whiteKingCastle : blackKingCastle
            let queenSide = piece.side == .white ? whiteQueenCastle : blackQueenCastle
            if kingSide, squares[home * 8 + 7] == Piece(side: piece.side, kind: .rook),
               squares[home * 8 + 5] == nil, squares[home * 8 + 6] == nil,
               !attacked(home * 8 + 5, by: piece.side.opponent), !attacked(home * 8 + 6, by: piece.side.opponent) {
                result.append(Move(from: from, to: home * 8 + 6, isCastle: true))
            }
            if queenSide, squares[home * 8] == Piece(side: piece.side, kind: .rook),
               squares[home * 8 + 1] == nil, squares[home * 8 + 2] == nil, squares[home * 8 + 3] == nil,
               !attacked(home * 8 + 3, by: piece.side.opponent), !attacked(home * 8 + 2, by: piece.side.opponent) {
                result.append(Move(from: from, to: home * 8 + 2, isCastle: true))
            }
        }
        return result
    }

    mutating func apply(_ move: Move) {
        guard let piece = squares[move.from] else { return }
        let captured = squares[move.to]
        if piece.kind == .king {
            if piece.side == .white { whiteKingCastle = false; whiteQueenCastle = false }
            else { blackKingCastle = false; blackQueenCastle = false }
        }
        if move.from == 56 || move.to == 56 { whiteQueenCastle = false }
        if move.from == 63 || move.to == 63 { whiteKingCastle = false }
        if move.from == 0 || move.to == 0 { blackQueenCastle = false }
        if move.from == 7 || move.to == 7 { blackKingCastle = false }

        squares[move.to] = Piece(side: piece.side, kind: move.promotion ?? piece.kind)
        squares[move.from] = nil
        if move.isEnPassant { squares[move.to + (piece.side == .white ? 8 : -8)] = nil }
        if move.isCastle {
            let home = piece.side == .white ? 7 : 0
            if move.to % 8 == 6 {
                squares[home * 8 + 5] = squares[home * 8 + 7]
                squares[home * 8 + 7] = nil
            } else {
                squares[home * 8 + 3] = squares[home * 8]
                squares[home * 8] = nil
            }
        }
        enPassant = piece.kind == .pawn && abs(move.to - move.from) == 16 ? (move.to + move.from) / 2 : nil
        halfmoveClock = piece.kind == .pawn || captured != nil || move.isEnPassant ? 0 : halfmoveClock + 1
        turn = turn.opponent
    }

    var result: String? {
        let moves = legalMoves()
        if moves.isEmpty { return inCheck(turn) ? (turn == .white ? "Máy thắng ván này. Mình thử lại nhé!" : "Chiếu hết! Bé đã thắng rồi! 🎉") : "Hòa cờ vì hết nước đi." }
        if halfmoveClock >= 100 { return "Hòa cờ sau 50 lượt không ăn quân." }
        let active = squares.compactMap { $0 }.filter { $0.kind != .king }
        if active.isEmpty { return "Hòa cờ vì chỉ còn hai Vua." }
        return nil
    }

    static func coordinate(_ index: Int) -> String {
        "\(String(UnicodeScalar(97 + index % 8)!))\(8 - index / 8)"
    }
}
