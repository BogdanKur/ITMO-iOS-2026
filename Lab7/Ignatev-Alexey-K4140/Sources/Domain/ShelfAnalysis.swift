import Foundation

struct ShelfStatistics: Equatable, Sendable {
    let total: Int
    let finished: Int
    let minutes: Int
    let average: Double?
}

enum ShelfAnalysis {
    static func search(_ entries: [LibraryEntry], query: String) throws -> [LibraryEntry] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return try entries.filter {
            try Task.checkCancellation()
            return query.isEmpty || $0.show.name.localizedCaseInsensitiveContains(query) ||
                $0.review.localizedCaseInsensitiveContains(query)
        }.sorted {
            $0.show.name.localizedStandardCompare($1.show.name) == .orderedAscending
        }
    }

    static func statistics(_ entries: [LibraryEntry]) throws -> ShelfStatistics {
        var finished = 0, minutes = 0, sum = 0, rated = 0
        for entry in entries {
            try Task.checkCancellation()
            if entry.status == .finished {
                finished += 1
            }
            minutes += entry.watchedEpisodes * entry.show.runtime
            if entry.personalRating > 0 {
                sum += entry.personalRating
                rated += 1
            }
        }
        return ShelfStatistics(total: entries.count, finished: finished, minutes: minutes,
                               average: rated == 0 ? nil : Double(sum) / Double(rated))
    }
}
