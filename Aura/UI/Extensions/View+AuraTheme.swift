import SwiftUI

extension View {
    func auraCardStyle(theme: AuraTheme, radius: CGFloat = 18) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(theme.cardFill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(theme.stroke, lineWidth: 1)
            }
            .shadow(color: theme.heroGlow.opacity(0.18), radius: 18, x: 0, y: 12)
    }
}
