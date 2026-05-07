import Foundation
import SwiftData

@Model
final class MoodEntry {
    var mood: Int
    var energy: Int
    var note: String
    var topPriorities: [String]
    var entryType: String
    var productivityScore: Int?
    var gratitude: String?
    var createdAt: Date
    var supabaseId: String?

    init(
        mood: Int = 3,
        energy: Int = 3,
        note: String = "",
        topPriorities: [String] = [],
        entryType: String = "morning",
        productivityScore: Int? = nil,
        gratitude: String? = nil
    ) {
        self.mood = mood
        self.energy = energy
        self.note = note
        self.topPriorities = topPriorities
        self.entryType = entryType
        self.productivityScore = productivityScore
        self.gratitude = gratitude
        self.createdAt = .now
        self.supabaseId = nil
    }

    var moodEmoji: String {
        switch mood {
        case 1: return "😫"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "🤩"
        default: return "😐"
        }
    }

    var energyLabel: String {
        switch energy {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Medium"
        case 4: return "High"
        case 5: return "Very High"
        default: return "Medium"
        }
    }
}
