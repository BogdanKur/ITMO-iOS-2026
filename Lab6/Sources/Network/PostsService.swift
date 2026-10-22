import Foundation
import Alamofire
struct RemotePost: Codable, Identifiable, Equatable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
struct NewPost: Encodable, Sendable { let title: String; let body: String; let userId: Int }
struct HTTPPayload: Sendable { let status: Int; let data: Data }
enum APIError: LocalizedError {
    case transport(String), invalidResponse, http(Int, String), emptyData, decoding
    var errorDescription: String? {
        switch self {
        case .transport(let message): return "Ошибка сети: " + message
        case .invalidResponse: return "Сервер не вернул HTTP-ответ."
        case .http(let code, let body): return "HTTP \(code): \(body)"
        case .emptyData: return "Сервер вернул пустые данные."
        case .decoding: return "Не удалось разобрать JSON сервера."
        }
    }
}
protocol HTTPTransport: Sendable { func send(_ request: URLRequest) async throws -> HTTPPayload }
struct AlamofireTransport: HTTPTransport {
    func send(_ request: URLRequest) async throws -> HTTPPayload {
        // Alamofire performs networking and response serialization outside the main actor.
        let response = await AF.request(request).serializingData(automaticallyCancelling: true).response
        if Task.isCancelled { throw CancellationError() }
        guard let http = response.response else {
            if let error = response.error { throw APIError.transport(error.localizedDescription) }
            throw APIError.invalidResponse
        }
        // HTTP errors are handled separately from transport errors by ResponseParser.
        if let error = response.error, (200..<300).contains(http.statusCode) {
            throw APIError.transport(error.localizedDescription)
        }
        return HTTPPayload(status: http.statusCode, data: response.data ?? Data())
    }
}
enum ResponseParser {
    static func decode<T: Decodable>(_ type: T.Type, from payload: HTTPPayload) throws -> T {
        guard (200..<300).contains(payload.status) else {
            let body = String(data: payload.data.prefix(200), encoding: .utf8) ?? "нет текста ошибки"
            throw APIError.http(payload.status, body)
        }
        guard !payload.data.isEmpty else { throw APIError.emptyData }
        do { return try JSONDecoder().decode(type, from: payload.data) }
        catch { throw APIError.decoding }
    }
}
protocol PostsService: Sendable {
    func fetchPosts() async throws -> [RemotePost]
    func createPost(title: String, body: String) async throws -> RemotePost
}
struct APIClient: PostsService {
    let transport: any HTTPTransport
    init(transport: any HTTPTransport = AlamofireTransport()) { self.transport = transport }
    private let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    func fetchPosts() async throws -> [RemotePost] {
        let payload = try await transport.send(request(method: "GET"))
        let posts = try ResponseParser.decode([RemotePost].self, from: payload)
        return posts.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.id < $1.id }
    }
    func createPost(title: String, body: String) async throws -> RemotePost {
        var request = request(method: "POST")
        request.httpBody = try JSONEncoder().encode(NewPost(title: try NoteValidator.title(title), body: body, userId: 1))
        return try ResponseParser.decode(RemotePost.self, from: await transport.send(request))
    }
    private func request(method: String) -> URLRequest {
        var r = URLRequest(url: baseURL.appendingPathComponent("posts"))
        r.httpMethod = method; r.timeoutInterval = 20
        r.setValue("application/json", forHTTPHeaderField: "Accept")
        if method == "POST" { r.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type") }
        return r
    }
}
