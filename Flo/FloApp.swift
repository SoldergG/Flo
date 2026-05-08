import SwiftUI
import SwiftData

// MARK: - App Entry Point (FIX #33: theme applied here from @AppStorage)

@main
struct FloApp: App {
    let container: ModelContainer

    // FIX #34: read theme + accent from persistence
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("accentColorHex") private var accentColorHex = "D97757"

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

    private var preferredColorScheme: ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.floTheme, FloTheme.default)
                // FIX #35: actually applies the user's chosen theme
                .preferredColorScheme(preferredColorScheme)
                // FIX #36: tint all native controls with chosen accent
                .tint(Color(hex: accentColorHex))
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        .modelContainer(container)
        .defaultSize(width: 500, height: 600) // FIX #37: reasonable macOS settings window size
        #endif
    }
}
