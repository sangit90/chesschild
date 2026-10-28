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
            let landscape = geometry.size.width > geometry.size.height
            ScrollView {
                VStack(spacing: 18) {
                    header
                    if landscape {
                        HStack(alignment: .top, spacing: 26) {
                            boardCard
                                .frame(maxWidth: min(geometry.size.height - 125, 620))
                            controls
                                .frame(maxWidth: 310)
                        }
                    } else {
                        boardCard.frame(maxWidth: 620)
                        controls.frame(maxWidth: 620)
                    }
                }
                .frame(maxWidth: 1020)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
            .background(
                LinearGradient(colors: [Palette.cream, Color(red: 0.86, green: 0.94, blue: 0.91)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
        }
        .sheet(isPresented: $showingRules) { rulesSheet }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CỜ VUA CỦA BÉ")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .kerning(2.5)
                    .foregroundColor(Palette.dark)
                Text("Mỗi nước đi, một điều mới ✨")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.ink)
            }
            Spacer()
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

    private var boardCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label(game.position.turn == .white ? "Lượt của bé" : "Máy đang nghĩ...", systemImage: game.position.turn == .white ? "hand.point.up.left.fill" : "sparkles")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Text("BÉ ♔  •  MÁY ♚")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundColor(Palette.ink)

            GeometryReader { proxy in
                let size = proxy.size.width / 8
                ZStack(alignment: .topLeading) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 8), spacing: 0) {
                        ForEach(0..<64, id: \.self) { index in
                            square(index, size: size)
                        }
                    }
                    if let moving {
                        pieceView(moving.piece, size: size)
                            .position(x: CGFloat(movingAt % 8) * size + size / 2,
                                      y: CGFloat(movingAt / 8) * size + size / 2)
                            .allowsHitTesting(false)
                            .zIndex(10)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.width)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.ink.opacity(0.14), lineWidth: 2))
                .shadow(color: Palette.ink.opacity(0.16), radius: 12, y: 7)
            }
            .aspectRatio(1, contentMode: .fit)

            HStack {
                ForEach(0..<8, id: \.self) { col in
                    Text(String(UnicodeScalar(65 + col)!))
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(Palette.dark)
        }
        .padding(18)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func square(_ index: Int, size: CGFloat) -> some View {
        let highlighted = game.legalSelection.contains(where: { $0.to == index })
        let suggested = game.suggested?.to == index
        let checkedKing = game.position.squares[index] == Piece(side: .white, kind: .king) && game.position.inCheck(.white)
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
            if index % 8 == 0 {
                Text("\(8 - index / 8)")
                    .font(.system(size: max(9, size * 0.16), weight: .heavy, design: .rounded))
                    .foregroundColor((index / 8).isMultiple(of: 2) ? Palette.dark : Palette.light)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        ZStack {
            Circle()
                .fill(piece.side == .white ? Palette.cream : Palette.gold)
                .overlay(Circle().stroke(Palette.ink.opacity(0.55), lineWidth: 1.5))
                .frame(width: size * 0.72, height: size * 0.72)
            Text(piece.glyph)
                .font(.system(size: size * 0.72, weight: .regular, design: .serif))
                .foregroundColor(Palette.ink)
                .shadow(color: Color.white.opacity(0.5), radius: 1, x: 0, y: 1)
        }
        .frame(width: size, height: size)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("THỬ THÁCH \(min(game.lessonStage + 1, 4))/4", systemImage: "star.fill")
                        .foregroundColor(Palette.dark)
                    Spacer()
                    Text("⭐ \(game.stars)")
                        .foregroundColor(Palette.ink)
                }
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                Text(game.missionTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.ink)
                Text(game.missionDetail)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Palette.dark)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Palette.gold.opacity(0.27), in: RoundedRectangle(cornerRadius: 22))

            VStack(alignment: .leading, spacing: 10) {
                Label("THẦY CỜ BÊN CẠNH", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .kerning(1.4)
                    .foregroundColor(Palette.dark)
                Text(game.message)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
            }
            .padding(20)
            .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 22))

            HStack(spacing: 10) {
                action("Gợi ý", icon: "lightbulb.fill", color: Palette.gold) { game.hint() }
                    .disabled(game.position.turn != .white || game.isFinished || moving != nil)
                action("Đi lại", icon: "arrow.uturn.backward", color: Palette.light) { game.undo() }
                    .disabled(!game.canUndo || moving != nil)
            }

            HStack(spacing: 10) {
                action("Ván mới", icon: "arrow.clockwise", color: Palette.light) { game.reset() }
                    .disabled(moving != nil)
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
            Text("Đã chơi \(game.games) ván • Thắng \(game.wins) ván")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Palette.dark)
        }
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
            if game.position.result?.contains("Bé đã thắng") == true {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            if game.position.turn == .black && !game.isFinished { computerTurn() }
        }
    }

    private func computerTurn() {
        guard !pendingComputer else { return }
        pendingComputer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard game.position.turn == .black, moving == nil else {
                pendingComputer = false
                return
            }
            let snapshot = game.position
            let difficulty = game.difficulty
            DispatchQueue.global(qos: .userInitiated).async {
                let move = ChessCoach.bestMove(in: snapshot, for: .black, difficulty: difficulty)
                DispatchQueue.main.async {
                    pendingComputer = false
                    guard game.position == snapshot, moving == nil else {
                        if game.position.turn == .black && moving == nil { computerTurn() }
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
                    Text("Bé cầm quân trắng và đi trước. Chạm một quân để thấy các ô sáng có thể đi, rồi chạm ô đích. Nút Gợi ý sẽ chỉ một nước đáng thử. Nút Đi lại cho bé sửa nước vừa đi.")
                        .font(.system(size: 18, design: .rounded))
                    ForEach(Kind.allCases, id: \.self) { kind in
                        HStack(alignment: .top, spacing: 12) {
                            Text(Piece(side: .white, kind: kind).glyph)
                                .font(.system(size: 34))
                                .foregroundColor(Palette.dark)
                                .frame(width: 44)
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
