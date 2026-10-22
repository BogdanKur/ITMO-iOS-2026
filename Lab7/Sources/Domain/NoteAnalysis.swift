import Foundation
struct NoteStatistics: Equatable, Sendable {
    let noteCount: Int
    let wordCount: Int
    let characterCount: Int
}
enum NoteAnalysis {
    static func search(_ notes: [Note], query: String) throws -> [Note] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return try notes.filter { note in
            try Task.checkCancellation()
            return query.isEmpty || note.title.localizedCaseInsensitiveContains(query) ||
                note.body.localizedCaseInsensitiveContains(query)
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    static func statistics(_ notes: [Note]) throws -> NoteStatistics {
        var words = 0, characters = 0
        for note in notes {
            try Task.checkCancellation()
            let text = note.title + " " + note.body
            words += text.split(whereSeparator: { $0.isWhitespace }).count
            characters += note.title.count + note.body.count
        }
        return NoteStatistics(noteCount: notes.count, wordCount: words, characterCount: characters)
    }
}
