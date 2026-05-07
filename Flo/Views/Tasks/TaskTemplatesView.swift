import SwiftUI
import SwiftData

struct TaskTemplatesView: View {
    @Environment(\.modelContext) private var context
    @State private var templates: [TaskTemplate] = TaskTemplate.presets
    @State private var showingCreateTemplate = false
    @State private var showingCreatedAlert = false
    @State private var createdTaskName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Preset templates
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("Templates", count: templates.count)

                            ForEach(templates) { template in
                                templateCard(template)
                            }
                        }

                        // Create custom template
                        FloButton("Create Custom Template", icon: "plus.rectangle.on.rectangle", style: .secondary) {
                            showingCreateTemplate = true
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Templates")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateSheet(templates: $templates)
            }
            .alert("Task Created", isPresented: $showingCreatedAlert) {
                Button("OK") {}
            } message: {
                Text("\"\(createdTaskName)\" has been added to your tasks.")
            }
        }
    }

    // MARK: - Template Card

    private func templateCard(_ template: TaskTemplate) -> some View {
        FloCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: template.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color(hex: template.colorHex))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(FloTypography.headline)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        Text("\(template.subtasks.count) subtask\(template.subtasks.count == 1 ? "" : "s")")
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: template.priority.icon)
                            .font(.system(size: 11))
                        Text(template.priority.label)
                            .font(FloTypography.caption2)
                    }
                    .foregroundStyle(template.priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(template.priority.color.opacity(0.1))
                    .clipShape(Capsule())
                }

                // Subtasks preview
                if !template.subtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(template.subtasks.prefix(4), id: \.self) { subtask in
                            HStack(spacing: 8) {
                                Circle()
                                    .strokeBorder(FloColors.Hex.border, lineWidth: 1.5)
                                    .frame(width: 16, height: 16)

                                Text(subtask)
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                            }
                        }

                        if template.subtasks.count > 4 {
                            Text("+\(template.subtasks.count - 4) more")
                                .font(FloTypography.caption2)
                                .foregroundStyle(FloColors.Hex.textTertiary)
                                .padding(.leading, 24)
                        }
                    }
                    .padding(.top, 4)
                }

                Divider()
                    .overlay(FloColors.Hex.border.opacity(0.5))

                // Action button
                Button {
                    createTaskFromTemplate(template)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Use Template")
                            .font(FloTypography.footnote)
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(FloColors.Hex.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Section Header

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
    }

    // MARK: - Create Task

    private func createTaskFromTemplate(_ template: TaskTemplate) {
        let task = TaskItem(
            title: template.name,
            notes: template.notes,
            priority: template.priority
        )
        context.insert(task)

        for subtaskTitle in template.subtasks {
            let subtask = TaskItem(title: subtaskTitle, priority: .medium)
            subtask.parentTask = task
            task.subtasks.append(subtask)
            context.insert(subtask)
        }

        try? context.save()
        createdTaskName = template.name
        showingCreatedAlert = true
    }
}

// MARK: - Task Template

struct TaskTemplate: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var colorHex: String
    var priority: Priority
    var notes: String
    var subtasks: [String]

    static let presets: [TaskTemplate] = [
        TaskTemplate(
            name: "Morning Routine",
            icon: "sun.max.fill",
            colorHex: "E5A84B",
            priority: .medium,
            notes: "Start the day with intention",
            subtasks: ["Wake up & stretch", "Drink water", "Meditate 10 min", "Review daily goals", "Healthy breakfast"]
        ),
        TaskTemplate(
            name: "Weekly Review",
            icon: "calendar.badge.checkmark",
            colorHex: "4A90D9",
            priority: .high,
            notes: "Reflect on the past week and plan ahead",
            subtasks: ["Review completed tasks", "Review pending tasks", "Update project priorities", "Plan next week's goals", "Clean up inbox"]
        ),
        TaskTemplate(
            name: "Meeting Prep",
            icon: "person.3.fill",
            colorHex: "8B5CF6",
            priority: .high,
            notes: "Prepare for an effective meeting",
            subtasks: ["Review agenda", "Prepare talking points", "Gather relevant docs", "Set up presentation", "Send reminders"]
        )
    ]
}

// MARK: - Create Template Sheet

struct CreateTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var templates: [TaskTemplate]

    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var colorHex = "D97757"
    @State private var priority: Priority = .medium
    @State private var notes = ""
    @State private var subtasks: [String] = [""]

    private let icons = [
        "star.fill", "briefcase.fill", "book.fill", "laptopcomputer",
        "house.fill", "heart.fill", "leaf.fill", "lightbulb.fill"
    ]

    private let colors = ["D97757", "B8602E", "D94F4F", "E5A84B", "5BA37C", "4A90D9", "8B5CF6", "EC4899"]

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FloTextField(placeholder: "Template name", text: $name, icon: "pencil")

                        // Icon picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            HStack(spacing: 10) {
                                ForEach(icons, id: \.self) { i in
                                    Image(systemName: i)
                                        .font(.system(size: 18))
                                        .foregroundStyle(icon == i ? Color(hex: colorHex) : FloColors.Hex.textSecondary)
                                        .frame(width: 40, height: 40)
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

                        // Color picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                            HStack(spacing: 10) {
                                ForEach(colors, id: \.self) { c in
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 32, height: 32)
                                        .overlay(Circle().strokeBorder(.white, lineWidth: colorHex == c ? 3 : 0))
                                        .scaleEffect(colorHex == c ? 1.1 : 1.0)
                                        .animation(FloAnimations.springSnappy, value: colorHex)
                                        .onTapGesture { colorHex = c }
                                }
                            }
                        }

                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            HStack(spacing: 8) {
                                ForEach(Priority.allCases) { p in
                                    FilterChip(label: p.label, isSelected: priority == p, color: p.color) {
                                        withAnimation(FloAnimations.springSnappy) { priority = p }
                                    }
                                }
                            }
                        }

                        // Subtasks
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subtasks")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            ForEach(subtasks.indices, id: \.self) { index in
                                HStack(spacing: 8) {
                                    Circle()
                                        .strokeBorder(FloColors.Hex.border, lineWidth: 1.5)
                                        .frame(width: 18, height: 18)

                                    TextField("Subtask", text: $subtasks[index])
                                        .font(FloTypography.body)
                                        .foregroundStyle(FloColors.Hex.textPrimary)

                                    if subtasks.count > 1 {
                                        Button {
                                            subtasks.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(FloColors.Hex.textTertiary)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(FloColors.Hex.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(FloColors.Hex.border, lineWidth: 1)
                                )
                            }

                            Button {
                                subtasks.append("")
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Subtask")
                                }
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Template")
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
                        let filtered = subtasks.filter { !$0.isEmpty }
                        let template = TaskTemplate(
                            name: name,
                            icon: icon,
                            colorHex: colorHex,
                            priority: priority,
                            notes: notes,
                            subtasks: filtered
                        )
                        templates.append(template)
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
