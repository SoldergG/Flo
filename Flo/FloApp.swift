import SwiftUI
import SwiftData

@main
struct FloApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                TaskItem.self,
                Project.self,
                Tag.self,
                Note.self,
                NoteFolder.self,
                Habit.self,
                HabitCompletion.self,
                FocusSession.self,
                FocusPreset.self,
                MoodEntry.self,
                JournalEntry.self,
                DailyScore.self,
                SmartList.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.floTheme, FloTheme.default)
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        .modelContainer(container)
        #endif
    }
}
