import Foundation
import SwiftData

@Model
final class Note {
    var title: String
    var content: String
    var isPinned: Bool
    var isFavorite: Bool
    var isTemplate: Bool
    var templateName: String?
    var wordCount: Int
    var readingTimeSeconds: Int
    var createdAt: Date
    var updatedAt: Date
    var supabaseId: String?

    @Relationship(deleteRule: .nullify, inverse: \NoteFolder.notes)
    var folder: NoteFolder?

    init(
        title: String = "",
        content: String = "",
        isPinned: Bool = false,
        isFavorite: Bool = false,
        isTemplate: Bool = false,
        templateName: String? = nil,
        folder: NoteFolder? = nil
    ) {
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.isTemplate = isTemplate
        self.templateName = templateName
        self.wordCount = content.split(separator: " ").count
        self.readingTimeSeconds = max(1, content.split(separator: " ").count / 4) * 60
        self.createdAt = .now
        self.updatedAt = .now
        self.supabaseId = nil
        self.folder = folder
    }

    var preview: String {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.prefix(2).joined(separator: " ")
    }

    var readingTimeLabel: String {
        let minutes = readingTimeSeconds / 60
        if minutes < 1 { return "< 1 min read" }
        return "\(minutes) min read"
    }

    func updateMetrics() {
        wordCount = content.split(separator: " ").count
        readingTimeSeconds = max(1, wordCount / 4) * 60
    }

    static let templates: [(String, String)] = [
        ("Meeting Notes", "## Meeting Notes\n\n**Date:** \n**Attendees:** \n\n### Agenda\n- \n\n### Discussion\n\n\n### Action Items\n- [ ] \n"),
        ("Daily Journal", "## Daily Journal\n\n**Mood:** \n**Energy:** \n\n### What happened today\n\n\n### What I'm grateful for\n\n\n### Tomorrow's focus\n"),
        ("Project Brief", "## Project Brief\n\n**Project:** \n**Goal:** \n**Timeline:** \n\n### Background\n\n\n### Requirements\n- \n\n### Success Metrics\n- \n"),
        ("Brainstorm", "## Brainstorm Session\n\n**Topic:** \n\n### Ideas\n1. \n2. \n3. \n\n### Next Steps\n- \n"),
        ("Reading Notes", "## Reading Notes\n\n**Title:** \n**Author:** \n\n### Key Takeaways\n- \n\n### Quotes\n> \n\n### My Thoughts\n")
    ]
}

@Model
final class NoteFolder {
    var name: String
    var icon: String
    var createdAt: Date

    var notes: [Note]

    @Relationship(deleteRule: .nullify, inverse: \NoteFolder.parentFolder)
    var subfolders: [NoteFolder]

    @Relationship(deleteRule: .nullify)
    var parentFolder: NoteFolder?

    init(name: String, icon: String = "folder.fill") {
        self.name = name
        self.icon = icon
        self.createdAt = .now
        self.notes = []
        self.subfolders = []
        self.parentFolder = nil
    }
}
