import Foundation
import SwiftData
import SwiftUI

@Model
final class Tag {
    var name: String
    var colorHex: String

    var tasks: [TaskItem]

    init(name: String, colorHex: String = "D97757") {
        self.name = name
        self.colorHex = colorHex
        self.tasks = []
    }

    var color: Color {
        Color(hex: colorHex)
    }
}
