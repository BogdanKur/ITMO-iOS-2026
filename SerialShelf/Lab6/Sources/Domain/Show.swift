import Foundation

struct Show: Identifiable, Codable, Equatable, Sendable {
    let id: Int
    let name: String
    let year: String
    let genres: [String]
    let summary: String
    let runtime: Int
    let rating: Double?
    let imageURL: String?
    let sourceURL: String
}

enum WatchStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case planned = "Хочу посмотреть"
    case watching = "Смотрю"
    case finished = "Просмотрено"
    var id: String { rawValue }
}

struct LibraryEntry: Identifiable, Codable, Equatable, Sendable {
    var id: Int { show.id }
    let show: Show
    var status: WatchStatus = .planned
    var personalRating: Int = 0
    var watchedEpisodes: Int = 0
    var review: String = ""
    let addedAt: Date
    var updatedAt: Date

    init(show: Show, now: Date = Date()) {
        self.show = show
        addedAt = now
        updatedAt = now
    }
}

enum LibraryError: LocalizedError {
    case duplicate, missing, invalidRating, invalidEpisodes, longReview, invalidReview
    var errorDescription: String? {
        switch self {
        case .duplicate: return "Этот сериал уже есть в коллекции."
        case .missing: return "Запись больше не существует."
        case .invalidRating: return "Оценка должна быть от 0 до 10."
        case .invalidEpisodes: return "Число серий должно быть от 0 до 10000."
        case .longReview: return "Комментарий должен быть не длиннее 2000 символов."
        case .invalidReview: return "Отзыв должен содержать от 1 до 2000 символов."
        }
    }
}

enum EntryValidator {
    static func validate(_ entry: LibraryEntry) throws {
        guard (0...10).contains(entry.personalRating) else { throw LibraryError.invalidRating }
        guard (0...10000).contains(entry.watchedEpisodes) else { throw LibraryError.invalidEpisodes }
        guard entry.review.count <= 2000 else { throw LibraryError.longReview }
    }
}
