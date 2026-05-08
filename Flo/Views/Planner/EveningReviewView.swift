import SwiftUI
import SwiftData

// MARK: - Evening Review View (FIX #6: saves MoodEntry to context)

struct EveningReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<MoodEntry> { $0.entryType == "evening" }, sort: \MoodEntry.createdAt, order: .reverse)
    private var eveningEntries: [MoodEntry]
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted }, sort: \TaskItem.completedAt, order: .reverse)
    private var completedTasks: [TaskItem]
    @Query(filter: #Predicate<Habit> { !$0.isArchived })
    private var habits: [Habit]

    @State private var rating: Int = 3
    @State private var win = ""
    @State private var gratitude = ""
    @State private var tomorrowIntent = ""
    @State private var mood: Int = 3

    private let moods: [(emoji: String, label: String)] = [
        ("😫", "Rough"), ("😕", "Low"), ("😐", "Okay"), ("😊", "Good"), ("🌟", "Amazing")
    ]

    // FIX #7: guard against double entry
    private var alreadyReviewed: Bool {
        eveningEntries.first.map { Calendar.current.isDateInToday($0.createdAt) } ?? false
    }

    // FIX #8: today's completed tasks count
    private var todayCompletedCount: Int {
        completedTasks.filter {
            guard let at = $0.completedAt else { return false }
            return Calendar.current.isDateInToday(at)
        }.count
    }

    private var habitsCompletedToday: Int {
        habits.filter(\.isCompletedToday).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("🌙")
                                .font(.system(size: 40))
                            Text("Evening Review")
                                .font(FloTypography.largeTitle)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                                .font(FloTypography.body)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }
                        .frame(maxWidth: .infinity)

                        if alreadyReviewed {
                            alreadyReviewedBanner
                        } else {
                            // FIX #9: today's summary card
                            daySummaryCard

                            // Mood
                            sectionCard("How was your day overall?") {
                                HStack(spacing: 0) {
                                    ForEach(Array(moods.enumerated()), id: \.offset) { idx, item in
                                        Button {
                                            withAnimation(FloAnimations.springSnappy) { mood = idx + 1 }
                                        } label: {
                                            VStack(spacing: 6) {
                                                Text(item.emoji)
                                                    .font(.system(size: 32))
                                                    .scaleEffect(mood == idx + 1 ? 1.2 : 0.85)
                                                    .opacity(mood == idx + 1 ? 1 : 0.4)
                                                Text(item.label)
                                                    .font(FloTypography.caption2)
                                                    .foregroundStyle(mood == idx + 1 ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.plain)
                                        .animation(FloAnimations.springSnappy, value: mood)
                                    }
                                }
                            }

                            // Day rating
                            sectionCard("Rate your day") {
                                HStack(spacing: 16) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button {
                                            withAnimation(FloAnimations.springBouncy) { rating = star }
                                        } label: {
                                            Image(systemName: star <= rating ? "star.fill" : "star")
                                                .font(.system(size: 32))
                                                .foregroundStyle(star <= rating ? FloColors.Hex.warning : FloColors.Hex.border)
                                                .scaleEffect(star == rating ? 1.2 : 1.0)
                                                .animation(FloAnimations.springBouncy, value: rating)
                                        }
                                        .buttonStyle(.plain)
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }

                            // Win + gratitude
                            sectionCard("Today's wins") {
                                VStack(spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "trophy.fill")
                                            .foregroundStyle(FloColors.Hex.warning)
                                            .frame(width: 22)
                                        TextField("Biggest win today...", text: $win)
                                            .font(FloTypography.body)
                                            .foregroundStyle(FloColors.Hex.textPrimary)
                                    }
                                    .padding(10)
                                    .background(FloColors.Hex.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    HStack(spacing: 10) {
                                        Image(systemName: "heart.fill")
                                            .foregroundStyle(FloColors.Hex.error)
                                            .frame(width: 22)
                                        TextField("Grateful for...", text: $gratitude)
                                            .font(FloTypography.body)
                                            .foregroundStyle(FloColors.Hex.textPrimary)
                                    }
                                    .padding(10)
                                    .background(FloColors.Hex.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }

                            // FIX #10: tomorrow's intention (new field)
                            sectionCard("Tomorrow's intention") {
                                HStack(spacing: 10) {
                                    Image(systemName: "sunrise.fill")
                                        .foregroundStyle(FloColors.Hex.accent)
                                        .frame(width: 22)
                                    TextField("What's the one thing you want to focus on tomorrow?", text: $tomorrowIntent, axis: .vertical)
                                        .font(FloTypography.body)
                                        .foregroundStyle(FloColors.Hex.textPrimary)
                                        .lineLimit(2...4)
                                }
                                .padding(10)
                                .background(FloColors.Hex.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            FloButton("End My Day", icon: "moon.stars.fill") {
                                saveReview()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Evening Review")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
            }
        }
    }

    // MARK: - Day Summary Card

    private var daySummaryCard: some View {
        FloCard {
            HStack(spacing: 0) {
                summaryItem(value: "\(todayCompletedCount)", label: "Tasks done", icon: "checkmark.circle.fill", color: FloColors.Hex.success)
                Divider().frame(height: 36)
                summaryItem(value: "\(habitsCompletedToday)/\(habits.count)", label: "Habits", icon: "flame.fill", color: FloColors.Hex.warning)
            }
        }
    }

    private func summaryItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color).font(.system(size: 14))
            Text(value).font(FloTypography.headline).foregroundStyle(FloColors.Hex.textPrimary)
            Text(label).font(FloTypography.caption2).foregroundStyle(FloColors.Hex.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Already Reviewed

    private var alreadyReviewedBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: "8B5CF6"))
            Text("Already reviewed today!")
                .font(FloTypography.title3)
                .foregroundStyle(FloColors.Hex.textPrimary)
            FloButton("Close", style: .secondary) { dismiss() }
        }
        .padding(.top, 20)
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textPrimary)
            content()
        }
        .padding(16)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // FIX #11: actually saves data
    private func saveReview() {
        let note = [win.isEmpty ? nil : "Win: \(win)", gratitude.isEmpty ? nil : "Grateful: \(gratitude)", tomorrowIntent.isEmpty ? nil : "Tomorrow: \(tomorrowIntent)"]
            .compactMap { $0 }
            .joined(separator: "\n")

        let entry = MoodEntry(
            mood: mood,
            energy: rating,
            note: note,
            topPriorities: tomorrowIntent.isEmpty ? [] : [tomorrowIntent],
            entryType: "evening",
            productivityScore: nil,
            gratitude: gratitude.isEmpty ? nil : gratitude
        )
        context.insert(entry)
        try? context.save()
        HapticManager.trigger(.success)
        dismiss()
    }
}
