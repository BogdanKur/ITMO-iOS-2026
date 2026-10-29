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
