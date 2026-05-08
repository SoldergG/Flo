import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .planner
    @State private var authManager = SupabaseManager.shared
    @State private var store = StoreKitManager.shared
    @State private var showAuth = false
    @State private var showSearch = false
    @Namespace private var tabAnimation

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(FloAnimations.springDefault) {
                        hasCompletedOnboarding = true
                    }
                }
            } else {
                mainContent
            }
        }
        .onAppear {
            Task {
                await authManager.observeAuthChanges()
                await store.updatePurchasedProducts()
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        #if os(iOS)
        iOSLayout
        #elseif os(macOS)
        macOSLayout
        #endif
    }

    // MARK: - iOS Layout

    #if os(iOS)
    private var iOSLayout: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "calendar", value: .planner) {
                DailyPlannerView()
            }
            Tab("Tasks", systemImage: "checkmark.circle", value: .tasks) {
                TasksHubView()
            }
            Tab("Focus", systemImage: "timer", value: .focus) {
                FocusHubView()
            }
            Tab("Habits", systemImage: "flame", value: .habits) {
                HabitsHubView()
            }
            Tab("Notes", systemImage: "note.text", value: .notes) {
                NotesView()
            }
        }
        .tint(FloColors.Hex.accent)
        .sheet(isPresented: $showSearch) {
            GlobalSearchView()
        }
    }
    #endif

    // MARK: - macOS Layout

    #if os(macOS)
    @State private var macDestination: MacDestination = .planner

    private var macOSLayout: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            macSidebar
        } detail: {
            macDetail
        }
        .frame(minWidth: 980, minHeight: 640)
        .sheet(isPresented: $showSearch) {
            GlobalSearchView()
        }
    }

    // MARK: - macOS Sidebar (full feature parity with iOS)

    private var macSidebar: some View {
        List(selection: $macDestination) {

            // MARK: Today
            Section("Today") {
                macItem(.planner,     "Daily Planner",       "calendar")
                macItem(.productivity, "Productivity Score",  "chart.line.uptrend.xyaxis")
                macItem(.weekly,       "Weekly Planner",      "calendar.badge.clock")
                macItem(.morning,      "Morning Check-In",    "sun.max.fill")
                macItem(.evening,      "Evening Review",      "moon.stars.fill")
                macItem(.journal,      "Journal",             "book.closed.fill")
                macItem(.aiBriefing,   "AI Briefing",         "sparkles")
            }

            // MARK: Tasks
            Section("Tasks") {
                macItem(.tasks,        "All Tasks",           "checkmark.circle")
                macItem(.kanban,       "Kanban Board",        "rectangle.split.3x1")
                macItem(.matrix,       "Priority Matrix",     "square.grid.2x2")
                macItem(.taskCal,      "Calendar",            "calendar")
                macItem(.smartLists,   "Smart Lists",         "sparkles")
                macItem(.taskStats,    "Statistics",          "chart.bar.fill")
                macItem(.templates,    "Templates",           "doc.on.doc")
            }

            // MARK: Focus
            Section("Focus") {
                macItem(.focus,        "Timer",               "timer")
                macItem(.ambient,      "Ambient Sounds",      "waveform")
                macItem(.presets,      "Presets",             "slider.horizontal.3")
                macItem(.focusHist,    "History",             "clock.arrow.circlepath")
                macItem(.focusReport,  "Report",              "chart.bar")
            }

            // MARK: Habits
            Section("Habits") {
                macItem(.habits,       "All Habits",          "flame")
                macItem(.habitCats,    "Categories",          "square.grid.2x2")
            }

            // MARK: Notes
            Section("Notes") {
                macItem(.notes,        "Notes",               "note.text")
            }

            // MARK: AI
            Section("AI") {
                macItem(.aiChat,       "AI Assistant",        "bubble.left.and.bubble.right.fill")
                macItem(.aiFeatures,   "All Features",        "sparkles")
                macItem(.aiSettings,   "AI Settings",         "key.fill")
            }

            // MARK: Account
            Section("Account") {
                macItem(.profile,      "Profile & Sync",      "person.circle")
                macItem(.settings,     "Settings",            "gearshape")
                macItem(.stats,        "Advanced Stats",      "chart.xyaxis.line")
                macItem(.export,       "Export Data",         "square.and.arrow.up")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Flō")
    }

    private func macItem(_ dest: MacDestination, _ label: String, _ icon: String) -> some View {
        Label(label, systemImage: macDestination == dest ? selectedIconFor(dest, icon) : icon)
            .tag(dest)
    }

    private func selectedIconFor(_ dest: MacDestination, _ icon: String) -> String {
        // Return filled variant for selected state
        let filled = icon + ".fill"
        return icon
    }

    // MARK: - macOS Detail (all views, no nested NavigationStack)

    @ViewBuilder
    private var macDetail: some View {
        switch macDestination {
        // Today
        case .planner:      DailyPlannerView()
        case .productivity: ProductivityScoreView()
        case .weekly:       WeeklyPlannerView()
        case .morning:      MorningCheckInView()
        case .evening:      EveningReviewView()
        case .journal:      JournalView()
        case .aiBriefing:   AIDailyBriefingView()

        // Tasks
        case .tasks:        TasksView()
        case .kanban:       KanbanBoardView()
        case .matrix:       EisenhowerMatrixView()
        case .taskCal:      TaskCalendarView()
        case .smartLists:   SmartListsView()
        case .taskStats:    TaskStatsView()
        case .templates:    TaskTemplatesView()

        // Focus
        case .focus:        FocusTimerView()
        case .ambient:      AmbientSoundsView()
        case .presets:      FocusPresetsView()
        case .focusHist:    FocusHistoryView()
        case .focusReport:  FocusReportView()

        // Habits
        case .habits:       HabitsView()
        case .habitCats:    HabitCategoriesView()

        // Notes
        case .notes:        NotesView()

        // AI
        case .aiChat:       AIAssistantView()
        case .aiFeatures:   AIFeaturesHubView()
        case .aiSettings:   AISettingsView()

        // Account
        case .profile:      ProfileView()
        case .settings:     SettingsView()
        case .stats:        AdvancedStatsView()
        case .export:       DataExportView()
        }
    }

    // MARK: - Mac Destination Enum

    enum MacDestination: Hashable {
        // Today
        case planner, productivity, weekly, morning, evening, journal, aiBriefing
        // Tasks
        case tasks, kanban, matrix, taskCal, smartLists, taskStats, templates
        // Focus
        case focus, ambient, presets, focusHist, focusReport
        // Habits
        case habits, habitCats
        // Notes
        case notes
        // AI
        case aiChat, aiFeatures, aiSettings
        // Account
        case profile, settings, stats, export
    }
    #endif
}

// MARK: - Tasks Hub (combines all task views)

struct TasksHubView: View {
    @State private var viewMode: TaskViewMode = .list

    enum TaskViewMode: String, CaseIterable {
        case list, kanban, matrix, calendar, smart
        var label: String {
            switch self {
            case .list: "List"
            case .kanban: "Kanban"
            case .matrix: "Matrix"
            case .calendar: "Calendar"
            case .smart: "Smart"
            }
        }
        var icon: String {
            switch self {
            case .list: "list.bullet"
            case .kanban: "rectangle.split.3x1"
            case .matrix: "square.grid.2x2"
            case .calendar: "calendar"
            case .smart: "sparkles"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(TaskViewMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(FloAnimations.springSnappy) {
                                    viewMode = mode
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 12))
                                    Text(mode.label)
                                        .font(FloTypography.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(viewMode == mode ? FloColors.Hex.accent : FloColors.Hex.surface)
                                .foregroundStyle(viewMode == mode ? .white : FloColors.Hex.textSecondary)
                                .clipShape(Capsule())
                                .overlay(Capsule().strokeBorder(viewMode == mode ? FloColors.Hex.accent : FloColors.Hex.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink {
                            TaskStatsView()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 12))
                                Text("Stats")
                                    .font(FloTypography.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(FloColors.Hex.surface)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(FloColors.Hex.border, lineWidth: 1))
                        }

                        NavigationLink {
                            TaskTemplatesView()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12))
                                Text("Templates")
                                    .font(FloTypography.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(FloColors.Hex.surface)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(FloColors.Hex.border, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(FloColors.Hex.background)

                // Active view
                Group {
                    switch viewMode {
                    case .list: TasksView()
                    case .kanban: KanbanBoardView()
                    case .matrix: EisenhowerMatrixView()
                    case .calendar: TaskCalendarView()
                    case .smart: SmartListsView()
                    }
                }
            }
            .background(FloColors.Hex.background)
        }
    }
}

// MARK: - Focus Hub

struct FocusHubView: View {
    var body: some View {
        NavigationStack {
            FocusTimerView()
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        NavigationLink {
                            FocusPresetsView()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }

                        NavigationLink {
                            FocusHistoryView()
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }

                        NavigationLink {
                            FocusReportView()
                        } label: {
                            Image(systemName: "chart.bar")
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }

                        NavigationLink {
                            AmbientSoundsView()
                        } label: {
                            Image(systemName: "waveform")
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }
                    }
                }
        }
    }
}

// MARK: - Habits Hub

struct HabitsHubView: View {
    @State private var showStats = false
    @State private var showCategories = false

    var body: some View {
        NavigationStack {
            HabitsView()
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        NavigationLink {
                            HabitCategoriesView()
                        } label: {
                            Image(systemName: "square.grid.2x2")
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }
                    }
                }
        }
    }
}
