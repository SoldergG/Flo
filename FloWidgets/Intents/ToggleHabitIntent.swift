import AppIntents
import WidgetKit

// MARK: - Habit Entity for AppIntents

struct HabitEntity: AppEntity {
    nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    nonisolated(unsafe) static var defaultQuery = HabitEntityQuery()

    var id: String
    var name: String
    var icon: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        let habits = WidgetDataProvider.loadHabits()
        return habits
            .filter { identifiers.contains($0.id) }
            .map { HabitEntity(id: $0.id, name: $0.name, icon: $0.icon) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        let habits = WidgetDataProvider.loadHabits()
        return habits.map { HabitEntity(id: $0.id, name: $0.name, icon: $0.icon) }
    }

    func defaultResult() async -> HabitEntity? {
        let habits = WidgetDataProvider.loadHabits()
        guard let first = habits.first else { return nil }
        return HabitEntity(id: first.id, name: first.name, icon: first.icon)
    }
}

// MARK: - Toggle Habit Intent

struct ToggleHabitIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Toggle Habit"
    nonisolated(unsafe) static var description: IntentDescription = "Mark a habit as completed or uncompleted for today."

    @Parameter(title: "Habit")
    var habit: HabitEntity

    init() {}

    init(habit: HabitEntity) {
        self.habit = habit
    }

    init(habitId: String, name: String, icon: String) {
        self.habit = HabitEntity(id: habitId, name: name, icon: icon)
    }

    func perform() async throws -> some IntentResult {
        WidgetDataProvider.toggleHabit(id: habit.id)
        return .result()
    }
}
