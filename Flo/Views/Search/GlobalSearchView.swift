import SwiftUI
import SwiftData

// MARK: - Global Search

struct GlobalSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var tasks: [TaskItem]
    @Query private var notes: [Note]
    @Query private var habits: [Habit]

    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @FocusState private var isSearchFocused: Bool

    enum SearchFilter: String, CaseIterable {
        case all, tasks, notes, habits
        var label: String { rawValue.capitalized }
        var icon: String {
            switch self {
            case .all: "magnifyingglass"
            case .tasks: "checkmark.circle"
            case .notes: "note.text"
            case .habits: "flame"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Filter pills
                filterPills

                // Results
                if searchText.isEmpty {
                    recentSearchesView
                } else if filteredResults.isEmpty {
                    emptyResultsView
                } else {
                    resultsList
                }
            }
            .background(FloColors.Hex.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FloColors.Hex.accent)
                }
            }
            .onAppear { isSearchFocused = true }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FloColors.Hex.textTertiary)

            TextField("Search tasks, notes, habits...", text: $searchText)
                .font(FloTypography.body)
                .focused($isSearchFocused)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
            }
        }
        .padding(12)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(FloAnimations.springSnappy) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 11))
                            Text(filter.label)
                                .font(FloTypography.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedFilter == filter ? FloColors.Hex.accent : FloColors.Hex.surface)
                        .foregroundStyle(selectedFilter == filter ? .white : FloColors.Hex.textSecondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Recent Searches

    private var recentSearchesView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(FloColors.Hex.textTertiary.opacity(0.5))
            Text("Search across everything")
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textSecondary)
            Text("Find tasks, notes, and habits instantly")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(FloColors.Hex.textTertiary.opacity(0.5))
            Text("No results for \"\(searchText)\"")
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textSecondary)
            Text("Try different keywords or filters")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textTertiary)
            Spacer()
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            if !matchingTasks.isEmpty && (selectedFilter == .all || selectedFilter == .tasks) {
                Section {
                    ForEach(matchingTasks.prefix(10)) { task in
                        TaskSearchRow(task: task, searchText: searchText)
                    }
                } header: {
                    Label("Tasks (\(matchingTasks.count))", systemImage: "checkmark.circle")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            }

            if !matchingNotes.isEmpty && (selectedFilter == .all || selectedFilter == .notes) {
                Section {
                    ForEach(matchingNotes.prefix(10)) { note in
                        NoteSearchRow(note: note, searchText: searchText)
                    }
                } header: {
                    Label("Notes (\(matchingNotes.count))", systemImage: "note.text")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            }

            if !matchingHabits.isEmpty && (selectedFilter == .all || selectedFilter == .habits) {
                Section {
                    ForEach(matchingHabits.prefix(10)) { habit in
                        HabitSearchRow(habit: habit)
                    }
                } header: {
                    Label("Habits (\(matchingHabits.count))", systemImage: "flame")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Filtering Logic

    private var filteredResults: [Any] {
        var results: [Any] = []
        if selectedFilter == .all || selectedFilter == .tasks { results.append(contentsOf: matchingTasks) }
        if selectedFilter == .all || selectedFilter == .notes { results.append(contentsOf: matchingNotes) }
        if selectedFilter == .all || selectedFilter == .habits { results.append(contentsOf: matchingHabits) }
        return results
    }

    private var matchingTasks: [TaskItem] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return tasks.filter {
            $0.title.lowercased().contains(query) ||
            $0.notes.lowercased().contains(query)
        }
    }

    private var matchingNotes: [Note] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
    }

    private var matchingHabits: [Habit] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return habits.filter { $0.name.lowercased().contains(query) }
    }
}

// MARK: - Search Result Rows

private struct TaskSearchRow: View {
    let task: TaskItem
    let searchText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isCompleted ? FloColors.Hex.success : FloColors.Hex.textTertiary)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(FloTypography.subheadline)
                    .foregroundStyle(task.isCompleted ? FloColors.Hex.textTertiary : FloColors.Hex.textPrimary)
                    .strikethrough(task.isCompleted)

                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(FloTypography.caption)
                        .foregroundStyle(task.isOverdue ? FloColors.Hex.error : FloColors.Hex.textTertiary)
                }
            }

            Spacer()

            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 2)
    }
}

private struct NoteSearchRow: View {
    let note: Note
    let searchText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: note.isPinned ? "pin.fill" : "note.text")
                .foregroundStyle(note.isPinned ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 3) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(FloTypography.subheadline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text(note.preview)
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(note.updatedAt, style: .relative)
                .font(FloTypography.caption2)
                .foregroundStyle(FloColors.Hex.textTertiary)
        }
        .padding(.vertical, 2)
    }
}

private struct HabitSearchRow: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .foregroundStyle(Color(hex: habit.colorHex))
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(FloTypography.subheadline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("\(habit.currentStreak) day streak")
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }

            Spacer()

            Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(habit.isCompletedToday ? FloColors.Hex.success : FloColors.Hex.textTertiary)
        }
        .padding(.vertical, 2)
    }
}
