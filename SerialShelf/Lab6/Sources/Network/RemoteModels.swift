import Foundation

struct RemoteShow: Decodable {
    struct Image: Decodable { let medium: String? }
    struct Rating: Decodable { let average: Double? }
    let id: Int
    let name: String
    let premiered: String?
    let genres: [String]
    let summary: String?
    let runtime: Int?
    let averageRuntime: Int?
    let rating: Rating
    let image: Image?
    let url: String

    func domain() -> Show {
        let text = (summary ?? "Описание пока отсутствует.")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        return Show(id: id, name: name, year: String((premiered ?? "—").prefix(4)),
            genres: genres, summary: text, runtime: max(1, averageRuntime ?? runtime ?? 45),
            rating: rating.average, imageURL: image?.medium, sourceURL: url)
    }
}

struct SearchHit: Decodable { let show: RemoteShow }
struct ReviewRequest: Encodable { let title: String; let body: String; let userId: Int }
struct ReviewReceipt: Codable, Equatable, Sendable { let id: Int; let title: String; let body: String; let userId: Int }
