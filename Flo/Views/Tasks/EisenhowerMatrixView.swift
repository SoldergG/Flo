import SwiftUI
import SwiftData

struct EisenhowerMatrixView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted && $0.parentTask == nil },
           sort: \TaskItem.createdAt, order: .reverse)
    private var tasks: [TaskItem]

    private var urgentImportant: [TaskItem] {
        tasks.filter { $0.priority == .high && isUrgent($0) }
    }

    private var notUrgentImportant: [TaskItem] {
        tasks.filter { $0.priority == .high && !isUrgent($0) }
    }

    private var urgentNotImportant: [TaskItem] {
        tasks.filter { $0.priority != .high && isUrgent($0) }
    }

    private var neitherUrgentNorImportant: [TaskItem] {
        tasks.filter { $0.priority != .high && !isUrgent($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                if tasks.isEmpty {
                    emptyState
                } else {
                    matrixGrid
                }
            }
            .navigationTitle("Eisenhower Matrix")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 56))
                .foregroundStyle(FloColors.Hex.border)

            Text("No active tasks")
                .font(FloTypography.title3)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Text("Add tasks with priorities and due dates to see them organized here")
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Matrix Grid

    private var matrixGrid: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Column headers
                HStack(spacing: 12) {
                    Spacer().frame(width: 0)
                    Text("URGENT")
                        .font(FloTypography.badge)
                        .foregroundStyle(FloColors.Hex.error)
                        .frame(maxWidth: .infinity)
                    Text("NOT URGENT")
                        .font(FloTypography.badge)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    // Row labels
                    VStack(spacing: 12) {
                        Text("I\nM\nP\nO\nR\nT\nA\nN\nT")
                            .font(FloTypography.badge)
                            .foregroundStyle(FloColors.Hex.accent)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: .infinity)

                        Text("N\nO\nT")
                            .font(FloTypography.badge)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: 14)

                    VStack(spacing: 12) {
                        // Top row
                        HStack(spacing: 12) {
                            quadrantView(
                                title: "Do First",
                                icon: "bolt.fill",
                                color: FloColors.Hex.error,
                                tasks: urgentImportant,
                                quadrant: "urgent_important"
                            )

                            quadrantView(
                                title: "Schedule",
                                icon: "calendar",
                                color: FloColors.Hex.accent,
                                tasks: notUrgentImportant,
                                quadrant: "not_urgent_important"
                            )
                        }

                        // Bottom row
                        HStack(spacing: 12) {
                            quadrantView(
                                title: "Delegate",
                                icon: "person.2.fill",
                                color: FloColors.Hex.warning,
                                tasks: urgentNotImportant,
                                quadrant: "urgent_not_important"
                            )

                            quadrantView(
                                title: "Eliminate",
                                icon: "trash",
                                color: FloColors.Hex.textTertiary,
                                tasks: neitherUrgentNorImportant,
                                quadrant: "neither"
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Quadrant

    private func quadrantView(
        title: String,
        icon: String,
        color: Color,
        tasks: [TaskItem],
        quadrant: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(FloTypography.badge)
                    .foregroundStyle(color)

                Spacer()

                Text("\(tasks.count)")
                    .font(FloTypography.badge)
                    .foregroundStyle(color.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.1))
                    .clipShape(Capsule())
            }

            Divider()
                .overlay(color.opacity(0.3))

            if tasks.isEmpty {
                Text("No tasks")
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(tasks) { task in
                            matrixTaskCard(task, color: color)
                                .draggable(task.title)
                        }
                    }
                }
                .frame(minHeight: 80, maxHeight: 200)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
        .dropDestination(for: String.self) { items, _ in
            guard let title = items.first,
                  let task = self.tasks.first(where: { $0.title == title }) else { return false }
            withAnimation(FloAnimations.springDefault) {
                applyQuadrant(quadrant, to: task)
            }
            return true
        }
    }

    private func matrixTaskCard(_ task: TaskItem, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(task.title)
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textPrimary)
                .lineLimit(1)

            Spacer()

            if let dueDate = task.dueDate {
                Text(dueDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(FloTypography.caption2)
                    .foregroundStyle(task.isOverdue ? FloColors.Hex.error : FloColors.Hex.textTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Helpers

    private func isUrgent(_ task: TaskItem) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        let calendar = Calendar.current
        let daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: dueDate)).day ?? 0
        return daysUntilDue <= 2
    }

    private func applyQuadrant(_ quadrant: String, to task: TaskItem) {
        switch quadrant {
        case "urgent_important":
            task.priority = .high
            task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now)
        case "not_urgent_important":
            task.priority = .high
            task.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now)
        case "urgent_not_important":
            task.priority = .medium
            task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now)
        case "neither":
            task.priority = .low
            task.dueDate = nil
        default:
            break
        }
        try? context.save()
    }
}
