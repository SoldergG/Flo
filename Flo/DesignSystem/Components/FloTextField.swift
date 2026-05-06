import SwiftUI

struct FloTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isFocused ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                    .animation(FloAnimations.easeFast, value: isFocused)
            }

            TextField(placeholder, text: $text)
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textPrimary)
                .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isFocused ? FloColors.Hex.accent : FloColors.Hex.border,
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .animation(FloAnimations.easeFast, value: isFocused)
    }
}

// MARK: - Text Editor

struct FloTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }

            TextEditor(text: $text)
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: minHeight)
        }
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(FloColors.Hex.border, lineWidth: 1)
        )
    }
}
