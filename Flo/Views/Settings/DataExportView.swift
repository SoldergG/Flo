import SwiftUI

struct DataExportView: View {
    @State private var isExporting = false

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 48))
                    .foregroundStyle(FloColors.Hex.accent)

                Text("Export Your Data")
                    .font(FloTypography.title3)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Download all your tasks, habits, focus sessions, and journal entries.")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 10) {
                    exportOption(icon: "doc.text", title: "Tasks", subtitle: "All tasks and projects")
                    exportOption(icon: "flame", title: "Habits", subtitle: "Habits and completion history")
                    exportOption(icon: "timer", title: "Focus", subtitle: "Focus sessions and presets")
                    exportOption(icon: "book", title: "Journal", subtitle: "All journal entries")
                }
                .padding(.horizontal, 20)

                FloButton("Export All (CSV)", icon: "arrow.down.doc.fill") {
                    isExporting = true
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Data Export")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func exportOption(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(FloColors.Hex.accent)
                .frame(width: 36, height: 36)
                .background(FloColors.Hex.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FloTypography.subheadline.weight(.semibold))
                    .foregroundStyle(FloColors.Hex.textPrimary)
                Text(subtitle)
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(FloColors.Hex.success)
        }
        .padding(12)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
