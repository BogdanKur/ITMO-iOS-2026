import Foundation
import Alamofire

struct HTTPPayload: Sendable { let status: Int; let data: Data }

enum APIError: LocalizedError {
    case transport(String), invalidResponse, http(Int), emptyData, decoding
    var errorDescription: String? {
        switch self {
        case .transport(let message): return "Ошибка соединения: " + message
        case .invalidResponse: return "Сервер не вернул HTTP-ответ."
        case .http(let code): return "Ошибка HTTP \(code). Попробуй повторить запрос."
        case .emptyData: return "Сервер вернул пустое тело ответа."
        case .decoding: return "Не удалось прочитать JSON сервера."
        }
    }
}

protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPPayload
}

struct AlamofireTransport: HTTPTransport {
    func send(_ request: URLRequest) async throws -> HTTPPayload {
        let response = await AF.request(request).serializingData(
            automaticallyCancelling: true, emptyResponseCodes: Set(200..<300)).response
        try Task.checkCancellation()
        guard let http = response.response else {
            if let error = response.error { throw APIError.transport(error.localizedDescription) }
            throw APIError.invalidResponse
        }
        if let error = response.error, (200..<300).contains(http.statusCode) {
            throw APIError.transport(error.localizedDescription)
        }
        return HTTPPayload(status: http.statusCode, data: response.data ?? Data())
    }
}

enum ResponseParser {
    static func decode<T: Decodable>(_ type: T.Type, from payload: HTTPPayload) throws -> T {
        guard (200..<300).contains(payload.status) else { throw APIError.http(payload.status) }
        guard !payload.data.isEmpty else { throw APIError.emptyData }
        do { return try JSONDecoder().decode(type, from: payload.data) }
        catch { throw APIError.decoding }
    }
}
