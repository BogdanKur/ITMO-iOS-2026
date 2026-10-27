import Foundation

protocol CatalogService: Sendable {
    func shows(query: String) async throws -> [Show]
}

protocol ReviewService: Sendable {
    func sendReview(show: Show, text: String) async throws -> ReviewReceipt
}

struct CatalogAPI: CatalogService, ReviewService {
    let transport: any HTTPTransport
    init(transport: any HTTPTransport = AlamofireTransport()) { self.transport = transport }

    func shows(query: String) async throws -> [Show] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var url = URLComponents(string: "https://api.tvmaze.com" )!
        url.path = query.isEmpty ? "/shows" : "/search/shows"
        url.queryItems = [URLQueryItem(name: query.isEmpty ? "page" : "q", value: query.isEmpty ? "0" : query)]
        var request = URLRequest(url: url.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let payload = try await transport.send(request)
        let remote: [RemoteShow]
        if query.isEmpty { remote = try ResponseParser.decode([RemoteShow].self, from: payload) }
        else { remote = try ResponseParser.decode([SearchHit].self, from: payload).map(\.show) }
        var ids = Set<Int>()
        return remote.map { $0.domain() }.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && ids.insert($0.id).inserted
        }.sorted {
            ($0.rating ?? -1) == ($1.rating ?? -1) ? $0.id < $1.id : ($0.rating ?? -1) > ($1.rating ?? -1)
        }
    }

    func sendReview(show: Show, text: String) async throws -> ReviewReceipt {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty && text.count <= 2000 else { throw LibraryError.longReview }
        var request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(ReviewRequest(title: show.name, body: text, userId: 1))
        return try ResponseParser.decode(ReviewReceipt.self, from: await transport.send(request))
    }
}
