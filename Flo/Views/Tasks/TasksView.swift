import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TaskItem> { $0.parentTask == nil }, sort: \TaskItem.createdAt, order: .reverse)
    private var tasks: [TaskItem]
    @Query private var projects: [Project]
    @State private var vm = TaskViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                if tasks.isEmpty && !vm.showingAddTask {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    FloIconButton("plus.circle.fill", color: FloColors.Hex.accent) {
                        vm.showingAddTask = true
                    }
                }
            }
            .sheet(isPresented: $vm.showingAddTask) {
                AddTaskSheet(vm: vm, projects: projects)
            }
            .sheet(isPresented: $vm.showingAddProject) {
                AddProjectSheet(vm: vm)
            }
            .searchable(text: $vm.searchText, prompt: "Search tasks...")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(FloColors.Hex.border)

            Text("No tasks yet")
                .font(FloTypography.title3)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Text("Tap + to create your first task")
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)

            FloButton("Add Task", icon: "plus", style: .secondary) {
                vm.showingAddTask = true
            }
            .frame(width: 200)
        }
    }

    private var filteredTasks: [TaskItem] {
        var result = tasks
        if let project = vm.selectedProject {
            result = result.filter { $0.project?.persistentModelID == project.persistentModelID }
        }
        if !vm.searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(vm.searchText) }
        }
        return result
    }

    private var activeTasks: [TaskItem] {
        filteredTasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [TaskItem] {
        filteredTasks.filter(\.isCompleted)
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Project filter
                if !projects.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: vm.selectedProject == nil) {
                                vm.selectedProject = nil
                            }
                            ForEach(projects) { project in
                                FilterChip(
                                    label: project.name,
                                    isSelected: vm.selectedProject?.persistentModelID == project.persistentModelID,
                                    color: project.color
                                ) {
                                    vm.selectedProject = project
                                }
                            }

                            Button {
                                vm.showingAddProject = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(FloColors.Hex.textTertiary)
                                    .frame(width: 32, height: 32)
                                    .background(FloColors.Hex.surface)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)
                }

                // Active tasks
                if !activeTasks.isEmpty {
                    Section {
                        ForEach(activeTasks) { task in
                            TaskRow(task: task) {
                                vm.toggleComplete(task, context: context)
                            }
                        }
                    } header: {
                        sectionHeader("To Do", count: activeTasks.count)
                    }
                }

                // Completed tasks
                if !completedTasks.isEmpty {
                    Section {
                        ForEach(completedTasks) { task in
                            TaskRow(task: task) {
                                vm.toggleComplete(task, context: context)
                            }
                        }
                    } header: {
                        sectionHeader("Completed", count: completedTasks.count)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(FloTypography.footnote)
                .foregroundStyle(FloColors.Hex.textTertiary)
                .textCase(.uppercase)
            Text("\(count)")
                .font(FloTypography.badge)
                .foregroundStyle(FloColors.Hex.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(FloColors.Hex.border.opacity(0.5))
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    @State private var showConfetti = false

    var body: some View {
        HStack(spacing: 14) {
            Button(action: {
                if !task.isCompleted {
                    showConfetti = true
                }
                onToggle()
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? FloColors.Hex.success : task.priority.color.opacity(0.5),
                            lineWidth: 2
                        )
                        .frame(width: 26, height: 26)

                    if task.isCompleted {
                        Circle()
                            .fill(FloColors.Hex.success)
                            .frame(width: 26, height: 26)
                            .transition(.scale.combined(with: .opacity))

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale)
                    }
                }
                .animation(FloAnimations.springBouncy, value: task.isCompleted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(FloTypography.body)
                    .foregroundStyle(task.isCompleted ? FloColors.Hex.textTertiary : FloColors.Hex.textPrimary)
                    .strikethrough(task.isCompleted, color: FloColors.Hex.textTertiary)

                HStack(spacing: 8) {
                    if let project = task.project {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(project.color)
                                .frame(width: 6, height: 6)
                            Text(project.name)
                                .font(FloTypography.caption)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }
                    }

                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(dueDate, style: .date)
                                .font(FloTypography.caption)
                        }
                        .foregroundStyle(task.isOverdue ? FloColors.Hex.error : FloColors.Hex.textSecondary)
                    }

                    if !task.subtasks.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 10))
                            Text("\(task.subtasks.filter(\.isCompleted).count)/\(task.subtasks.count)")
                                .font(FloTypography.caption)
                        }
                        .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: task.priority.icon)
                .font(.system(size: 14))
                .foregroundStyle(task.priority.color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(FloColors.Hex.background)
        .confetti(isActive: $showConfetti)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = FloColors.Hex.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(FloTypography.footnote)
                .foregroundStyle(isSelected ? .white : FloColors.Hex.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : FloColors.Hex.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? color : FloColors.Hex.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Task Sheet

struct AddTaskSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: TaskViewModel
    let projects: [Project]

    @State private var title = ""
    @State private var notes = ""
    @State private var priority: Priority = .medium
    @State private var dueDate: Date?
    @State private var showDatePicker = false
    @State private var selectedProject: Project?

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FloTextField(placeholder: "Task name", text: $title, icon: "checkmark.circle")

                        FloTextEditor(placeholder: "Notes (optional)", text: $notes)

                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            HStack(spacing: 8) {
                                ForEach(Priority.allCases) { p in
                                    Button {
                                        withAnimation(FloAnimations.springSnappy) {
                                            priority = p
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: p.icon)
                                                .font(.system(size: 14))
                                            Text(p.label)
                                                .font(FloTypography.footnote)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(priority == p ? p.color.opacity(0.15) : FloColors.Hex.surface)
                                        .foregroundStyle(priority == p ? p.color : FloColors.Hex.textSecondary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(priority == p ? p.color : FloColors.Hex.border, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Due date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due date")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            Button {
                                showDatePicker.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text(dueDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "No due date")
                                    Spacer()
                                    if dueDate != nil {
                                        Button {
                                            dueDate = nil
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(FloColors.Hex.textTertiary)
                                        }
                                    }
                                }
                                .font(FloTypography.body)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                                .padding(12)
                                .background(FloColors.Hex.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(FloColors.Hex.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if showDatePicker {
                                DatePicker("", selection: Binding(
                                    get: { dueDate ?? .now },
                                    set: { dueDate = $0 }
                                ), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(FloColors.Hex.accent)
                                .transition(FloAnimations.slideUp)
                            }
                        }

                        // Project
                        if !projects.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Project")
                                    .font(FloTypography.footnote)
                                    .foregroundStyle(FloColors.Hex.textSecondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        FilterChip(label: "None", isSelected: selectedProject == nil) {
                                            selectedProject = nil
                                        }
                                        ForEach(projects) { project in
                                            FilterChip(
                                                label: project.name,
                                                isSelected: selectedProject?.persistentModelID == project.persistentModelID,
                                                color: project.color
                                            ) {
                                                selectedProject = project
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.addTask(
                            title: title,
                            notes: notes,
                            priority: priority,
                            dueDate: dueDate,
                            project: selectedProject,
                            context: context
                        )
                        dismiss()
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                    .disabled(title.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Add Project Sheet

struct AddProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: TaskViewModel

    @State private var name = ""
    @State private var colorHex = "D97757"
    @State private var icon = "folder.fill"

    private let colors = ["D97757", "B8602E", "D94F4F", "E5A84B", "5BA37C", "4A90D9", "8B5CF6", "EC4899"]
    private let icons = ["folder.fill", "briefcase.fill", "house.fill", "star.fill", "heart.fill", "book.fill", "laptopcomputer", "graduationcap.fill"]

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Preview
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: colorHex))
                            .frame(width: 48, height: 48)
                            .background(Color(hex: colorHex).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text(name.isEmpty ? "Project Name" : name)
                            .font(FloTypography.headline)
                            .foregroundStyle(name.isEmpty ? FloColors.Hex.textTertiary : FloColors.Hex.textPrimary)

                        Spacer()
                    }
                    .padding(16)
                    .background(FloColors.Hex.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)

                    FloTextField(placeholder: "Project name", text: $name, icon: "pencil")

                    // Colors
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(FloTypography.footnote)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        HStack(spacing: 10) {
                            ForEach(colors, id: \.self) { c in
                                Circle()
                                    .fill(Color(hex: c))
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: colorHex == c ? 3 : 0))
                                    .scaleEffect(colorHex == c ? 1.1 : 1.0)
                                    .animation(FloAnimations.springSnappy, value: colorHex)
                                    .onTapGesture { colorHex = c }
                            }
                        }
                    }

                    // Icons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(FloTypography.footnote)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        HStack(spacing: 10) {
                            ForEach(icons, id: \.self) { i in
                                Image(systemName: i)
                                    .font(.system(size: 20))
                                    .foregroundStyle(icon == i ? Color(hex: colorHex) : FloColors.Hex.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(icon == i ? Color(hex: colorHex).opacity(0.15) : FloColors.Hex.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(icon == i ? Color(hex: colorHex) : FloColors.Hex.border, lineWidth: 1)
                                    )
                                    .onTapGesture { icon = i }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Project")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        vm.addProject(name: name, colorHex: colorHex, icon: icon, context: context)
                        dismiss()
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
