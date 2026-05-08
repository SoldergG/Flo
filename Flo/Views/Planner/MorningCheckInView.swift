import SwiftUI
import SwiftData

// MARK: - Morning Check-In View (FIX #1: saves MoodEntry to context)

struct MorningCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<MoodEntry> { $0.entryType == "morning" }, sort: \MoodEntry.createdAt, order: .reverse)
    private var morningEntries: [MoodEntry]

    @State private var energy: Double = 3
    @State private var mood: Int = 4
    @State private var priority1 = ""
    @State private var priority2 = ""
    @State private var priority3 = ""
    @State private var note = ""

    private let moods: [(emoji: String, label: String)] = [
        ("😫", "Rough"), ("😕", "Low"), ("😐", "Okay"), ("😊", "Good"), ("🔥", "Amazing")
    ]

    // FIX #2: check if already checked in today
    private var alreadyCheckedIn: Bool {
        morningEntries.first.map { Calendar.current.isDateInToday($0.createdAt) } ?? false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text(greetingText)
                                .font(.system(size: 40))
                            Text("Morning Check-In")
                                .font(FloTypography.largeTitle)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                                .font(FloTypography.body)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }
                        .frame(maxWidth: .infinity)

                        if alreadyCheckedIn {
                            // Already done today
                            checkedInBanner
                        } else {
                            // Energy level (FIX #3: shows ticks)
                            sectionCard("Energy Level") {
                                VStack(spacing: 12) {
                                    HStack {
                                        ForEach(1...5, id: \.self) { level in
                                            Button {
                                                withAnimation(FloAnimations.springSnappy) {
                                                    energy = Double(level)
                                                }
                                            } label: {
                                                VStack(spacing: 4) {
                                                    Text(energyIcon(level))
                                                        .font(.system(size: 28))
                                                        .scaleEffect(Int(energy) == level ? 1.2 : 0.85)
                                                        .opacity(Int(energy) == level ? 1 : 0.4)

                                                    Text("\(level)")
                                                        .font(FloTypography.caption2)
                                                        .foregroundStyle(Int(energy) == level ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(.plain)
                                            .animation(FloAnimations.springSnappy, value: energy)
                                        }
                                    }
                                    Text(energyLabel(Int(energy)))
                                        .font(FloTypography.caption)
                                        .foregroundStyle(FloColors.Hex.textSecondary)
                                }
                            }

                            // Mood
                            sectionCard("How are you feeling?") {
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

                            // FIX #4: 3 priority slots instead of 1
                            sectionCard("Top 3 Priorities Today") {
                                VStack(spacing: 10) {
                                    priorityField("1st", text: $priority1, icon: "1.circle.fill", color: FloColors.Hex.error)
                                    priorityField("2nd", text: $priority2, icon: "2.circle.fill", color: FloColors.Hex.warning)
                                    priorityField("3rd", text: $priority3, icon: "3.circle.fill", color: FloColors.Hex.success)
                                }
                            }

                            // Optional note
                            sectionCard("Anything on your mind?") {
                                TextField("How are you feeling about today?", text: $note, axis: .vertical)
                                    .font(FloTypography.body)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                                    .lineLimit(3...6)
                            }

                            FloButton("Start My Day", icon: "sun.max.fill") {
                                saveCheckIn()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Morning Check-In")
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

    // MARK: - Already Checked In

    private var checkedInBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(FloColors.Hex.success)

            Text("Already checked in today!")
                .font(FloTypography.title3)
                .foregroundStyle(FloColors.Hex.textPrimary)

            if let entry = morningEntries.first {
                Text("Mood: \(moods[min(entry.mood - 1, 4)].emoji) · Energy: \(entry.energyLabel)")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)

                if !entry.topPriorities.filter({ !$0.isEmpty }).isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today's priorities:")
                            .font(FloTypography.footnote)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        ForEach(Array(entry.topPriorities.filter({ !$0.isEmpty }).enumerated()), id: \.offset) { i, p in
                            HStack(spacing: 8) {
                                Image(systemName: "\(i+1).circle.fill")
                                    .foregroundStyle(FloColors.Hex.accent)
                                    .font(.system(size: 14))
                                Text(p)
                                    .font(FloTypography.body)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(FloColors.Hex.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

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

    private func priorityField(_ placeholder: String, text: Binding<String>, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 22)
            TextField(placeholder, text: text)
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textPrimary)
        }
        .padding(10)
        .background(FloColors.Hex.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "🌅" }
        else { return "☀️" }
    }

    private func energyIcon(_ level: Int) -> String {
        ["🪫", "😴", "⚡", "🔋", "🚀"][level - 1]
    }

    private func energyLabel(_ level: Int) -> String {
        ["Very Low", "Low", "Medium", "High", "Full Energy"][level - 1]
    }

    // MARK: - Save (FIX #5: actually persists data)

    private func saveCheckIn() {
        let priorities = [priority1, priority2, priority3].filter { !$0.isEmpty }
        let entry = MoodEntry(
            mood: mood,
            energy: Int(energy),
            note: note,
            topPriorities: priorities,
            entryType: "morning"
        )
        context.insert(entry)
        try? context.save()
        HapticManager.trigger(.success)
        dismiss()
    }
}
