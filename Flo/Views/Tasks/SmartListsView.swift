import SwiftUI
import SwiftData

struct SmartListsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TaskItem> { $0.parentTask == nil },
           sort: \TaskItem.createdAt, order: .reverse)
    private var allTasks: [TaskItem]

    @State private var selectedList: SmartListFilter?

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(SmartListFilter.allCases) { list in
                            smartListRow(list)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Smart Lists")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(item: $selectedList) { list in
                SmartListDetailView(list: list, tasks: tasksForList(list))
            }
        }
    }

    // MARK: - Smart List Row

    private func smartListRow(_ list: SmartListFilter) -> some View {
        let count = tasksForList(list).count

        return FloPressableCard(action: {
            selectedList = list
        }) {
            HStack(spacing: 14) {
                Image(systemName: list.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(list.color)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(list.title)
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    Text(list.subtitle)
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }

                Spacer()

                Text("\(count)")
                    .font(FloTypography.title3)
                    .foregroundStyle(count > 0 ? list.color : FloColors.Hex.textTertiary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
        }
    }

    // MARK: - Filtering

    private func tasksForList(_ list: SmartListFilter) -> [TaskItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: today)!

        switch list {
        case .overdue:
            return allTasks.filter { !$0.isCompleted && $0.isOverdue }
        case .today:
            return allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 >= today && $0 < tomorrow } ?? false) }
        case .thisWeek:
            return allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 >= today && $0 < weekEnd } ?? false) }
        case .upcoming:
            return allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 >= weekEnd } ?? false) }
        case .noDate:
            return allTasks.filter { !$0.isCompleted && $0.dueDate == nil }
        case .completed:
            return allTasks.filter(\.isCompleted)
        }
    }
}

// MARK: - Smart List Enum

enum SmartListFilter: String, CaseIterable, Identifiable {
    case overdue
    case today
    case thisWeek
    case upcoming
    case noDate
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overdue: "Overdue"
        case .today: "Today"
        case .thisWeek: "This Week"
        case .upcoming: "Upcoming"
        case .noDate: "No Date"
        case .completed: "Completed"
        }
    }

    var subtitle: String {
        switch self {
        case .overdue: "Tasks past their due date"
        case .today: "Due today"
        case .thisWeek: "Due in the next 7 days"
        case .upcoming: "Due after this week"
        case .noDate: "Tasks without a due date"
        case .completed: "All finished tasks"
        }
    }

    var icon: String {
        switch self {
        case .overdue: "exclamationmark.triangle.fill"
        case .today: "sun.max.fill"
        case .thisWeek: "calendar.badge.clock"
        case .upcoming: "arrow.right.circle.fill"
        case .noDate: "questionmark.circle.fill"
        case .completed: "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .overdue: FloColors.Hex.error
        case .today: FloColors.Hex.accent
        case .thisWeek: FloColors.Hex.warning
        case .upcoming: Color(hex: "4A90D9")
        case .noDate: FloColors.Hex.textTertiary
        case .completed: FloColors.Hex.success
        }
    }
}

// MARK: - Smart List Detail

struct SmartListDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let list: SmartListFilter
    let tasks: [TaskItem]

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                if tasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: list.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(list.color.opacity(0.4))

                        Text("No tasks")
                            .font(FloTypography.title3)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        Text(list.subtitle)
                            .font(FloTypography.body)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(tasks) { task in
                                TaskRow(task: task) {
                                    withAnimation(FloAnimations.springBouncy) {
                                        task.isCompleted.toggle()
                                        task.completedAt = task.isCompleted ? .now : nil
                                        try? context.save()
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(list.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            }
        }
    }
}
