import Foundation
import SwiftData

@Model
final class SmartList {
    var name: String
    var icon: String
    var colorHex: String
    var filterJSON: String
    var createdAt: Date
    var supabaseId: String?

    init(
        name: String,
        icon: String = "line.3.horizontal.decrease.circle",
        colorHex: String = "D97757",
        filterJSON: String = "{}"
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.filterJSON = filterJSON
        self.createdAt = .now
        self.supabaseId = nil
    }

    enum FilterType: String, Codable {
        case overdue
        case today
        case thisWeek
        case upcoming
        case noDate
        case completed
        case highPriority
        case custom
    }

    static let builtIn: [(String, String, String, FilterType)] = [
        ("Overdue", "exclamationmark.circle.fill", "D94F4F", .overdue),
        ("Today", "sun.max.fill", "E5A84B", .today),
        ("This Week", "calendar", "4A90D9", .thisWeek),
        ("Upcoming", "arrow.right.circle.fill", "5BA37C", .upcoming),
        ("No Date", "questionmark.circle.fill", "9B8E82", .noDate),
        ("Completed", "checkmark.circle.fill", "5BA37C", .completed),
        ("High Priority", "flame.fill", "D94F4F", .highPriority)
    ]
}
