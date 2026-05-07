import Foundation
import SwiftData

@Model
final class JournalEntry {
    var title: String
    var content: String
    var mood: Int?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var supabaseId: String?

    init(
        title: String = "",
        content: String = "",
        mood: Int? = nil,
        tags: [String] = []
    ) {
        self.title = title
        self.content = content
        self.mood = mood
        self.tags = tags
        self.createdAt = .now
        self.updatedAt = .now
        self.supabaseId = nil
    }

    var moodEmoji: String? {
        guard let mood else { return nil }
        switch mood {
        case 1: return "😫"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "🤩"
        default: return nil
        }
    }

    var preview: String {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.prefix(2).joined(separator: " ")
    }

    var wordCount: Int {
        content.split(separator: " ").count
    }
}
