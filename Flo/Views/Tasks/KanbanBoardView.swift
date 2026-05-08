import SwiftUI
import SwiftData

struct KanbanBoardView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TaskItem> { $0.parentTask == nil },
           sort: \TaskItem.createdAt, order: .reverse)
    private var tasks: [TaskItem]

    private let columns = [
        KanbanColumn(id: "todo", title: "To Do", icon: "circle", color: FloColors.Hex.textSecondary),
        KanbanColumn(id: "in_progress", title: "In Progress", icon: "arrow.right.circle.fill", color: FloColors.Hex.accent),
        KanbanColumn(id: "done", title: "Done", icon: "checkmark.circle.fill", color: FloColors.Hex.success)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                if tasks.isEmpty {
                    emptyState
                } else {
                    kanbanBoard
                }
            }
            .navigationTitle("Kanban Board")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.split.3x1")
                .font(.system(size: 56))
                .foregroundStyle(FloColors.Hex.border)

            Text("No tasks yet")
                .font(FloTypography.title3)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Text("Add tasks to organize them on the board")
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)
        }
    }

    private var kanbanBoard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(columns) { column in
                    kanbanColumn(column)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Column

    private func kanbanColumn(_ column: KanbanColumn) -> some View {
        let columnTasks = tasksForColumn(column.id)

        return VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: column.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(column.color)

                Text(column.title)
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("\(columnTasks.count)")
                    .font(FloTypography.badge)
                    .foregroundStyle(column.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(column.color.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()
            }
            .padding(.horizontal, 4)

            // Task cards
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(columnTasks) { task in
                        kanbanCard(task, color: column.color)
                            // FIX #65: use model ID instead of title for drag (prevents duplicate-title bug)
                            .draggable(task.persistentModelID.hashValue.description)
                    }

                    if columnTasks.isEmpty {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(FloColors.Hex.border.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .frame(height: 60)
                            .overlay(
                                Text("Drop tasks here")
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textTertiary)
                            )
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 280)
        .background(FloColors.Hex.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(FloColors.Hex.border.opacity(0.5), lineWidth: 1)
        )
        .dropDestination(for: String.self) { items, _ in
            // FIX #66: match by hash ID, not title
            guard let hashStr = items.first,
                  let task = tasks.first(where: { $0.persistentModelID.hashValue.description == hashStr }) else { return false }
            withAnimation(FloAnimations.springDefault) {
                moveTask(task, to: column.id)
            }
            return true
        }
    }

    // MARK: - Card

    private func kanbanCard(_ task: TaskItem, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: task.priority.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(task.priority.color)

                Text(task.title)
                    .font(FloTypography.subheadline)
                    .foregroundStyle(FloColors.Hex.textPrimary)
                    .lineLimit(2)

                Spacer()
            }

            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if let project = task.project {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(project.color)
                            .frame(width: 6, height: 6)
                        Text(project.name)
                            .font(FloTypography.caption2)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                }

                Spacer()

                if let dueDate = task.dueDate {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(dueDate.formatted(.dateTime.month(.abbreviated).day()))
                            .font(FloTypography.caption2)
                    }
                    .foregroundStyle(task.isOverdue ? FloColors.Hex.error : FloColors.Hex.textTertiary)
                }
            }
        }
        .padding(12)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helpers

    // FIX #67: use kanbanStatus field (designed for this purpose)
    private func tasksForColumn(_ status: String) -> [TaskItem] {
        tasks.filter { $0.kanbanStatus == status }
    }

    private func moveTask(_ task: TaskItem, to column: String) {
        task.kanbanStatus = column
        switch column {
        case "done":
            task.isCompleted = true
            task.completedAt = .now
        default:
            task.isCompleted = false
            task.completedAt = nil
        }
        try? context.save()
    }
}

// MARK: - Kanban Column Model

private struct KanbanColumn: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
}
