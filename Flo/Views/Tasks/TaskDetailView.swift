import SwiftUI
import SwiftData

// MARK: - Task Detail / Edit View (FIX #42: full task editing)

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var task: TaskItem
    @Query private var projects: [Project]

    @State private var newSubtask = ""
    @FocusState private var subtaskFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Title
                        TextField("Task title", text: $task.title)
                            .font(FloTypography.title2)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                            .padding(.horizontal, 20)

                        Divider().padding(.horizontal, 20)

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes", systemImage: "note.text")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                            TextEditor(text: $task.notes)
                                .font(FloTypography.body)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                        }
                        .padding(.horizontal, 20)

                        Divider().padding(.horizontal, 20)

                        // Priority + Due Date
                        VStack(spacing: 12) {
                            // Priority (FIX #43: picker in detail)
                            HStack {
                                Label("Priority", systemImage: "flag.fill")
                                    .font(FloTypography.body)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                                Spacer()
                                Picker("Priority", selection: $task.priority) {
                                    ForEach(Priority.allCases) { p in
                                        Label(p.label, systemImage: p.icon)
                                            .tag(p)
                                    }
                                }
                                .tint(task.priority.color)
                            }
                            .padding(.horizontal, 20)

                            Divider().padding(.horizontal, 20)

                            // Due date (FIX #44: inline date picker)
                            HStack {
                                Label("Due Date", systemImage: "calendar")
                                    .font(FloTypography.body)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                                Spacer()
                                if task.dueDate != nil {
                                    Button {
                                        task.dueDate = nil
                                        try? context.save()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(FloColors.Hex.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { task.dueDate ?? Date() },
                                        set: { task.dueDate = $0 }
                                    ),
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .tint(FloColors.Hex.accent)
                            }
                            .padding(.horizontal, 20)

                            Divider().padding(.horizontal, 20)

                            // Project (FIX #45: assign/change project)
                            HStack {
                                Label("Project", systemImage: "folder.fill")
                                    .font(FloTypography.body)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                                Spacer()
                                Picker("Project", selection: $task.project) {
                                    Text("None").tag(Optional<Project>.none)
                                    ForEach(projects) { project in
                                        Text(project.name).tag(Optional(project))
                                    }
                                }
                                .tint(FloColors.Hex.textSecondary)
                            }
                            .padding(.horizontal, 20)
                        }

                        Divider().padding(.horizontal, 20)

                        // FIX #46: Subtasks section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Subtasks", systemImage: "list.bullet")
                                    .font(FloTypography.footnote)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                                Spacer()
                                if !task.subtasks.isEmpty {
                                    Text("\(task.subtasks.filter(\.isCompleted).count)/\(task.subtasks.count)")
                                        .font(FloTypography.caption)
                                        .foregroundStyle(FloColors.Hex.textTertiary)
                                }
                            }
                            .padding(.horizontal, 20)

                            ForEach(task.subtasks.filter { !$0.isTemplate }) { sub in
                                HStack(spacing: 12) {
                                    Button {
                                        sub.isCompleted.toggle()
                                        sub.completedAt = sub.isCompleted ? .now : nil
                                        try? context.save()
                                    } label: {
                                        Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(sub.isCompleted ? FloColors.Hex.success : FloColors.Hex.border)
                                            .font(.system(size: 18))
                                    }
                                    .buttonStyle(.plain)

                                    Text(sub.title)
                                        .font(FloTypography.body)
                                        .foregroundStyle(sub.isCompleted ? FloColors.Hex.textTertiary : FloColors.Hex.textPrimary)
                                        .strikethrough(sub.isCompleted)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Button {
                                        context.delete(sub)
                                        try? context.save()
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 13))
                                            .foregroundStyle(FloColors.Hex.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 20)
                            }

                            // Add subtask
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(FloColors.Hex.accent)
                                    .font(.system(size: 18))
                                TextField("Add subtask…", text: $newSubtask)
                                    .font(FloTypography.body)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                                    .focused($subtaskFocused)
                                    .onSubmit { addSubtask() }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(FloColors.Hex.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                        }

                        // FIX #47: estimated time field
                        HStack {
                            Label("Estimated", systemImage: "clock")
                                .font(FloTypography.body)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                            Spacer()
                            Stepper(
                                task.estimatedMinutes.map { "\($0) min" } ?? "Not set",
                                value: Binding(
                                    get: { task.estimatedMinutes ?? 0 },
                                    set: { task.estimatedMinutes = $0 > 0 ? $0 : nil }
                                ),
                                in: 0...480,
                                step: 15
                            )
                            .font(FloTypography.body)
                            .tint(FloColors.Hex.accent)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(task.title.isEmpty ? "New Task" : "Edit Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        task.title = task.title.trimmingCharacters(in: .whitespaces)
                        if task.title.isEmpty {
                            context.delete(task)
                        }
                        try? context.save()
                        dismiss()
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func addSubtask() {
        let title = newSubtask.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let sub = TaskItem(title: title, priority: .medium)
        sub.parentTask = task
        task.subtasks.append(sub)
        context.insert(sub)
        try? context.save()
        newSubtask = ""
        HapticManager.trigger(.light)
    }
}
