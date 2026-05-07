import SwiftUI
import SwiftData

// MARK: - AI Assistant Chat View

struct AIAssistantView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @FocusState private var isInputFocused: Bool

    private let ai = FloAIService.shared

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeSection
                            }

                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(FloAnimations.springDefault) {
                            if let lastID = messages.last?.id {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input bar
                inputBar
            }
        }
        .navigationTitle("AI Assistant")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    messages = []
                    ai.clearConversation()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            }
        }
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(FloColors.Hex.accentSoft)
                    .frame(width: 120, height: 120)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(FloColors.Hex.accent)
            }

            VStack(spacing: 8) {
                Text("Hi! I'm your Flo AI Assistant")
                    .font(FloTypography.title2)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Ask me anything about productivity, tasks, habits, or focus.")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Quick actions
            VStack(spacing: 8) {
                quickAction("Give me a productivity tip", icon: "lightbulb.fill")
                quickAction("Suggest a daily plan", icon: "calendar")
                quickAction("How can I focus better?", icon: "brain.head.profile.fill")
                quickAction("Generate a journal prompt", icon: "text.book.closed.fill")
                quickAction("Motivate me!", icon: "flame.fill")
            }
            .padding(.top, 8)
        }
    }

    private func quickAction(_ text: String, icon: String) -> some View {
        Button {
            sendMessage(text)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(FloColors.Hex.accent)
                    .frame(width: 28, height: 28)
                    .background(FloColors.Hex.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(text)
                    .font(FloTypography.subheadline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FloColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(FloColors.Hex.border.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Ask Flo anything...", text: $inputText, axis: .vertical)
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textPrimary)
                    .focused($isInputFocused)
                    .lineLimit(1...4)
                    .onSubmit { sendMessage(inputText) }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FloColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isInputFocused ? FloColors.Hex.accent : FloColors.Hex.border, lineWidth: isInputFocused ? 2 : 1)
            )

            // Send button
            Button {
                sendMessage(inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(inputText.isEmpty ? FloColors.Hex.border : FloColors.Hex.accent)
            }
            .disabled(inputText.isEmpty || isTyping)
            .buttonStyle(.plain)
            .animation(FloAnimations.easeFast, value: inputText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FloColors.Hex.background)
    }

    // MARK: - Send Message

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        inputText = ""
        isTyping = true

        Task {
            do {
                let systemPrompt = buildSystemPrompt()
                let response = try await ai.chat(
                    prompt: trimmed,
                    systemPrompt: systemPrompt,
                    temperature: 0.7,
                    maxTokens: 512
                )

                await MainActor.run {
                    let aiMessage = ChatMessage(role: .assistant, content: response)
                    messages.append(aiMessage)
                    isTyping = false
                }
            } catch {
                await MainActor.run {
                    let errorMsg = ChatMessage(role: .assistant, content: "I couldn't process that right now. Try again or check your internet connection.")
                    messages.append(errorMsg)
                    isTyping = false
                }
            }
        }
    }

    private func buildSystemPrompt() -> String {
        let userName = UserDefaults.standard.string(forKey: "user_display_name") ?? "friend"
        let pendingTasks = tasks.filter { !$0.isCompleted && !$0.isTemplate }.count
        let todayHabits = habits.filter(\.isCompletedToday).count

        return """
        You are Flo, a warm, calm, and encouraging productivity companion. The user's name is \(userName).
        Current context: \(pendingTasks) pending tasks, \(todayHabits)/\(habits.count) habits completed today.
        Be concise (2-4 sentences). Use a friendly, supportive tone. Give actionable advice.
        Don't use markdown headers or bullet points. Write in natural, conversational prose.
        """
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()

    enum Role {
        case user, assistant
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage
    @State private var visible = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user { Spacer(minLength: 60) }

            if message.role == .assistant {
                // AI avatar
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(FloColors.Hex.accent)
                    .clipShape(Circle())
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(FloTypography.body)
                    .foregroundStyle(message.role == .user ? .white : FloColors.Hex.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? AnyShapeStyle(FloColors.Hex.accent)
                            : AnyShapeStyle(FloColors.Hex.surface)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(FloTypography.caption2)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 10)
        .onAppear {
            withAnimation(FloAnimations.springDefault) {
                visible = true
            }
        }
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var dotIndex = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(FloColors.Hex.accent)
                .clipShape(Circle())

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(FloColors.Hex.textTertiary)
                        .frame(width: 7, height: 7)
                        .offset(y: dotIndex == i ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: dotIndex
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(FloColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer()
        }
        .onAppear { dotIndex = 1 }
    }
}
