import SwiftUI
import SwiftData

@main
struct FloApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.floTheme, FloTheme.default)
        }
        .modelContainer(for: [
            TaskItem.self,
            Project.self,
            Tag.self,
            Note.self,
            NoteFolder.self,
            Habit.self,
            HabitCompletion.self,
            FocusSession.self
        ])

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
