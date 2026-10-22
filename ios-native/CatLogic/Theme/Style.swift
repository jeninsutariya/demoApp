import SwiftUI

// Text in the token type scale, Nunito, scaling with Dynamic Type.
extension Font {
    static func token(_ s: Tokens.TextStyle, relativeTo style: Font.TextStyle = .body) -> Font {
        let name = s.weight >= 800 ? "Nunito-ExtraBold" : s.weight >= 700 ? "Nunito-Bold" : "Nunito-Medium"
        return .custom(name, size: s.size, relativeTo: style)
    }
}

extension View {
    func textStyle(_ s: Tokens.TextStyle, _ color: Color = Tokens.Colors.text, relativeTo style: Font.TextStyle = .body) -> some View {
        font(.token(s, relativeTo: style))
            .lineSpacing(s.line - s.size)
            .foregroundStyle(color)
    }

    func card() -> some View {
        padding(Tokens.space[4])
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.Colors.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg))
            .shadow(color: Tokens.Colors.text.opacity(0.08), radius: 6, y: 2)
    }

    // Page frame: background and a centred column at content-max width
    func page() -> some View {
        frame(maxWidth: Tokens.Layout.contentMax)
            .padding(.horizontal, Tokens.Layout.gutter)
            .frame(maxWidth: .infinity)
            .background(Tokens.Colors.bg)
    }
}

enum Format {
    static func time(_ ms: Int) -> String {
        let s = ms / 1000, m = s / 60, h = m / 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m % 60, s % 60) : String(format: "%d:%02d", m, s % 60)
    }

    static func date(_ key: String) -> String {
        let p = key.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3, let d = Calendar.current.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) else { return key }
        return d.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}
