import Foundation
import SwiftData

@Model
final class FocusPreset {
    var name: String
    var durationSeconds: Int
    var breakSeconds: Int
    var ambientSound: String?
    var icon: String
    var colorHex: String
    var createdAt: Date
    var supabaseId: String?

    init(
        name: String,
        durationSeconds: Int,
        breakSeconds: Int = 300,
        ambientSound: String? = nil,
        icon: String = "timer",
        colorHex: String = "D97757"
    ) {
        self.name = name
        self.durationSeconds = durationSeconds
        self.breakSeconds = breakSeconds
        self.ambientSound = ambientSound
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = .now
        self.supabaseId = nil
    }

    var durationMinutes: Int { durationSeconds / 60 }
    var breakMinutes: Int { breakSeconds / 60 }

    static let defaults: [(String, Int, Int, String, String)] = [
        ("Quick Focus", 900, 180, "bolt.fill", "E5A84B"),
        ("Pomodoro", 1500, 300, "timer", "D97757"),
        ("Deep Work", 3000, 600, "brain.head.profile.fill", "5BA37C"),
        ("Marathon", 5400, 900, "flame.fill", "D94F4F")
    ]
}
