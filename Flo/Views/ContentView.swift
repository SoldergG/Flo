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
    private var macOSLayout: some View {
        NavigationSplitView {
            // Sidebar: keep everything inside the List to avoid constraint loops
            List(selection: $selectedTab) {
                Section {
                    ForEach(AppTab.allCases) { tab in
                        Label(tab.label, systemImage: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .foregroundStyle(selectedTab == tab ? FloColors.Hex.accent : FloColors.Hex.textSecondary)
                            .tag(tab)
                    }
                }

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Flō")
        } detail: {
            switch selectedTab {
            case .planner: DailyPlannerView()
            case .tasks: TasksHubView()
            case .focus: FocusHubView()
            case .habits: HabitsHubView()
            case .notes: NotesView()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showSearch) {
            GlobalSearchView()
        }
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
