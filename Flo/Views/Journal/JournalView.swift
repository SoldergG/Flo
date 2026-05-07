import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var showNewEntry = false

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            if entries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(FloColors.Hex.accent.opacity(0.4))
                    Text("No journal entries yet")
                        .font(FloTypography.title3)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                    Text("Start writing to track your thoughts")
                        .font(FloTypography.body)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                                        .font(FloTypography.headline)
                                        .foregroundStyle(FloColors.Hex.textPrimary)
                                    Spacer()
                                    Text(entry.createdAt.formatted(.dateTime.hour().minute()))
                                        .font(FloTypography.caption)
                                        .foregroundStyle(FloColors.Hex.textTertiary)
                                }

                                Text(entry.content)
                                    .font(FloTypography.body)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                                    .lineLimit(3)
                            }
                            .padding(14)
                            .background(FloColors.Hex.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Journal")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
