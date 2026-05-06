import SwiftUI
import SwiftData

struct DailyPlannerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @Query(filter: #Predicate<FocusSession> { $0.wasCompleted }) private var sessions: [FocusSession]

    @State private var selectedDate = Date.now
    @State private var greeting = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        statsRow
                        todaysTasks
                        habitsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Today")
            .onAppear { updateGreeting() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(FloTypography.largeTitle)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Stats

    private var todayTasks: [TaskItem] {
        let today = Calendar.current.startOfDay(for: selectedDate)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return allTasks.filter { task in
            if let scheduled = task.scheduledDate {
                return scheduled >= today && scheduled < tomorrow
            }
            if let due = task.dueDate {
                return due >= today && due < tomorrow
            }
            return Calendar.current.isDateInToday(task.createdAt) && task.parentTask == nil
        }
    }

    private var completedToday: [TaskItem] {
        todayTasks.filter(\.isCompleted)
    }

    private var habitsCompletedToday: Int {
        habits.filter(\.isCompletedToday).count
    }

    private var todayFocusMinutes: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return sessions
            .filter { $0.createdAt >= today }
            .reduce(0) { $0 + Int(($1.actualDuration ?? $1.duration) / 60) }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            FloStatCard(
                title: "Tasks",
                value: "\(completedToday.count)/\(todayTasks.count)",
                icon: "checkmark.circle.fill",
                color: FloColors.Hex.accent
            )

            FloStatCard(
                title: "Habits",
                value: "\(habitsCompletedToday)/\(habits.count)",
                icon: "flame.fill",
                color: FloColors.Hex.warning
            )

            FloStatCard(
                title: "Focus",
                value: "\(todayFocusMinutes)m",
                icon: "timer",
                color: FloColors.Hex.success
            )
        }
    }

    // MARK: - Today's Tasks

    private var todaysTasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Tasks")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Spacer()

                if !todayTasks.isEmpty {
                    Text("\(completedToday.count)/\(todayTasks.count)")
                        .font(FloTypography.badge)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FloColors.Hex.border.opacity(0.5))
                        .clipShape(Capsule())
                }
            }

            if todayTasks.isEmpty {
                FloCard {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(FloColors.Hex.warning)
                        Text("No tasks scheduled for today")
                            .font(FloTypography.body)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        Spacer()
                    }
                }
            } else {
                ForEach(todayTasks) { task in
                    TaskRow(task: task) {
                        withAnimation(FloAnimations.springBouncy) {
                            task.isCompleted.toggle()
                            task.completedAt = task.isCompleted ? .now : nil
                            try? context.save()
                        }
                    }
                    .background(FloColors.Hex.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    // MARK: - Habits Section

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Habits")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Spacer()

                FloHabitRing(completed: habitsCompletedToday, total: habits.count, size: 28)
            }

            if habits.isEmpty {
                FloCard {
                    HStack {
                        Image(systemName: "flame")
                            .foregroundStyle(FloColors.Hex.border)
                        Text("No habits yet — add some to track daily")
                            .font(FloTypography.body)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        Spacer()
                    }
                }
            } else {
                ForEach(habits) { habit in
                    MiniHabitRow(habit: habit) {
                        withAnimation(FloAnimations.springBouncy) {
                            if habit.isCompletedToday {
                                if let c = habit.completions.first(where: { Calendar.current.isDateInToday($0.date) }) {
                                    context.delete(c)
                                }
                            } else {
                                let completion = HabitCompletion(date: .now)
                                completion.habit = habit
                                habit.completions.append(completion)
                                context.insert(completion)
                            }
                            try? context.save()
                        }
                    }
                }
            }
        }
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        case 17..<22: greeting = "Good evening"
        default: greeting = "Good night"
        }
    }
}

// MARK: - Mini Habit Row

struct MiniHabitRow: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        FloPressableCard(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: habit.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(habit.isCompletedToday ? FloColors.Hex.success : FloColors.Hex.accent)
                    .frame(width: 32, height: 32)
                    .background(
                        (habit.isCompletedToday ? FloColors.Hex.success : FloColors.Hex.accent).opacity(0.12)
                    )
                    .clipShape(Circle())

                Text(habit.name)
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Spacer()

                if habit.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(habit.currentStreak)")
                            .font(FloTypography.badge)
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                }

                ZStack {
                    Circle()
                        .strokeBorder(habit.isCompletedToday ? FloColors.Hex.success : FloColors.Hex.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if habit.isCompletedToday {
                        Circle()
                            .fill(FloColors.Hex.success)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}
