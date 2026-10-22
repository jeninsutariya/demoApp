import SwiftUI

struct TokenButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, ghost, danger }
    var variant = Variant.primary
    var height: CGFloat = 52
    @Environment(\.isEnabled) private var enabled

    init(variant: Variant = .primary, height: CGFloat = 52) {
        self.variant = variant
        self.height = height
    }

    func makeBody(configuration: Configuration) -> some View {
        let (bg, fg, border): (Color, Color, Color) = switch variant {
        case .primary: (Tokens.Colors.accent, Tokens.Colors.onAccent, .clear)
        case .secondary: (Tokens.Colors.surface, Tokens.Colors.text, Tokens.Colors.borderInput)
        case .ghost: (.clear, Tokens.Colors.accent, .clear)
        case .danger: (Tokens.Colors.danger, Tokens.Colors.onAccent, .clear)
        }
        configuration.label
            .font(.token(Tokens.TextScale.base))
            .fontWeight(.bold)
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: height)
            .padding(.horizontal, Tokens.space[5])
            .background(bg, in: Capsule())
            .overlay(Capsule().strokeBorder(border, lineWidth: 1))
            .opacity(enabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: Tokens.Motion.fast), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TokenButtonStyle {
    static var primary: TokenButtonStyle { TokenButtonStyle(variant: .primary) }
    static var secondary: TokenButtonStyle { TokenButtonStyle(variant: .secondary) }
    static var ghost: TokenButtonStyle { TokenButtonStyle(variant: .ghost) }
    static var danger: TokenButtonStyle { TokenButtonStyle(variant: .danger) }
}

struct ToolButton: View {
    let systemImage: String
    let label: String
    var badge: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Tokens.Colors.text)
                .frame(width: 48, height: 48)
                .background(Tokens.Colors.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
                .shadow(color: Tokens.Colors.text.opacity(0.08), radius: 6, y: 2)
                .overlay(alignment: .topTrailing) {
                    if let badge {
                        Text("\(badge)")
                            .textStyle(Tokens.TextScale.xs, Tokens.Colors.onAccent)
                            .padding(.horizontal, Tokens.space[1])
                            .frame(minWidth: 20)
                            .background(Tokens.Colors.accent, in: Capsule())
                            .offset(x: Tokens.space[1], y: -Tokens.space[1])
                    }
                }
        }
        .buttonStyle(PressScale())
        .accessibilityLabel(badge.map { "\(label), \($0) left" } ?? label)
    }
}

struct PressScale: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(enabled ? 1 : 0.4)
    }
}
