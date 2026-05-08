import SwiftUI
import SwiftData

// MARK: - Journal View (FIX #12: add create/edit/delete + full entry sheet)

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var editingEntry: JournalEntry?
    @State private var showingNewEntry = false

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            if entries.isEmpty {
                emptyState
            } else {
                entriesList
            }
        }
        .navigationTitle("Journal")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        // FIX #13: toolbar button to create entries
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FloIconButton("square.and.pencil", color: FloColors.Hex.accent) {
                    showingNewEntry = true
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            JournalEntryEditor(entry: nil)
        }
        .sheet(item: $editingEntry) { entry in
            JournalEntryEditor(entry: entry)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(FloColors.Hex.border)

            Text("No journal entries yet")
                .font(FloTypography.title3)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Text("Write your thoughts, reflect on your day")
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)
                .multilineTextAlignment(.center)

            FloButton("Start Writing", icon: "square.and.pencil", style: .secondary) {
                showingNewEntry = true
            }
            .frame(width: 200)
        }
    }

    // MARK: - Entries List

    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(entries) { entry in
                    // FIX #14: tap to open entry for editing
                    Button {
                        editingEntry = entry
                    } label: {
                        JournalEntryCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                    // FIX #15: swipe to delete
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation { context.delete(entry); try? context.save() }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 80)
        }
    }
}

// MARK: - Journal Entry Card

struct JournalEntryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    // FIX #16: show title if not empty
                    if !entry.title.isEmpty {
                        Text(entry.title)
                            .font(FloTypography.headline)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        Text(entry.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                        Text("·")
                            .foregroundStyle(FloColors.Hex.textTertiary)
                        Text(entry.createdAt.formatted(.dateTime.hour().minute()))
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                }
                Spacer()
                // FIX #17: show mood emoji if present
                if let emoji = entry.moodEmoji {
                    Text(emoji)
                        .font(.system(size: 20))
                }
            }

            if !entry.preview.isEmpty {
                Text(entry.preview)
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .lineLimit(3)
            }

            // FIX #18: word count footer
            HStack(spacing: 12) {
                Label("\(entry.wordCount) words", systemImage: "text.alignleft")
                    .font(FloTypography.caption2)
                    .foregroundStyle(FloColors.Hex.textTertiary)

                if !entry.tags.isEmpty {
                    Label(entry.tags.prefix(2).joined(separator: ", "), systemImage: "tag")
                        .font(FloTypography.caption2)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Journal Entry Editor (FIX #19: full create/edit sheet)

struct JournalEntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let entry: JournalEntry?

    @State private var title = ""
    @State private var content = ""
    @State private var selectedMood: Int? = nil
    @State private var tagText = ""
    @State private var tags: [String] = []
    @FocusState private var contentFocused: Bool

    private let moods: [(value: Int, emoji: String)] = [
        (1, "😫"), (2, "😕"), (3, "😐"), (4, "😊"), (5, "🤩")
    ]

    var isNew: Bool { entry == nil }

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Title
                        TextField("Title (optional)", text: $title)
                            .font(FloTypography.title2)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        Divider().padding(.horizontal, 20)

                        // Content
                        TextEditor(text: $content)
                            .font(FloTypography.body)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                            .scrollContentBackground(.hidden)
                            .focused($contentFocused)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 200)

                        // Mood selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                                .padding(.horizontal, 20)

                            HStack(spacing: 16) {
                                ForEach(moods, id: \.value) { m in
                                    Button {
                                        withAnimation(FloAnimations.springSnappy) {
                                            selectedMood = selectedMood == m.value ? nil : m.value
                                        }
                                    } label: {
                                        Text(m.emoji)
                                            .font(.system(size: 28))
                                            .scaleEffect(selectedMood == m.value ? 1.2 : 0.85)
                                            .opacity(selectedMood == nil || selectedMood == m.value ? 1 : 0.4)
                                    }
                                    .buttonStyle(.plain)
                                    .animation(FloAnimations.springSnappy, value: selectedMood)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }

                        // FIX #20: tag input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                                .padding(.horizontal, 20)

                            HStack(spacing: 8) {
                                TextField("Add tag…", text: $tagText)
                                    .font(FloTypography.body)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(FloColors.Hex.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .onSubmit { addTag() }

                                Button("Add") { addTag() }
                                    .font(FloTypography.footnote)
                                    .foregroundStyle(FloColors.Hex.accent)
                                    .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal, 20)

                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(tags, id: \.self) { tag in
                                            HStack(spacing: 4) {
                                                Text("#\(tag)")
                                                    .font(FloTypography.caption)
                                                    .foregroundStyle(FloColors.Hex.accent)
                                                Button {
                                                    tags.removeAll { $0 == tag }
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 9, weight: .semibold))
                                                        .foregroundStyle(FloColors.Hex.textTertiary)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(FloColors.Hex.accentSoft)
                                            .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Word count footer
                        HStack {
                            Text("\(content.split(separator: " ").count) words")
                                .font(FloTypography.caption)
                                .foregroundStyle(FloColors.Hex.textTertiary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle(isNew ? "New Entry" : "Edit Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if isNew && title.isEmpty && content.isEmpty { }
                        dismiss()
                    }
                    .foregroundStyle(FloColors.Hex.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(FloColors.Hex.accent)
                        .fontWeight(.semibold)
                        .disabled(content.isEmpty)
                }
            }
            .onAppear {
                if let e = entry {
                    title = e.title
                    content = e.content
                    selectedMood = e.mood
                    tags = e.tags
                } else {
                    contentFocused = true
                }
            }
        }
    }

    private func addTag() {
        let t = tagText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !t.isEmpty, !tags.contains(t) else { tagText = ""; return }
        tags.append(t)
        tagText = ""
    }

    private func save() {
        if let e = entry {
            // Update existing
            e.title = title
            e.content = content
            e.mood = selectedMood
            e.tags = tags
            e.updatedAt = .now
        } else {
            // Create new
            let newEntry = JournalEntry(title: title, content: content, mood: selectedMood, tags: tags)
            context.insert(newEntry)
        }
        try? context.save()
        HapticManager.trigger(.success)
        dismiss()
    }
}
