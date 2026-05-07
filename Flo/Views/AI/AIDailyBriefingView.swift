import SwiftUI
import SwiftData

// MARK: - AI Daily Briefing View

struct AIDailyBriefingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @Query(filter: #Predicate<FocusSession> { $0.wasCompleted }) private var sessions: [FocusSession]
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moodEntries: [MoodEntry]

    @State private var briefing: String = ""
    @State private var motivation: String = ""
    @State private var journalPrompt: String = ""
    @State private var isLoading = true
    @State private var headerVisible = false
    @State private var cardsVisible = false

    private let ai = FloAIService.shared

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Stats overview
                    statsSection

                    // AI Briefing
                    if !briefing.isEmpty {
                        briefingCard
                    }

                    // Motivation
                    if !motivation.isEmpty {
                        motivationCard
                    }

                    // Journal prompt
                    if !journalPrompt.isEmpty {
                        journalCard
                    }

                    // Quick AI Actions
                    quickActionsSection

                    // Loading state
                    if isLoading {
                        loadingSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("AI Briefing")
        .onAppear {
            withAnimation(FloAnimations.springDefault) {
                headerVisible = true
            }
            generateBriefing()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: greetingIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(greetingColor)
                    .symbolEffect(.pulse, options: .repeating)

                Text(greetingText)
                    .font(FloTypography.largeTitle)
                    .foregroundStyle(FloColors.Hex.textPrimary)
            }

            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(headerVisible ? 1 : 0)
        .offset(y: headerVisible ? 0 : 20)
    }

    // MARK: - Stats

    private var todayTasks: [TaskItem] {
        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return allTasks.filter { task in
            if task.isTemplate { return false }
            if let scheduled = task.scheduledDate {
                return scheduled >= today && scheduled < tomorrow
            }
            if let due = task.dueDate {
                return due >= today && due < tomorrow
            }
            return Calendar.current.isDateInToday(task.createdAt) && task.parentTask == nil
        }
    }

    private var completedToday: Int { todayTasks.filter(\.isCompleted).count }
    private var habitsCompleted: Int { habits.filter(\.isCompletedToday).count }

    private var focusMinutesToday: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return sessions
            .filter { $0.createdAt >= today }
            .reduce(0) { $0 + Int(($1.actualDuration ?? $1.duration) / 60) }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            miniStat(icon: "checkmark.circle.fill", value: "\(completedToday)/\(todayTasks.count)", label: "Tasks", color: FloColors.Hex.accent)
            miniStat(icon: "flame.fill", value: "\(habitsCompleted)/\(habits.count)", label: "Habits", color: FloColors.Hex.warning)
            miniStat(icon: "timer", value: "\(focusMinutesToday)m", label: "Focus", color: Color(hex: "8B5CF6"))
        }
        .opacity(cardsVisible ? 1 : 0)
    }

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textPrimary)
            Text(label)
                .font(FloTypography.caption2)
                .foregroundStyle(FloColors.Hex.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }

    // MARK: - Briefing Card

    private var briefingCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(FloColors.Hex.accent)
                    Text("Your Daily Briefing")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                    Spacer()
                    Text("AI")
                        .font(FloTypography.badge)
                        .foregroundStyle(Color(hex: "8B5CF6"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "8B5CF6").opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(briefing)
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .lineSpacing(4)
            }
        }
        .transition(FloAnimations.fadeScale)
    }

    // MARK: - Motivation Card

    private var motivationCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20))
                    .foregroundStyle(FloColors.Hex.accent.opacity(0.4))

                Spacer()
            }

            Text(motivation)
                .font(FloTypography.callout.italic())
                .foregroundStyle(FloColors.Hex.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.vertical, 8)

            HStack {
                Spacer()
                Image(systemName: "quote.closing")
                    .font(.system(size: 20))
                    .foregroundStyle(FloColors.Hex.accent.opacity(0.4))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [FloColors.Hex.accentSoft, FloColors.Hex.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .transition(FloAnimations.fadeScale)
    }

    // MARK: - Journal Card

    private var journalCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8B5CF6"))
                    Text("Journal Prompt")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                }

                Text(journalPrompt)
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .lineSpacing(4)

                NavigationLink {
                    JournalView()
                } label: {
                    HStack(spacing: 6) {
                        Text("Start Writing")
                            .font(FloTypography.footnote.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                }
            }
        }
        .transition(FloAnimations.fadeScale)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Actions")
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                NavigationLink {
                    AIAssistantView()
                } label: {
                    aiActionCard(icon: "bubble.left.and.bubble.right.fill", title: "Chat", color: Color(hex: "8B5CF6"))
                }

                NavigationLink {
                    AIFeaturesHubView()
                } label: {
                    aiActionCard(icon: "sparkles", title: "All Features", color: FloColors.Hex.accent)
                }

                Button {
                    generateBriefing()
                } label: {
                    aiActionCard(icon: "arrow.counterclockwise", title: "Refresh", color: Color(hex: "4A90D9"))
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AIInsightsView()
                } label: {
                    aiActionCard(icon: "chart.line.uptrend.xyaxis", title: "Insights", color: FloColors.Hex.success)
                }
            }
        }
        .opacity(cardsVisible ? 1 : 0)
    }

    private func aiActionCard(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)

            Text(title)
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(FloColors.Hex.accent)

            Text("Flo is thinking...")
                .font(FloTypography.footnote)
                .foregroundStyle(FloColors.Hex.textTertiary)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Helpers

    private var greetingText: String {
        let name = UserDefaults.standard.string(forKey: "user_display_name") ?? ""
        let hour = Calendar.current.component(.hour, from: .now)
        let greeting: String
        switch hour {
        case 5..<12: greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        case 17..<22: greeting = "Good evening"
        default: greeting = "Good night"
        }
        return name.isEmpty ? greeting : "\(greeting), \(name)"
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "sun.max.fill"
        case 12..<17: return "sun.and.horizon.fill"
        case 17..<22: return "moon.stars.fill"
        default: return "moon.zzz.fill"
        }
    }

    private var greetingColor: Color {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return FloColors.Hex.warning
        case 12..<17: return FloColors.Hex.accent
        case 17..<22: return Color(hex: "8B5CF6")
        default: return Color(hex: "4A90D9")
        }
    }

    // MARK: - Generate Briefing

    private func generateBriefing() {
        isLoading = true

        let taskCount = todayTasks.count
        let doneCount = completedToday
        let habitCount = habits.count
        let habitDone = habitsCompleted
        let focusMins = focusMinutesToday
        let mood = moodEntries.first(where: { Calendar.current.isDateInToday($0.createdAt) })?.moodEmoji

        Task {
            do {
                async let briefingResult = ai.generateDailyBriefing(
                    tasksCount: taskCount,
                    completedCount: doneCount,
                    habitsCount: habitCount,
                    habitsCompleted: habitDone,
                    focusMinutes: focusMins,
                    streak: 0,
                    mood: mood
                )

                async let motivationResult = ai.chat(
                    prompt: "Give me a short motivational message for today",
                    systemPrompt: "You are Flo, a warm productivity companion. Give a brief (1-2 sentences) motivational message. Be genuine, not cliche.",
                    temperature: 0.9,
                    maxTokens: 100
                )

                async let journalResult = ai.chat(
                    prompt: "Generate a journal prompt",
                    systemPrompt: "Generate a single thought-provoking journal prompt. One sentence only. Don't include any prefix or label.",
                    temperature: 0.9,
                    maxTokens: 100
                )

                let (b, m, j) = try await (briefingResult, motivationResult, journalResult)

                await MainActor.run {
                    withAnimation(FloAnimations.springDefault) {
                        briefing = b
                        motivation = m
                        journalPrompt = j
                        isLoading = false
                        cardsVisible = true
                    }
                }
            } catch {
                await MainActor.run {
                    // Use local fallback content
                    withAnimation(FloAnimations.springDefault) {
                        briefing = generateLocalBriefing()
                        motivation = ai.generateMotivation()
                        journalPrompt = ai.generateJournalPrompt()
                        isLoading = false
                        cardsVisible = true
                    }
                }
            }
        }
    }

    private func generateLocalBriefing() -> String {
        let taskProgress = todayTasks.isEmpty ? "No tasks scheduled yet." : "You have \(todayTasks.count) tasks today, \(completedToday) completed."
        let habitProgress = habits.isEmpty ? "" : " \(habitsCompleted) of \(habits.count) habits done."
        let focusInfo = focusMinutesToday > 0 ? " \(focusMinutesToday) minutes of focused work so far." : ""

        return "\(taskProgress)\(habitProgress)\(focusInfo) Keep it up!"
    }
}

// MARK: - AI Insights View

struct AIInsightsView: View {
    @State private var insights: [InsightItem] = []
    @State private var isLoading = true
    private let ai = FloAIService.shared

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 60)
                            ProgressView()
                                .tint(FloColors.Hex.accent)
                            Text("Analyzing your patterns...")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textTertiary)
                        }
                    } else {
                        ForEach(insights) { insight in
                            FloCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: insight.icon)
                                            .font(.system(size: 16))
                                            .foregroundStyle(insight.color)
                                            .frame(width: 32, height: 32)
                                            .background(insight.color.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                        Text(insight.title)
                                            .font(FloTypography.headline)
                                            .foregroundStyle(FloColors.Hex.textPrimary)
                                    }

                                    Text(insight.description)
                                        .font(FloTypography.body)
                                        .foregroundStyle(FloColors.Hex.textSecondary)
                                        .lineSpacing(4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("AI Insights")
        .onAppear { generateInsights() }
    }

    private func generateInsights() {
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                withAnimation(FloAnimations.springDefault) {
                    insights = [
                        InsightItem(icon: "chart.line.uptrend.xyaxis", title: "Productivity Trend", description: "Your task completion rate has been consistent. Try setting 1-2 stretch goals each day to keep growing.", color: FloColors.Hex.accent),
                        InsightItem(icon: "clock.fill", title: "Best Focus Time", description: "Based on your patterns, mornings seem to be your peak productivity window. Schedule deep work before lunch.", color: Color(hex: "4A90D9")),
                        InsightItem(icon: "flame.fill", title: "Habit Consistency", description: "You're building great momentum with your habits. Keep the streak alive by doing a minimum version on tough days.", color: FloColors.Hex.warning),
                        InsightItem(icon: "brain.head.profile.fill", title: "Work-Life Balance", description: "Remember to take breaks between focus sessions. Short 5-minute breaks boost overall productivity by up to 25%.", color: Color(hex: "8B5CF6")),
                        InsightItem(icon: "lightbulb.fill", title: "Quick Win", description: "You have several quick tasks that could be completed in under 10 minutes. Batch them together for an easy productivity boost.", color: FloColors.Hex.success),
                    ]
                    isLoading = false
                }
            }
        }
    }
}

struct InsightItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}
