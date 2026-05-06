import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.createdAt)
    private var habits: [Habit]
    @State private var vm = HabitViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                if habits.isEmpty {
                    emptyState
                } else {
                    habitsList
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    FloIconButton("plus.circle.fill", color: FloColors.Hex.accent) {
                        vm.showingAddHabit = true
                    }
                }
            }
            .sheet(isPresented: $vm.showingAddHabit) {
                AddHabitSheet(vm: vm)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame")
                .font(.system(size: 56))
                .foregroundStyle(FloColors.Hex.border)

            Text("No habits yet")
                .font(FloTypography.title3)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Text("Build consistency with daily habits")
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)

            FloButton("Add Habit", icon: "plus", style: .secondary) {
                vm.showingAddHabit = true
            }
            .frame(width: 200)
        }
    }

    private var habitsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Week header
                weekHeader

                // Habits
                ForEach(habits) { habit in
                    HabitCard(habit: habit) {
                        withAnimation(FloAnimations.springBouncy) {
                            vm.toggleCompletion(habit, context: context)
                        }
                    }
                }

                // Summary
                if !habits.isEmpty {
                    summaryCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
    }

    private var weekHeader: some View {
        HStack(spacing: 0) {
            ForEach(vm.weekDates, id: \.self) { date in
                let isToday = Calendar.current.isDateInToday(date)
                VStack(spacing: 6) {
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(FloTypography.caption2)
                        .foregroundStyle(FloColors.Hex.textTertiary)

                    Text(date.formatted(.dateTime.day()))
                        .font(isToday ? FloTypography.headline : FloTypography.footnote)
                        .foregroundStyle(isToday ? .white : FloColors.Hex.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(isToday ? FloColors.Hex.accent : .clear)
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var summaryCard: some View {
        FloCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(FloTypography.footnote)
                        .foregroundStyle(FloColors.Hex.textSecondary)

                    let completed = habits.filter(\.isCompletedToday).count
                    Text("\(completed)/\(habits.count) completed")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                }

                Spacer()

                let completed = habits.filter(\.isCompletedToday).count
                FloHabitRing(completed: completed, total: habits.count, size: 48)
            }
        }
    }
}

// MARK: - Habit Card

struct HabitCard: View {
    let habit: Habit
    let onToggle: () -> Void
    @State private var showConfetti = false

    var body: some View {
        FloPressableCard(action: {
            if !habit.isCompletedToday {
                showConfetti = true
            }
            onToggle()
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(habit.isCompletedToday ? FloColors.Hex.success.opacity(0.15) : FloColors.Hex.accentSoft)
                        .frame(width: 44, height: 44)

                    Image(systemName: habit.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(habit.isCompletedToday ? FloColors.Hex.success : FloColors.Hex.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(habit.currentStreak > 0 ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                        Text("\(habit.currentStreak) day streak")
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                }

                Spacer()

                // Check
                ZStack {
                    Circle()
                        .strokeBorder(
                            habit.isCompletedToday ? FloColors.Hex.success : FloColors.Hex.border,
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if habit.isCompletedToday {
                        Circle()
                            .fill(FloColors.Hex.success)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(FloAnimations.springBouncy, value: habit.isCompletedToday)
            }
        }
        .confetti(isActive: $showConfetti)
    }
}

// MARK: - Streak Chart

struct StreakChart: View {
    let completions: [Date]
    let weeks: Int

    private var grid: [[Bool]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let completionDays = Set(completions.map { calendar.startOfDay(for: $0) })

        var result: [[Bool]] = []
        for week in (0..<weeks).reversed() {
            var weekData: [Bool] = []
            for day in 0..<7 {
                let offset = -(week * 7 + (6 - day))
                if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                    weekData.append(completionDays.contains(calendar.startOfDay(for: date)))
                } else {
                    weekData.append(false)
                }
            }
            result.append(weekData)
        }
        return result
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<grid.count, id: \.self) { week in
                VStack(spacing: 3) {
                    ForEach(0..<grid[week].count, id: \.self) { day in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(grid[week][day] ? FloColors.Hex.accent : FloColors.Hex.border.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
    }
}

// MARK: - Add Habit Sheet

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: HabitViewModel

    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var frequency: Frequency = .daily

    private let icons = [
        "star.fill", "heart.fill", "flame.fill", "drop.fill",
        "figure.run", "book.fill", "moon.fill", "cup.and.saucer.fill",
        "dumbbell.fill", "brain.head.profile.fill", "leaf.fill", "pencil"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Preview
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(FloColors.Hex.accentSoft)
                                    .frame(width: 52, height: 52)
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(FloColors.Hex.accent)
                            }

                            VStack(alignment: .leading) {
                                Text(name.isEmpty ? "Habit Name" : name)
                                    .font(FloTypography.headline)
                                    .foregroundStyle(name.isEmpty ? FloColors.Hex.textTertiary : FloColors.Hex.textPrimary)
                                Text(frequency.label)
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(FloColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)

                        FloTextField(placeholder: "e.g. Read, Exercise, Meditate", text: $name, icon: "pencil")

                        // Icon picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                                ForEach(icons, id: \.self) { i in
                                    Image(systemName: i)
                                        .font(.system(size: 20))
                                        .foregroundStyle(icon == i ? FloColors.Hex.accent : FloColors.Hex.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(icon == i ? FloColors.Hex.accentSoft : FloColors.Hex.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(icon == i ? FloColors.Hex.accent : FloColors.Hex.border, lineWidth: 1)
                                        )
                                        .onTapGesture { icon = i }
                                }
                            }
                        }

                        // Frequency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequency")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            HStack(spacing: 8) {
                                ForEach([Frequency.daily, .weekdays, .weekends], id: \.self) { freq in
                                    Button {
                                        withAnimation(FloAnimations.springSnappy) {
                                            frequency = freq
                                        }
                                    } label: {
                                        Text(freq.label)
                                            .font(FloTypography.footnote)
                                            .foregroundStyle(frequency == freq ? .white : FloColors.Hex.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(frequency == freq ? FloColors.Hex.accent : FloColors.Hex.surface)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(frequency == freq ? FloColors.Hex.accent : FloColors.Hex.border, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        vm.addHabit(name: name, icon: icon, frequency: frequency, context: context)
                        dismiss()
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}
