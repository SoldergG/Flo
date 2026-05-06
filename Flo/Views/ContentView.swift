import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var selectedTab: AppTab = .planner
    @Namespace private var tabAnimation

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainContent
            } else {
                OnboardingView {
                    withAnimation(FloAnimations.springDefault) {
                        hasCompletedOnboarding = true
                    }
                }
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
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DailyPlannerView()
                    .tag(AppTab.planner)

                TasksView()
                    .tag(AppTab.tasks)

                FocusTimerView()
                    .tag(AppTab.focus)

                HabitsView()
                    .tag(AppTab.habits)

                NotesView()
                    .tag(AppTab.notes)
            }

            // Custom tab bar
            floTabBar
        }
    }

    private var floTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(FloAnimations.springSnappy) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 22))
                            .symbolEffect(.bounce, value: selectedTab == tab)

                        Text(tab.label)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 20)
        .background(
            FloColors.Hex.surface
                .shadow(color: .black.opacity(0.06), radius: 12, y: -4)
                .ignoresSafeArea()
        )
    }
    #endif

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView {
            List(AppTab.allCases, selection: $selectedTab) { tab in
                Label(tab.label, systemImage: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .foregroundStyle(selectedTab == tab ? FloColors.Hex.accent : FloColors.Hex.textSecondary)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationTitle("Flō")

            Spacer()

            // Settings button at bottom
            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }
            .padding()
        } detail: {
            switch selectedTab {
            case .planner: DailyPlannerView()
            case .tasks: TasksView()
            case .focus: FocusTimerView()
            case .habits: HabitsView()
            case .notes: NotesView()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
    #endif
}
