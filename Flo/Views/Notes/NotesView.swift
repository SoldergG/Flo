import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @Query private var folders: [NoteFolder]
    @State private var vm = NotesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                if notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    FloIconButton("plus.circle.fill", color: FloColors.Hex.accent) {
                        let note = Note(title: "", content: "")
                        context.insert(note)
                        try? context.save()
                        vm.showingAddNote = true
                    }
                }
            }
            .sheet(isPresented: $vm.showingAddNote) {
                if let lastNote = notes.first {
                    NoteEditorSheet(note: lastNote)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 56))
                .foregroundStyle(FloColors.Hex.border)

            Text("No notes yet")
                .font(FloTypography.title3)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Text("Capture your thoughts and ideas")
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)

            FloButton("New Note", icon: "plus", style: .secondary) {
                let note = Note(title: "", content: "")
                context.insert(note)
                vm.showingAddNote = true
            }
            .frame(width: 200)
        }
    }

    private var filteredNotes: [Note] {
        var result = notes
        if let folder = vm.selectedFolder {
            result = result.filter { $0.folder?.persistentModelID == folder.persistentModelID }
        }
        if !vm.searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(vm.searchText) ||
                $0.content.localizedCaseInsensitiveContains(vm.searchText)
            }
        }
        return result
    }

    private var pinnedNotes: [Note] {
        filteredNotes.filter(\.isPinned)
    }

    private var unpinnedNotes: [Note] {
        filteredNotes.filter { !$0.isPinned }
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Folder filter
                if !folders.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: vm.selectedFolder == nil) {
                                vm.selectedFolder = nil
                            }
                            ForEach(folders) { folder in
                                FilterChip(
                                    label: folder.name,
                                    isSelected: vm.selectedFolder?.persistentModelID == folder.persistentModelID
                                ) {
                                    vm.selectedFolder = folder
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)
                }

                // Pinned
                if !pinnedNotes.isEmpty {
                    sectionHeader("Pinned")
                    ForEach(pinnedNotes) { note in
                        NoteCard(note: note)
                    }
                }

                // All notes
                if !unpinnedNotes.isEmpty {
                    if !pinnedNotes.isEmpty {
                        sectionHeader("Notes")
                    }
                    ForEach(unpinnedNotes) { note in
                        NoteCard(note: note)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .searchable(text: $vm.searchText, prompt: "Search notes...")
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(FloTypography.footnote)
                .foregroundStyle(FloColors.Hex.textTertiary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: Note
    @State private var showEditor = false

    var body: some View {
        Button {
            showEditor = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(FloColors.Hex.accent)
                    }

                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(note.updatedAt.formatted(.dateTime.month().day()))
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }

                if !note.preview.isEmpty {
                    Text(note.preview)
                        .font(FloTypography.footnote)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                        .lineLimit(2)
                }

                if let folder = note.folder {
                    HStack(spacing: 4) {
                        Image(systemName: folder.icon)
                            .font(.system(size: 10))
                        Text(folder.name)
                            .font(FloTypography.caption2)
                    }
                    .foregroundStyle(FloColors.Hex.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditor) {
            NoteEditorSheet(note: note)
        }
    }
}

// MARK: - Note Editor

struct NoteEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var note: Note

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    TextField("Title", text: $note.title)
                        .font(FloTypography.title2)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    TextEditor(text: $note.content)
                        .font(FloTypography.body)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Bottom bar
                    HStack {
                        Text("\(note.wordCount) words")
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textTertiary)

                        Spacer()

                        Button {
                            withAnimation(FloAnimations.springSnappy) {
                                note.isPinned.toggle()
                            }
                        } label: {
                            Image(systemName: note.isPinned ? "pin.slash.fill" : "pin.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(FloColors.Hex.surface)
                }
            }
            .navigationTitle("Edit Note")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        note.updatedAt = .now
                        try? context.save()
                        dismiss()
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                }
            }
        }
    }
}
