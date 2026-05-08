import SwiftUI
import SwiftData

// MARK: - Edit Habit Sheet (FIX #54: edit existing habits)

struct EditHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var habit: Habit

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedFrequency: Frequency
    @State private var hasReminder: Bool
    @State private var reminderTime: Date

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedFrequency = State(initialValue: habit.frequency)
        _hasReminder = State(initialValue: habit.reminderTime != nil)
        _reminderTime = State(initialValue: habit.reminderTime ?? {
            var c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            c.hour = 9; c.minute = 0
            return Calendar.current.date(from: c) ?? .now
        }())
    }

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
                                Circle().fill(FloColors.Hex.accentSoft).frame(width: 52, height: 52)
                                Image(systemName: selectedIcon).font(.system(size: 24)).foregroundStyle(FloColors.Hex.accent)
                            }
                            VStack(alignment: .leading) {
                                Text(name.isEmpty ? "Habit Name" : name)
                                    .font(FloTypography.headline)
                                    .foregroundStyle(name.isEmpty ? FloColors.Hex.textTertiary : FloColors.Hex.textPrimary)
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill").font(.system(size: 11)).foregroundStyle(FloColors.Hex.warning)
                                    Text("\(habit.currentStreak) day streak")
                                        .font(FloTypography.caption).foregroundStyle(FloColors.Hex.textSecondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(FloColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        FloTextField(placeholder: "Habit name", text: $name, icon: "pencil")

                        // Icon picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon").font(FloTypography.footnote).foregroundStyle(FloColors.Hex.textSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                                ForEach(icons, id: \.self) { i in
                                    Image(systemName: i).font(.system(size: 20))
                                        .foregroundStyle(selectedIcon == i ? FloColors.Hex.accent : FloColors.Hex.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == i ? FloColors.Hex.accentSoft : FloColors.Hex.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .onTapGesture { selectedIcon = i }
                                }
                            }
                        }

                        // Frequency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequency").font(FloTypography.footnote).foregroundStyle(FloColors.Hex.textSecondary)
                            HStack(spacing: 8) {
                                ForEach([Frequency.daily, .weekdays, .weekends], id: \.self) { freq in
                                    Button {
                                        withAnimation(FloAnimations.springSnappy) { selectedFrequency = freq }
                                    } label: {
                                        Text(freq.label)
                                            .font(FloTypography.footnote)
                                            .foregroundStyle(selectedFrequency == freq ? .white : FloColors.Hex.textSecondary)
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(selectedFrequency == freq ? FloColors.Hex.accent : FloColors.Hex.surface)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Reminder toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $hasReminder.animation(FloAnimations.springSnappy)) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.fill").font(.system(size: 14)).foregroundStyle(FloColors.Hex.accent)
                                    Text("Daily Reminder").font(FloTypography.footnote).foregroundStyle(FloColors.Hex.textPrimary)
                                }
                            }
                            .tint(FloColors.Hex.accent)
                            if hasReminder {
                                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .font(FloTypography.footnote).tint(FloColors.Hex.accent)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(16)
                        .background(FloColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(FloColors.Hex.accent)
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.icon = selectedIcon
        habit.frequency = selectedFrequency
        habit.reminderTime = hasReminder ? reminderTime : nil
        try? context.save()

        if hasReminder {
            CalendarService.scheduleHabitReminder(
                name: habit.name,
                time: reminderTime,
                habitId: habit.persistentModelID.hashValue.description
            )
        }

        HapticManager.trigger(.success)
        dismiss()
    }
}
