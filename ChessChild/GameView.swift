import SwiftUI
import UIKit

private enum Palette {
    static let ink = Color(red: 0.18, green: 0.25, blue: 0.31)
    static let dark = Color(red: 0.29, green: 0.52, blue: 0.56)
    static let light = Color(red: 0.91, green: 0.95, blue: 0.88)
    static let gold = Color(red: 1.00, green: 0.76, blue: 0.35)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.90)
}

private struct MovingPiece {
    let piece: Piece
    let from: Int
    let to: Int
}

struct GameView: View {
    @StateObject private var game = GameSession()
    @State private var moving: MovingPiece? = nil
    @State private var movingAt: Int = 0
    @State private var showingRules = false
    @State private var pendingComputer = false

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(0, geometry.size.width - 32)
            let sideBySide = contentWidth >= 700 && geometry.size.width > geometry.size.height
            let narrow = contentWidth < 600
            let boardSide = max(0, min(640, sideBySide
                ? contentWidth - 18 - 28 - 320
                : contentWidth - 28))

            ScrollView {
                VStack(spacing: 12) {
                    header
                    if sideBySide {
                        HStack(alignment: .top, spacing: 18) {
                            boardCard(side: boardSide, narrow: false)
                                .frame(width: boardSide + 28)
                            controls(compact: false, narrow: false)
                                .frame(width: 320)
                        }
                    } else {
                        boardCard(side: boardSide, narrow: narrow)
                            .frame(width: boardSide + 28)
                        controls(compact: true, narrow: narrow)
                            .frame(width: boardSide + 28)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(colors: [Palette.cream, Color(red: 0.86, green: 0.94, blue: 0.91)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
        }
        .sheet(isPresented: $showingRules) { rulesSheet }
        .onAppear { if game.mode == .computer && game.position.turn != game.playerSide { computerTurn() } }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CỜ VUA CỦA BÉ")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.dark)
                Text("Mỗi nước đi, một điều mới ✨")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button { showingRules = true } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.ink)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.8), in: Circle())
            }
            .accessibilityLabel("Hướng dẫn chơi")
        }
    }

    private var turnLabel: some View {
        Label(game.mode == .twoPlayers ? "Lượt của \(game.position.turn == .white ? "Trắng" : "Đen")" : (game.position.turn == game.playerSide ? "Lượt của bé" : "Máy đang nghĩ..."), systemImage: game.mode == .computer && game.position.turn != game.playerSide ? "sparkles" : "hand.point.up.left.fill")
            .font(.system(size: 16, weight: .bold, design: .rounded))
    }

    private var sideLegend: some View {
        HStack(spacing: 5) {
            Circle().fill(Palette.cream).overlay(Circle().stroke(Palette.ink, lineWidth: 1)).frame(width: 13, height: 13)
            Text(game.mode == .computer && game.playerSide == .white ? "BÉ" : (game.mode == .computer ? "MÁY" : "TRẮNG"))
            Text("•").padding(.horizontal, 2)
            Circle().fill(Palette.ink).frame(width: 13, height: 13)
            Text(game.mode == .computer && game.playerSide == .black ? "BÉ" : (game.mode == .computer ? "MÁY" : "ĐEN"))
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
    }

    private func boardCard(side: CGFloat, narrow: Bool) -> some View {
        let size = side / 8
        return VStack(spacing: 8) {
            Group {
                if narrow {
                    VStack(alignment: .leading, spacing: 4) {
                        turnLabel
                        sideLegend.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                } else {
                    HStack {
                        turnLabel
                        Spacer()
                        sideLegend
                    }
                }
            }
            .foregroundColor(Palette.ink)

            fileLabels(side: side, opposite: true)

            ZStack(alignment: .topLeading) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(size), spacing: 0), count: 8), spacing: 0) {
                    ForEach(0..<64, id: \.self) { index in
                        square(boardIndex(index), size: size)
                    }
                }
                if let moving {
                    pieceView(moving.piece, size: size)
                        .position(x: CGFloat(boardIndex(movingAt) % 8) * size + size / 2,
                                  y: CGFloat(boardIndex(movingAt) / 8) * size + size / 2)
                        .allowsHitTesting(false)
                        .zIndex(10)
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.ink.opacity(0.14), lineWidth: 2))
            .shadow(color: Palette.ink.opacity(0.16), radius: 12, y: 7)

            fileLabels(side: side, opposite: false)
        }
        .padding(14)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var isBoardFlipped: Bool {
        game.mode == .computer && game.playerSide == .black
    }

    private func fileLabels(side: CGFloat, opposite: Bool) -> some View {
        HStack {
            ForEach(0..<8, id: \.self) { col in
                Text(String(UnicodeScalar(isBoardFlipped ? 72 - col : 65 + col)!))
                    .frame(maxWidth: .infinity)
                    .rotationEffect(.degrees(opposite ? 180 : 0))
            }
        }
        .frame(width: side)
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundColor(Palette.dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chữ cái các cột")
    }

    private func boardIndex(_ index: Int) -> Int {
        isBoardFlipped ? 63 - index : index
    }

    private func square(_ index: Int, size: CGFloat) -> some View {
        let highlighted = game.legalSelection.contains(where: { $0.to == index })
        let suggested = game.suggested?.to == index
        let checkedKing = game.position.squares[index] == Piece(side: game.position.turn, kind: .king) && game.position.inCheck(game.position.turn)
        return ZStack {
            Rectangle()
                .fill((index / 8 + index % 8).isMultiple(of: 2) ? Palette.light : Palette.dark)
            if game.selected == index {
                Rectangle().fill(Palette.gold.opacity(0.65))
            } else if suggested {
                Rectangle().fill(Palette.gold.opacity(0.5))
            } else if checkedKing {
                Rectangle().fill(Color.red.opacity(0.45))
            }
            if highlighted {
                Circle()
                    .fill(suggested ? Palette.gold : Color.white.opacity(0.65))
                    .frame(width: size * 0.32, height: size * 0.32)
                    .shadow(color: .black.opacity(0.12), radius: 2)
            }
            if let piece = game.position.squares[index], moving?.from != index {
                pieceView(piece, size: size)
                    .scaleEffect(game.selected == index ? 1.12 : 1)
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: game.selected)
            }
            if boardIndex(index) % 8 == 0 || boardIndex(index) % 8 == 7 {
                Text("\(8 - index / 8)")
                    .font(.system(size: max(9, size * 0.16), weight: .heavy, design: .rounded))
                    .foregroundColor((index / 8 + index % 8).isMultiple(of: 2) ? Palette.dark : Palette.light)
                    .rotationEffect(.degrees(boardIndex(index) % 8 == 7 ? 180 : 0))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: boardIndex(index) % 8 == 0 ? .topLeading : .topTrailing)
                    .padding(3)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture { tap(index) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ô \(ChessPosition.coordinate(index)), \(game.position.squares[index].map { "\($0.kind.name) \($0.side == .white ? "trắng" : "đen")" } ?? "trống")")
        .accessibilityAddTraits(.isButton)
    }

    private func pieceView(_ piece: Piece, size: CGFloat) -> some View {
        ChessPieceView(piece: piece, size: size)
    }

    private func controls(compact: Bool, narrow: Bool) -> some View {
        VStack(spacing: compact ? 9 : 12) {
            if narrow && game.mode == .computer {
                modeMenu
                HStack(spacing: 8) { colorMenu; difficultyMenu }
            } else {
                HStack(spacing: 8) {
                    modeMenu
                    if game.mode == .computer { colorMenu; difficultyMenu }
                }
            }
            if game.mode == .computer && compact && !narrow {
                HStack(alignment: .top, spacing: 10) {
                    missionCard(compact: true)
                    coachCard(compact: true)
                }
            } else {
                if game.mode == .computer { missionCard(compact: false) }
                coachCard(compact: false)
            }
            if narrow {
                HStack(spacing: 8) { hintButton; undoButton }
                newGameButton
            } else if compact {
                HStack(spacing: 8) {
                    hintButton
                    undoButton
                    newGameButton
                }
            } else {
                HStack(spacing: 10) { hintButton; undoButton }
                newGameButton
            }
            if game.mode == .computer {
                Text("Đã chơi \(game.games) ván • Thắng \(game.wins) ván")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Palette.dark)
            }
        }
    }

    private func missionCard(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack {
                Label("THỬ THÁCH \(min(game.lessonStage + 1, 4))/4", systemImage: "star.fill")
                    .foregroundColor(Palette.dark)
                Spacer(minLength: 2)
                Text("⭐ \(game.stars)")
                    .foregroundColor(Palette.ink)
            }
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            Text(game.missionTitle)
                .font(.system(size: compact ? 16 : 18, weight: .bold, design: .rounded))
                .foregroundColor(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(game.missionDetail)
                .font(.system(size: compact ? 13 : 14, design: .rounded))
                .foregroundColor(Palette.dark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 103 : 0, alignment: .topLeading)
        .padding(compact ? 13 : 18)
        .background(Palette.gold.opacity(0.27), in: RoundedRectangle(cornerRadius: 20))
    }

    private func coachCard(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            Label(game.mode == .computer ? "THẦY CỜ BÊN CẠNH" : "HƯỚNG DẪN LƯỢT CHƠI", systemImage: "sparkles")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.dark)
            Text(game.message)
                .font(.system(size: compact ? 15 : 17, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 103 : 80, alignment: .topLeading)
        .padding(compact ? 13 : 18)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 20))
    }

    private var hintButton: some View {
        action("Gợi ý", icon: "lightbulb.fill", color: Palette.gold) { game.hint() }
            .disabled((game.mode == .computer && game.position.turn != game.playerSide) || game.isFinished || moving != nil)
    }

    private var undoButton: some View {
        action("Đi lại", icon: "arrow.uturn.backward", color: Palette.light) { game.undo() }
            .disabled(!game.canUndo || moving != nil)
    }

    private var newGameButton: some View {
        action("Ván mới", icon: "arrow.clockwise", color: Palette.light) { game.reset(); startComputerIfNeeded() }
            .disabled(moving != nil)
    }

    private var difficultyMenu: some View {
        Menu {
            Button("Tập chơi") { game.difficulty = 0 }
            Button("Thử thách") { game.difficulty = 1 }
        } label: {
            Label(game.difficulty == 0 ? "Tập chơi" : "Thử thách", systemImage: "slider.horizontal.3")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Palette.light, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var colorMenu: some View {
        Menu {
            Button("Cầm quân Trắng") { game.setPlayerSide(.white); startComputerIfNeeded() }
            Button("Cầm quân Đen") { game.setPlayerSide(.black); startComputerIfNeeded() }
        } label: {
            Label(game.playerSide == .white ? "Trắng" : "Đen", systemImage: "circle.lefthalf.filled")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Palette.light, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(moving != nil)
    }

    private var modeMenu: some View {
        Menu {
            Button("Chơi với máy") { game.setMode(.computer); startComputerIfNeeded() }
            Button("Hai người chơi") { game.setMode(.twoPlayers) }
        } label: {
            Label(game.mode == .computer ? "Chơi với máy" : "Hai người chơi", systemImage: "person.2.fill")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Palette.light, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(moving != nil)
    }

    private func action(_ title: String, icon: String, color: Color, handler: @escaping () -> Void) -> some View {
        Button(action: handler) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(color, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func tap(_ index: Int) {
        guard moving == nil else { return }
        if let move = game.select(index) { animate(move) }
        else if game.selected == index { UISelectionFeedbackGenerator().selectionChanged() }
    }

    private func animate(_ move: Move) {
        guard let piece = game.position.squares[move.from] else { return }
        moving = MovingPiece(piece: piece, from: move.from, to: move.to)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        movingAt = move.from
        withAnimation(.easeInOut(duration: 0.32)) { movingAt = move.to }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            game.play(move)
            moving = nil
            let celebrate = game.mode == .twoPlayers
                ? game.resultMessage?.contains("thắng") == true
                : game.resultMessage?.contains("Bé đã thắng") == true
            if celebrate {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            startComputerIfNeeded()
        }
    }

    private func startComputerIfNeeded() {
        if game.mode == .computer && game.position.turn != game.playerSide && !game.isFinished { computerTurn() }
    }

    private func computerTurn() {
        guard game.mode == .computer && !pendingComputer else { return }
        pendingComputer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard game.mode == .computer, game.position.turn != game.playerSide, moving == nil else {
                pendingComputer = false
                return
            }
            let snapshot = game.position
            let difficulty = game.difficulty
            let computerSide = game.playerSide.opponent
            DispatchQueue.global(qos: .userInitiated).async {
                let move = ChessCoach.bestMove(in: snapshot, for: computerSide, difficulty: difficulty)
                DispatchQueue.main.async {
                    pendingComputer = false
                    guard game.mode == .computer, game.position == snapshot, game.playerSide.opponent == computerSide, moving == nil else {
                        if game.mode == .computer && game.position.turn != game.playerSide && moving == nil { computerTurn() }
                        return
                    }
                    if let move { animate(move) }
                }
            }
        }
    }

    private var rulesSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Chọn Chơi với máy hoặc Hai người chơi trên cùng thiết bị. Khi chơi với máy, chọn cầm quân Trắng hoặc Đen; quân Trắng luôn đi trước. Chạm một quân của bên tới lượt để thấy các ô có thể đi, rồi chạm ô đích. Nhấn Gợi ý nhiều lần để xem các phương án khác nhau. Nút Đi lại hoàn tác lượt vừa đi.")
                        .font(.system(size: 18, design: .rounded))
                    ForEach(Kind.allCases, id: \.self) { kind in
                        HStack(alignment: .top, spacing: 12) {
                            ChessPieceView(piece: Piece(side: .white, kind: kind), size: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(kind.name).font(.headline)
                                Text(kind.lesson).font(.body)
                            }
                        }
                    }
                    Text("Nếu một quân Tốt đến hàng cuối, quân đó tự động thành Hậu. Muốn thắng, hãy chiếu hết Vua đối phương!")
                        .font(.system(size: 16, design: .rounded))
                }
                .foregroundColor(Palette.ink)
                .padding(24)
            }
            .background(Palette.cream)
            .navigationTitle("Học chơi cờ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong") { showingRules = false } } }
        }
    }
}
