import Foundation
import SwiftData
import SwiftUI

@Observable
final class NotesViewModel {
    var showingAddNote = false
    var showingAddFolder = false
    var searchText = ""
    var selectedFolder: NoteFolder?

    func addNote(title: String, content: String = "", folder: NoteFolder? = nil, context: ModelContext) {
        let note = Note(title: title, content: content, folder: folder)
        context.insert(note)
        try? context.save()
    }

    func deleteNote(_ note: Note, context: ModelContext) {
        context.delete(note)
        try? context.save()
    }

    func addFolder(name: String, icon: String = "folder.fill", context: ModelContext) {
        let folder = NoteFolder(name: name, icon: icon)
        context.insert(folder)
        try? context.save()
    }

    func updateNote(_ note: Note, context: ModelContext) {
        note.updatedAt = .now
        try? context.save()
    }
}
