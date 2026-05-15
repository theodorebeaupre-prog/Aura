import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Menu {
            ForEach(themeManager.themes) { theme in
                Button {
                    themeManager.selectTheme(theme)
                } label: {
                    HStack(spacing: 10) {
                        themeSwatch(theme)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(theme.name)
                            Text(theme.caption)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if theme.id == themeManager.selectedTheme.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: themeManager.selectedTheme.symbol)
                Text(themeManager.selectedTheme.name)
            }
        }
        .menuStyle(.borderlessButton)
    }

    private func themeSwatch(_ theme: AuraTheme) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(theme.previewGradient)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(theme.stroke, lineWidth: 1)
            }
            .frame(width: 20, height: 20)
    }
}
