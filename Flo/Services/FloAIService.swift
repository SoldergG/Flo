import Foundation
import NaturalLanguage
import SwiftUI

// MARK: - AI Service (Groq Free Tier + Local Fallback)

@MainActor @Observable
final class FloAIService {
    static let shared = FloAIService()

    // MARK: - State

    var isProcessing = false
    var lastError: String?

    // Groq free API (generous free tier, fast inference)
    var activeAPIKey: String {
        let key = UserDefaults.standard.string(forKey: "groq_api_key") ?? ""
        return key.isEmpty ? "gsk_placeholder" : key
    }

    var hasAPIKey: Bool {
        let key = UserDefaults.standard.string(forKey: "groq_api_key") ?? ""
        return !key.isEmpty && key != "gsk_placeholder"
    }
    private let groqBaseURL = "https://api.groq.com/openai/v1/chat/completions"
    private let groqModel = "llama-3.3-70b-versatile"

    // MARK: - Chat History

    private var conversationHistory: [[String: String]] = []

    // MARK: - Core AI Request

    func chat(
        prompt: String,
        systemPrompt: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int = 1024
    ) async throws -> String {
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        // Try Groq API first
        if activeAPIKey != "gsk_placeholder" {
            do {
                return try await groqRequest(
                    prompt: prompt,
                    systemPrompt: systemPrompt,
                    temperature: temperature,
                    maxTokens: maxTokens
                )
            } catch {
                // Fall back to local
                print("Groq API failed: \(error). Using local fallback.")
            }
        }

        // Local fallback using heuristics
        return localFallback(prompt: prompt, systemPrompt: systemPrompt)
    }

    // MARK: - Groq API Request

    private func groqRequest(
        prompt: String,
        systemPrompt: String?,
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        var messages: [[String: String]] = []

        if let systemPrompt {
            messages.append(["role": "system", "content": systemPrompt])
        }

        // Add conversation history (last 10 messages)
        let recentHistory = conversationHistory.suffix(10)
        messages.append(contentsOf: recentHistory)
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": groqModel,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": maxTokens,
            "stream": false
        ]

        var request = URLRequest(url: URL(string: groqBaseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(activeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FloAIError.apiError("API returned error")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String ?? ""

        // Update conversation history
        conversationHistory.append(["role": "user", "content": prompt])
        conversationHistory.append(["role": "assistant", "content": content])

        return content
    }

    // MARK: - Local Fallback (Smart Heuristics + NaturalLanguage)

    private func localFallback(prompt: String, systemPrompt: String?) -> String {
        let lowered = prompt.lowercased()

        // Task-related queries
        if lowered.contains("task") || lowered.contains("todo") || lowered.contains("tarefa") {
            return generateTaskAdvice(prompt: lowered)
        }

        // Habit-related
        if lowered.contains("habit") || lowered.contains("streak") || lowered.contains("habito") {
            return generateHabitAdvice(prompt: lowered)
        }

        // Focus-related
        if lowered.contains("focus") || lowered.contains("pomodoro") || lowered.contains("concentr") {
            return generateFocusAdvice(prompt: lowered)
        }

        // Mood/wellness
        if lowered.contains("mood") || lowered.contains("feeling") || lowered.contains("stress") || lowered.contains("humor") {
            return generateMoodAdvice(prompt: lowered)
        }

        // Motivation
        if lowered.contains("motivat") || lowered.contains("inspir") || lowered.contains("quote") {
            return generateMotivation()
        }

        // Planning
        if lowered.contains("plan") || lowered.contains("schedule") || lowered.contains("organize") {
            return generatePlanningAdvice(prompt: lowered)
        }

        // Journal
        if lowered.contains("journal") || lowered.contains("reflect") || lowered.contains("write") {
            return generateJournalPrompt()
        }

        // Default productivity tip
        return generateProductivityTip()
    }

    // MARK: - Smart Generators

    private func generateTaskAdvice(prompt: String) -> String {
        let tips = [
            "Break large tasks into smaller, actionable steps. Each subtask should take 15-30 minutes to complete.",
            "Try the 2-minute rule: if a task takes less than 2 minutes, do it immediately instead of adding it to your list.",
            "Use the Eisenhower Matrix to prioritize: focus on Urgent+Important tasks first, schedule Important ones, delegate Urgent ones.",
            "Batch similar tasks together. Processing emails, making calls, or running errands in groups is more efficient.",
            "Set a hard deadline for every task, even if it's self-imposed. Parkinson's Law says work expands to fill available time.",
            "Review your task list every morning. Move anything not critical to tomorrow and focus on your top 3.",
            "Consider your energy levels when scheduling. Do deep work in the morning and routine tasks in the afternoon.",
            "If you've been procrastinating on a task, make the first step ridiculously small: just open the document, write one sentence."
        ]
        return tips.randomElement()!
    }

    private func generateHabitAdvice(prompt: String) -> String {
        let tips = [
            "Stack new habits onto existing ones. After you brush your teeth, do 5 pushups. The trigger makes it automatic.",
            "Don't break the chain! Your streak is powerful motivation. Even on bad days, do a minimal version of your habit.",
            "Track your habits visually. Seeing a row of completed checkmarks releases dopamine and reinforces the behavior.",
            "Start with tiny habits. Want to meditate 20 minutes? Start with 2 minutes for 2 weeks, then gradually increase.",
            "Environment design matters more than willpower. Put your running shoes by the door, keep your phone in another room.",
            "Use 'habit pairing': combine a habit you need to do with something you enjoy. Audiobook + walking = win.",
            "Focus on systems, not goals. 'I run every morning' is more sustainable than 'I want to run a marathon'.",
            "If you miss a day, never miss two. One miss is an accident, two starts a new pattern."
        ]
        return tips.randomElement()!
    }

    private func generateFocusAdvice(prompt: String) -> String {
        let tips = [
            "Try the 25/5 Pomodoro technique: 25 minutes of focused work, then a 5-minute break. After 4 rounds, take a 15-minute break.",
            "Put your phone in another room while working. Even having it face-down on your desk reduces cognitive performance.",
            "Use ambient sounds like rain or lo-fi music to create a focus bubble. Silence isn't always the best environment.",
            "Close all unnecessary tabs and apps before starting. Each one is a potential distraction pulling at your attention.",
            "Set a clear intention before each focus session: 'I will complete X in the next 25 minutes.'",
            "Take real breaks. Step away from the screen, stretch, get water. Your brain consolidates learning during rest.",
            "Match your task to the right focus duration: 15 min for quick tasks, 50 min for creative work, 90 min for deep work.",
            "If you're struggling to start, commit to just 5 minutes. The hardest part is beginning; momentum takes over."
        ]
        return tips.randomElement()!
    }

    private func generateMoodAdvice(prompt: String) -> String {
        let tips = [
            "Your mood affects your productivity more than your schedule. Take 5 minutes to check in with yourself before planning.",
            "Low energy? Start with an easy win. Completing something small builds momentum for bigger challenges.",
            "Feeling overwhelmed? Write down everything on your mind, then circle the one thing you can do right now.",
            "Movement is the fastest mood booster. A 10-minute walk can increase energy and creativity for 2 hours.",
            "Practice the 4-7-8 breathing technique: breathe in for 4 seconds, hold for 7, exhale for 8. Instant calm.",
            "Gratitude journaling for 3 minutes can measurably improve your mood. Write 3 things you're thankful for.",
            "If you're stressed, try the 'brain dump': write everything down without organizing. Just getting it out helps.",
            "Remember: productivity isn't linear. Some days are for deep work, others are for recovery. Both are valuable."
        ]
        return tips.randomElement()!
    }

    func generateMotivation() -> String {
        let quotes = [
            "The secret of getting ahead is getting started. Your future self will thank you for starting today.",
            "Progress, not perfection. Every small step forward counts more than you think.",
            "You don't have to see the whole staircase. Just take the first step.",
            "Discipline is choosing between what you want now and what you want most.",
            "The best time to plant a tree was 20 years ago. The second best time is now.",
            "Small daily improvements over time lead to stunning results.",
            "Don't count the days. Make the days count.",
            "Focus on being productive instead of busy. It's not about how many tasks you complete, but which ones.",
            "Your habits are the compound interest of self-improvement. Getting 1% better every day counts for a lot.",
            "The only way to do great work is to love what you do. Start with what you have, where you are."
        ]
        return quotes.randomElement()!
    }

    private func generatePlanningAdvice(prompt: String) -> String {
        let tips = [
            "Use time blocking: assign specific hours to specific tasks. It prevents decision fatigue throughout the day.",
            "Plan tomorrow tonight. Spending 10 minutes planning before bed reduces morning anxiety and gives direction.",
            "The 1-3-5 rule: plan to accomplish 1 big thing, 3 medium things, and 5 small things each day.",
            "Leave buffer time between tasks. Back-to-back scheduling causes stress and doesn't account for real life.",
            "Weekly reviews are essential. Every Sunday, review what worked, what didn't, and adjust your approach.",
            "Use your calendar for fixed commitments and your task list for flexible work. Don't mix them.",
            "Plan your week around your energy patterns. Most people have peak focus in the morning.",
            "Always have a 'next action' defined. Vague tasks like 'work on project' create resistance."
        ]
        return tips.randomElement()!
    }

    func generateJournalPrompt() -> String {
        let prompts = [
            "What was the most meaningful moment of your day? Why did it stand out?",
            "If you could give your morning self one piece of advice, what would it be?",
            "What's one thing you learned today that you didn't know yesterday?",
            "Describe a challenge you faced today. How did you handle it? What would you do differently?",
            "What are three things you're grateful for right now?",
            "What's taking up the most mental space right now? Can you break it into smaller pieces?",
            "If tomorrow were a perfect productive day, what would it look like?",
            "What habit or routine is serving you well? What one thing could you improve?",
            "Who made a positive impact on your day? How can you pass that forward?",
            "Rate your day 1-10. What would have made it a 10?"
        ]
        return prompts.randomElement()!
    }

    private func generateProductivityTip() -> String {
        let tips = [
            "Try the 'two-minute rule': if something takes less than two minutes, do it right now.",
            "Batch your communication. Check email/messages at set times instead of constantly.",
            "The most productive people protect their mornings for deep, creative work.",
            "Use a 'parking lot' note for ideas that pop up during focus time. Capture them, don't chase them.",
            "Review your week every Sunday. It takes 15 minutes but saves hours of aimless work.",
            "Say no to good things so you can say yes to great things. Guard your time ruthlessly.",
            "Automate the mundane. Templates, shortcuts, and routines free your mind for real thinking.",
            "Take breaks seriously. Your brain needs rest to perform at its peak."
        ]
        return tips.randomElement()!
    }

    // MARK: - NaturalLanguage Sentiment Analysis

    func analyzeSentiment(text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(sentiment?.rawValue ?? "0") ?? 0
    }

    // MARK: - Text Classification

    func classifyText(_ text: String) -> String {
        let lowered = text.lowercased()

        if lowered.contains("urgent") || lowered.contains("asap") || lowered.contains("deadline") {
            return "urgent"
        } else if lowered.contains("meeting") || lowered.contains("call") || lowered.contains("discuss") {
            return "communication"
        } else if lowered.contains("review") || lowered.contains("check") || lowered.contains("read") {
            return "review"
        } else if lowered.contains("create") || lowered.contains("build") || lowered.contains("design") || lowered.contains("write") {
            return "creative"
        } else if lowered.contains("fix") || lowered.contains("bug") || lowered.contains("error") || lowered.contains("issue") {
            return "maintenance"
        }
        return "general"
    }

    // MARK: - Smart Priority Suggestion

    func suggestPriority(title: String, dueDate: Date?) -> Priority {
        let urgentKeywords = ["urgent", "asap", "critical", "emergency", "deadline", "today", "now"]
        let lowTitle = title.lowercased()

        if urgentKeywords.contains(where: { lowTitle.contains($0) }) {
            return .high
        }

        if let due = dueDate {
            let hoursUntilDue = due.timeIntervalSince(.now) / 3600
            if hoursUntilDue < 24 { return .high }
            if hoursUntilDue < 72 { return .medium }
        }

        return .low
    }

    // MARK: - Smart Task Breakdown

    func suggestSubtasks(for taskTitle: String) async throws -> [String] {
        let systemPrompt = """
        You are a productivity assistant for the Flo app. Break down the given task into 3-5 actionable subtasks.
        Return ONLY a JSON array of strings. Example: ["Research options", "Create draft", "Get feedback"]
        Keep each subtask concise (under 10 words). Be specific and actionable.
        """

        let response = try await chat(
            prompt: "Break down this task: \(taskTitle)",
            systemPrompt: systemPrompt,
            temperature: 0.5,
            maxTokens: 256
        )

        // Try to parse JSON array
        if let data = response.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return array
        }

        // Fallback: split by newlines
        return response.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { String($0) }
    }

    // MARK: - Daily Briefing Generator

    func generateDailyBriefing(
        tasksCount: Int,
        completedCount: Int,
        habitsCount: Int,
        habitsCompleted: Int,
        focusMinutes: Int,
        streak: Int,
        mood: String?
    ) async throws -> String {
        let systemPrompt = """
        You are Flo, a calm and encouraging productivity companion. Generate a brief, personalized daily briefing.
        Be warm but concise (3-4 sentences max). Use the data provided to give specific, actionable advice.
        Don't use bullet points. Write in a conversational, friendly tone. Address the user directly.
        """

        var context = "Today's stats: \(completedCount)/\(tasksCount) tasks done, \(habitsCompleted)/\(habitsCount) habits completed, \(focusMinutes) focus minutes"
        if streak > 0 { context += ", \(streak)-day streak" }
        if let mood { context += ", mood: \(mood)" }

        return try await chat(
            prompt: "Generate my daily briefing. \(context)",
            systemPrompt: systemPrompt,
            temperature: 0.8,
            maxTokens: 200
        )
    }

    // MARK: - Smart Scheduling

    func suggestOptimalTime(for taskTitle: String, duration: Int) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        let type = classifyText(taskTitle)

        switch type {
        case "creative":
            if hour < 12 { return "Now is great! Morning is optimal for creative work." }
            return "Try scheduling this for tomorrow morning (9-11 AM) when creativity peaks."
        case "communication":
            if hour >= 10 && hour <= 16 { return "Good time for this. People are most responsive mid-day." }
            return "Schedule between 10 AM and 4 PM for best response rates."
        case "review":
            if hour >= 14 { return "Afternoon is perfect for review tasks. Your analytical mind is warmed up." }
            return "Consider doing this after lunch when your mind shifts to analytical mode."
        case "maintenance":
            return "Batch this with similar tasks. Low-energy afternoon slots work well for maintenance."
        default:
            if duration > 45 { return "Block \(duration) minutes of uninterrupted time. Morning works best for deep work." }
            return "This can fit in any open slot. Consider batching it with similar tasks."
        }
    }

    // MARK: - Weekly Insights

    func generateWeeklyInsights(
        taskCompletion: Double,
        habitConsistency: Double,
        focusHours: Double,
        topProject: String?
    ) async throws -> String {
        let systemPrompt = """
        You are Flo, a productivity coach. Analyze the weekly data and provide 3 actionable insights.
        Be encouraging but honest. If things are going well, celebrate. If not, suggest specific improvements.
        Keep it under 150 words. Use a warm, supportive tone.
        """

        var prompt = "Weekly review: \(Int(taskCompletion * 100))% task completion, \(Int(habitConsistency * 100))% habit consistency, \(String(format: "%.1f", focusHours)) focus hours"
        if let topProject { prompt += ", most active project: \(topProject)" }

        return try await chat(
            prompt: prompt,
            systemPrompt: systemPrompt,
            temperature: 0.7,
            maxTokens: 300
        )
    }

    // MARK: - Conversation Management

    func clearConversation() {
        conversationHistory = []
    }

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "groq_api_key")
    }

    func getAPIKey() -> String {
        UserDefaults.standard.string(forKey: "groq_api_key") ?? "gsk_placeholder"
    }
}

// MARK: - AI Error

enum FloAIError: LocalizedError {
    case apiError(String)
    case noResponse
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return "AI Error: \(msg)"
        case .noResponse: return "No response from AI"
        case .invalidJSON: return "Invalid response format"
        }
    }
}

// MARK: - AI Feature Definition

struct AIFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let category: AIFeatureCategory
    let color: Color
    let isAvailableOffline: Bool

    enum AIFeatureCategory: String, CaseIterable {
        case tasks = "Tasks"
        case habits = "Habits"
        case focus = "Focus"
        case wellness = "Wellness"
        case planning = "Planning"
        case insights = "Insights"
        case writing = "Writing"
        case coaching = "Coaching"

        var icon: String {
            switch self {
            case .tasks: return "checkmark.circle.fill"
            case .habits: return "flame.fill"
            case .focus: return "timer"
            case .wellness: return "heart.fill"
            case .planning: return "calendar"
            case .insights: return "chart.line.uptrend.xyaxis"
            case .writing: return "pencil.and.outline"
            case .coaching: return "person.fill.questionmark"
            }
        }
    }
}

// MARK: - All 50 AI Features

extension FloAIService {
    static let allFeatures: [AIFeature] = [
        // TASKS (1-10)
        AIFeature(icon: "sparkles", title: "Smart Task Breakdown", subtitle: "Auto-split big tasks into subtasks", category: .tasks, color: FloColors.Hex.accent, isAvailableOffline: false),
        AIFeature(icon: "arrow.up.arrow.down", title: "Priority Auto-Classify", subtitle: "AI suggests task priority levels", category: .tasks, color: FloColors.Hex.priorityHigh, isAvailableOffline: true),
        AIFeature(icon: "clock.arrow.2.circlepath", title: "Time Estimation", subtitle: "Predict how long tasks will take", category: .tasks, color: Color(hex: "4A90D9"), isAvailableOffline: true),
        AIFeature(icon: "arrow.triangle.branch", title: "Dependency Detection", subtitle: "Find tasks that block others", category: .tasks, color: FloColors.Hex.warning, isAvailableOffline: true),
        AIFeature(icon: "rectangle.stack.fill", title: "Task Batching", subtitle: "Group similar tasks for efficiency", category: .tasks, color: Color(hex: "8B5CF6"), isAvailableOffline: true),
        AIFeature(icon: "wand.and.stars", title: "Smart Reordering", subtitle: "Optimize your task order by energy", category: .tasks, color: FloColors.Hex.accent, isAvailableOffline: true),
        AIFeature(icon: "doc.on.doc.fill", title: "Template Generator", subtitle: "Create templates from completed tasks", category: .tasks, color: Color(hex: "EC4899"), isAvailableOffline: false),
        AIFeature(icon: "text.badge.checkmark", title: "Description Enhancer", subtitle: "Improve task descriptions with detail", category: .tasks, color: FloColors.Hex.success, isAvailableOffline: false),
        AIFeature(icon: "magnifyingglass.circle.fill", title: "Smart Search", subtitle: "Natural language search across all data", category: .tasks, color: Color(hex: "4A90D9"), isAvailableOffline: true),
        AIFeature(icon: "chart.bar.fill", title: "Completion Predictions", subtitle: "Predict when tasks will be done", category: .tasks, color: FloColors.Hex.warning, isAvailableOffline: true),

        // HABITS (11-18)
        AIFeature(icon: "lightbulb.fill", title: "Habit Suggestions", subtitle: "AI recommends habits for your goals", category: .habits, color: FloColors.Hex.warning, isAvailableOffline: false),
        AIFeature(icon: "chart.line.uptrend.xyaxis", title: "Streak Predictions", subtitle: "Forecast your habit streaks", category: .habits, color: FloColors.Hex.success, isAvailableOffline: true),
        AIFeature(icon: "link.circle.fill", title: "Habit Pairing", subtitle: "Stack habits for maximum impact", category: .habits, color: Color(hex: "8B5CF6"), isAvailableOffline: false),
        AIFeature(icon: "person.fill.checkmark", title: "Habit Coaching", subtitle: "Personalized encouragement messages", category: .habits, color: FloColors.Hex.accent, isAvailableOffline: false),
        AIFeature(icon: "square.grid.2x2.fill", title: "Category Suggestions", subtitle: "Auto-categorize your habits", category: .habits, color: Color(hex: "EC4899"), isAvailableOffline: true),
        AIFeature(icon: "arrow.up.forward.circle.fill", title: "Progression System", subtitle: "Level up your habit difficulty", category: .habits, color: FloColors.Hex.success, isAvailableOffline: true),
        AIFeature(icon: "bell.badge.fill", title: "Smart Reminders", subtitle: "Optimal reminder timing per habit", category: .habits, color: FloColors.Hex.warning, isAvailableOffline: true),
        AIFeature(icon: "trophy.fill", title: "Milestone Celebrations", subtitle: "AI celebrates your achievements", category: .habits, color: Color(hex: "FFD700"), isAvailableOffline: true),

        // FOCUS (19-26)
        AIFeature(icon: "brain.head.profile.fill", title: "Focus Recommendations", subtitle: "Suggest optimal session duration", category: .focus, color: Color(hex: "8B5CF6"), isAvailableOffline: true),
        AIFeature(icon: "waveform.circle.fill", title: "Sound Matching", subtitle: "Best ambient sound for your task", category: .focus, color: Color(hex: "4A90D9"), isAvailableOffline: true),
        AIFeature(icon: "cup.and.saucer.fill", title: "Break Suggestions", subtitle: "Smart break activities", category: .focus, color: FloColors.Hex.success, isAvailableOffline: true),
        AIFeature(icon: "bolt.circle.fill", title: "Energy Optimization", subtitle: "Match tasks to your energy level", category: .focus, color: FloColors.Hex.warning, isAvailableOffline: true),
        AIFeature(icon: "tag.fill", title: "Session Naming", subtitle: "Auto-name focus sessions", category: .focus, color: FloColors.Hex.accent, isAvailableOffline: true),
        AIFeature(icon: "chart.pie.fill", title: "Focus Analytics", subtitle: "Deep insights on focus patterns", category: .focus, color: Color(hex: "EC4899"), isAvailableOffline: true),
        AIFeature(icon: "arrow.triangle.2.circlepath", title: "Flow State Detection", subtitle: "Know when you're in the zone", category: .focus, color: Color(hex: "8B5CF6"), isAvailableOffline: true),
        AIFeature(icon: "gauge.with.needle.fill", title: "Productivity Score", subtitle: "AI-powered daily productivity rating", category: .focus, color: FloColors.Hex.accent, isAvailableOffline: true),

        // WELLNESS (27-34)
        AIFeature(icon: "face.smiling.fill", title: "Mood Analysis", subtitle: "Track and analyze mood patterns", category: .wellness, color: FloColors.Hex.warning, isAvailableOffline: true),
        AIFeature(icon: "heart.text.clipboard.fill", title: "Wellness Check-in", subtitle: "Daily AI wellness companion", category: .wellness, color: FloColors.Hex.error, isAvailableOffline: false),
        AIFeature(icon: "figure.walk", title: "Movement Prompts", subtitle: "Remind you to move and stretch", category: .wellness, color: FloColors.Hex.success, isAvailableOffline: true),
        AIFeature(icon: "lungs.fill", title: "Breathing Exercises", subtitle: "Guided breathing for focus", category: .wellness, color: Color(hex: "4A90D9"), isAvailableOffline: true),
        AIFeature(icon: "moon.stars.fill", title: "Sleep Insights", subtitle: "Correlate sleep with productivity", category: .wellness, color: Color(hex: "8B5CF6"), isAvailableOffline: true),
        AIFeature(icon: "scalemass.fill", title: "Work-Life Balance", subtitle: "AI monitors your balance score", category: .wellness, color: FloColors.Hex.accent, isAvailableOffline: true),
        AIFeature(icon: "leaf.fill", title: "Mindfulness Moments", subtitle: "Quick mindfulness exercises", category: .wellness, color: FloColors.Hex.success, isAvailableOffline: true),
        AIFeature(icon: "chart.xyaxis.line", title: "Stress Trend Analysis", subtitle: "Understand your stress patterns", category: .wellness, color: FloColors.Hex.warning, isAvailableOffline: true),

        // PLANNING (35-42)
        AIFeature(icon: "sun.max.fill", title: "Morning Briefing", subtitle: "AI-generated daily plan", category: .planning, color: FloColors.Hex.warning, isAvailableOffline: false),
        AIFeature(icon: "moon.fill", title: "Evening Review", subtitle: "AI-powered daily reflection", category: .planning, color: Color(hex: "8B5CF6"), isAvailableOffline: false),
        AIFeature(icon: "calendar.badge.plus", title: "Smart Scheduling", subtitle: "Optimal time slots for tasks", category: .planning, color: Color(hex: "4A90D9"), isAvailableOffline: true),
        AIFeature(icon: "flag.checkered", title: "Goal Setting", subtitle: "AI helps define SMART goals", category: .planning, color: FloColors.Hex.accent, isAvailableOffline: false),
        AIFeature(icon: "timeline.selection", title: "Project Timeline", subtitle: "Estimate project completion dates", category: .planning, color: FloColors.Hex.success, isAvailableOffline: true),
        AIFeature(icon: "list.bullet.clipboard.fill", title: "Weekly Planning", subtitle: "AI-assisted week ahead review", category: .planning, color: FloColors.Hex.warning, isAvailableOffline: false),
        AIFeature(icon: "sparkle.magnifyingglass", title: "Opportunity Finder", subtitle: "Find time gaps in your schedule", category: .planning, color: Color(hex: "EC4899"), isAvailableOffline: true),
        AIFeature(icon: "arrow.3.trianglepath", title: "Workflow Optimizer", subtitle: "Improve your daily workflow", category: .planning, color: Color(hex: "4A90D9"), isAvailableOffline: false),

        // INSIGHTS (43-47)
        AIFeature(icon: "chart.line.flattrend.xyaxis", title: "Productivity Trends", subtitle: "Weekly and monthly trend analysis", category: .insights, color: FloColors.Hex.accent, isAvailableOffline: true),
        AIFeature(icon: "brain.fill", title: "Pattern Recognition", subtitle: "Find hidden productivity patterns", category: .insights, color: Color(hex: "8B5CF6"), isAvailableOffline: true),
        AIFeature(icon: "square.and.arrow.up.fill", title: "Smart Export", subtitle: "AI-summarized data exports", category: .insights, color: Color(hex: "4A90D9"), isAvailableOffline: false),
        AIFeature(icon: "exclamationmark.triangle.fill", title: "Burnout Detection", subtitle: "Early warning for overwork", category: .insights, color: FloColors.Hex.error, isAvailableOffline: true),
        AIFeature(icon: "medal.fill", title: "Achievement System", subtitle: "AI tracks and rewards progress", category: .insights, color: Color(hex: "FFD700"), isAvailableOffline: true),

        // WRITING & COACHING (48-50)
        AIFeature(icon: "text.book.closed.fill", title: "Journal Prompts", subtitle: "Personalized daily writing prompts", category: .writing, color: FloColors.Hex.accent, isAvailableOffline: true),
        AIFeature(icon: "quote.bubble.fill", title: "Daily Motivation", subtitle: "AI-curated motivational messages", category: .coaching, color: FloColors.Hex.warning, isAvailableOffline: true),
        AIFeature(icon: "bubble.left.and.bubble.right.fill", title: "AI Assistant", subtitle: "Chat with Flo about anything", category: .coaching, color: Color(hex: "8B5CF6"), isAvailableOffline: false),
    ]
}
