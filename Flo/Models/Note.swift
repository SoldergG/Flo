import Foundation
import SwiftData

@Model
final class Note {
    var title: String
    var content: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \NoteFolder.notes)
    var folder: NoteFolder?

    init(
        title: String = "",
        content: String = "",
        isPinned: Bool = false,
        folder: NoteFolder? = nil
    ) {
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.createdAt = .now
        self.updatedAt = .now
        self.folder = folder
    }

    var preview: String {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.prefix(2).joined(separator: " ")
    }

    var wordCount: Int {
        content.split(separator: " ").count
    }
}

@Model
final class NoteFolder {
    var name: String
    var icon: String
    var createdAt: Date

    var notes: [Note]

    init(name: String, icon: String = "folder.fill") {
        self.name = name
        self.icon = icon
        self.createdAt = .now
        self.notes = []
    }
}
