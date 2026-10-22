import SwiftUI

// Placeholder cat drawn for this project (same outline as the web build).
// Replace with commissioned art; never the original game's cats.
struct CatShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let o = CGPoint(x: rect.midX - 12 * s, y: rect.midY - 12 * s)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x * s, y: o.y + y * s) }
        var path = Path()
        path.move(to: p(5, 3))
        path.addLine(to: p(8.5, 7.2))
        path.addLine(to: p(15.5, 7.2))
        path.addLine(to: p(19, 3))
        path.addLine(to: p(20, 11.2))
        path.addArc(center: p(12, 11.2), radius: 8 * s, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct CatIcon: View {
    var color = Tokens.Colors.cat

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) / 24
            ZStack {
                CatShape().fill(color)
                Circle().fill(Tokens.Colors.surface).frame(width: 2.4 * s).offset(x: -2.5 * s, y: 0.5 * s)
                Circle().fill(Tokens.Colors.surface).frame(width: 2.4 * s).offset(x: 2.5 * s, y: 0.5 * s)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct LivesView: View {
    let lives: Int

    var body: some View {
        HStack(spacing: Tokens.space[1]) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .foregroundStyle(i < lives ? Tokens.Colors.danger : Tokens.Colors.border)
                    .scaleEffect(i < lives ? 1 : 0.85)
            }
        }
        .animation(.spring(duration: Tokens.Motion.base), value: lives)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(lives) of 3 lives left")
    }
}
