import SwiftUI

/// Six matching silhouettes, drawn at any board size without image assets.
struct ChessPieceView: View {
    let piece: Piece
    let size: CGFloat

    private var bodyColor: Color {
        piece.side == .white
            ? Color(red: 1.00, green: 0.99, blue: 0.94)
            : Color(red: 0.12, green: 0.19, blue: 0.23)
    }

    private var detailColor: Color {
        piece.side == .white
            ? Color(red: 0.42, green: 0.49, blue: 0.50)
            : Color(red: 0.67, green: 0.77, blue: 0.75)
    }

    var body: some View {
        ZStack {
            PieceSilhouette(kind: piece.kind)
                .fill(bodyColor)
            PieceDetails(kind: piece.kind)
                .stroke(detailColor, style: StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size * 0.88, height: size * 0.88)
        .shadow(color: Color.black.opacity(piece.side == .white ? 0.34 : 0.27), radius: size * 0.045, x: 0, y: size * 0.035)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct PieceSilhouette: Shape {
    let kind: Kind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        func base(_ x: CGFloat = 20, _ width: CGFloat = 60) {
            path.addRect(CGRect(x: x + 4, y: 75, width: width - 8, height: 7))
            path.addRect(CGRect(x: x, y: 83, width: width, height: 8))
        }

        switch kind {
        case .pawn:
            path.addEllipse(in: CGRect(x: 39, y: 12, width: 22, height: 22))
            path.addRect(CGRect(x: 36, y: 37, width: 28, height: 7))
            path.move(to: p(41, 42))
            path.addCurve(to: p(30, 74), control1: p(39, 56), control2: p(33, 64))
            path.addLine(to: p(70, 74))
            path.addCurve(to: p(59, 42), control1: p(67, 64), control2: p(61, 56))
            path.closeSubpath()
            base(22, 56)

        case .rook:
            path.addLines([p(22, 18), p(34, 18), p(34, 28), p(44, 28), p(44, 18),
                           p(56, 18), p(56, 28), p(66, 28), p(66, 18), p(78, 18),
                           p(74, 40), p(26, 40), p(22, 18)])
            path.addLines([p(31, 42), p(69, 42), p(72, 74), p(28, 74), p(31, 42)])
            base()

        case .knight:
            path.move(to: p(58, 13))
            path.addLine(to: p(51, 24))
            path.addLine(to: p(44, 20))
            path.addLine(to: p(39, 30))
            path.addCurve(to: p(22, 44), control1: p(34, 34), control2: p(26, 36))
            path.addLine(to: p(25, 56))
            path.addQuadCurve(to: p(39, 54), control: p(32, 59))
            path.addLine(to: p(47, 48))
            path.addQuadCurve(to: p(51, 59), control: p(53, 54))
            path.addLine(to: p(40, 74))
            path.addLine(to: p(72, 74))
            path.addQuadCurve(to: p(70, 49), control: p(69, 61))
            path.addLine(to: p(78, 39))
            path.addLine(to: p(70, 31))
            path.addLine(to: p(65, 18))
            path.closeSubpath()
            base(21, 58)

        case .bishop:
            path.addEllipse(in: CGRect(x: 45, y: 8, width: 10, height: 10))
            path.move(to: p(50, 19))
            path.addCurve(to: p(29, 63), control1: p(36, 28), control2: p(27, 46))
            path.addQuadCurve(to: p(50, 72), control: p(36, 72))
            path.addQuadCurve(to: p(71, 63), control: p(64, 72))
            path.addCurve(to: p(50, 19), control1: p(73, 46), control2: p(64, 28))
            path.closeSubpath()
            base(22, 56)

        case .queen:
            let jewels: [(CGFloat, CGFloat)] = [(15, 19), (34, 12), (47, 6), (66, 12), (85, 19)]
            for (x, y) in jewels {
                path.addEllipse(in: CGRect(x: x, y: y, width: 8, height: 8))
            }
            path.addLines([p(18, 32), p(37, 47), p(50, 25), p(63, 47), p(82, 32),
                           p(75, 65), p(25, 65), p(18, 32)])
            path.addRect(CGRect(x: 28, y: 67, width: 44, height: 7))
            base(17, 66)

        case .king:
            path.addRect(CGRect(x: 46, y: 9, width: 8, height: 28))
            path.addRect(CGRect(x: 36, y: 18, width: 28, height: 8))
            path.move(to: p(27, 43))
            path.addQuadCurve(to: p(42, 37), control: p(30, 32))
            path.addQuadCurve(to: p(50, 42), control: p(46, 38))
            path.addQuadCurve(to: p(58, 37), control: p(54, 38))
            path.addQuadCurve(to: p(73, 43), control: p(70, 32))
            path.addLine(to: p(68, 74))
            path.addLine(to: p(32, 74))
            path.closeSubpath()
            base(18, 64)
        }

        return path.applying(CGAffineTransform(
            a: rect.width / 100, b: 0, c: 0, d: rect.height / 100,
            tx: rect.minX, ty: rect.minY
        ))
    }
}

private struct PieceDetails: Shape {
    let kind: Kind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        switch kind {
        case .pawn:
            path.move(to: p(38, 47)); path.addLine(to: p(62, 47))
        case .rook:
            path.move(to: p(27, 41)); path.addLine(to: p(73, 41))
            path.move(to: p(34, 68)); path.addLine(to: p(66, 68))
        case .knight:
            path.addEllipse(in: CGRect(x: 41, y: 35, width: 4, height: 4))
            path.move(to: p(59, 26)); path.addQuadCurve(to: p(62, 59), control: p(73, 42))
        case .bishop:
            path.move(to: p(61, 31)); path.addLine(to: p(42, 58))
        case .queen:
            path.move(to: p(26, 61)); path.addLine(to: p(74, 61))
        case .king:
            path.move(to: p(34, 58)); path.addLine(to: p(66, 58))
        }
        return path.applying(CGAffineTransform(
            a: rect.width / 100, b: 0, c: 0, d: rect.height / 100,
            tx: rect.minX, ty: rect.minY
        ))
    }
}
