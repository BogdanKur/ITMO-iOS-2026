import XCTest
@testable import StudyNotes
private actor StubTransport: HTTPTransport {
    let payload: HTTPPayload
    private(set) var requests: [URLRequest] = []
    init(status: Int = 200, json: String) { payload = HTTPPayload(status: status, data: Data(json.utf8)) }
    func send(_ request: URLRequest) async throws -> HTTPPayload { requests.append(request); return payload }
}
private struct BrokenTransport: HTTPTransport {
    func send(_ request: URLRequest) async throws -> HTTPPayload { throw APIError.transport("offline") }
}
final class NetworkTests: XCTestCase {
    private let post = #"{"userId":1,"id":101,"title":"Swift","body":"Hello"}"#
    func testGETParsesFiltersSortsAndBuildsCorrectRequest() async throws {
        let transport = StubTransport(json: #"[{"userId":1,"id":2,"title":"B","body":""},{"userId":1,"id":1,"title":"A","body":""},{"userId":1,"id":3,"title":" ","body":""}]"#)
        let posts = try await APIClient(transport: transport).fetchPosts()
        XCTAssertEqual(posts.map(\.id), [1,2])
        let requests = await transport.requests
        XCTAssertEqual(requests.first?.httpMethod, "GET")
        XCTAssertEqual(requests.first?.url?.path, "/posts")
        XCTAssertNil(requests.first?.httpBody)
    }
    func testPOSTEncodesJSONAndParsesCreatedObject() async throws {
        let transport = StubTransport(status: 201, json: post)
        let result = try await APIClient(transport: transport).createPost(title: " Swift ", body: "Hello")
        XCTAssertEqual(result.id, 101)
        let requests = await transport.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=UTF-8")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(json["title"] as? String, "Swift"); XCTAssertEqual(json["userId"] as? Int, 1)
    }
    func testHTTPEmptyDataAndMalformedJSONAreDistinct() {
        for status in [400,401,404,500] {
            XCTAssertThrowsError(try ResponseParser.decode(RemotePost.self, from: HTTPPayload(status: status, data: Data("failure".utf8)))) {
                guard case APIError.http(let code, _) = $0 else { return XCTFail("Expected HTTP error") }
                XCTAssertEqual(code, status)
            }
        }
        XCTAssertThrowsError(try ResponseParser.decode(RemotePost.self, from: HTTPPayload(status: 200, data: Data()))) {
            guard case APIError.emptyData = $0 else { return XCTFail("Expected empty data") }
        }
        XCTAssertThrowsError(try ResponseParser.decode(RemotePost.self, from: HTTPPayload(status: 200, data: Data("bad".utf8)))) {
            guard case APIError.decoding = $0 else { return XCTFail("Expected decoding error") }
        }
    }
    func testInvalidPOSTDoesNotSendRequest() async {
        let transport = StubTransport(json: post)
        do { _ = try await APIClient(transport: transport).createPost(title: " ", body: ""); XCTFail() }
        catch { XCTAssertTrue(error is NoteValidationError) }
        let requests = await transport.requests; XCTAssertTrue(requests.isEmpty)
    }
    @MainActor func testViewModelSuccessAndTransportError() async {
        let vm = PostsViewModel(service: APIClient(transport: StubTransport(json: "[" + post + "]")))
        await vm.load(); XCTAssertEqual(vm.posts.count, 1); XCTAssertFalse(vm.loading)
        let failed = PostsViewModel(service: APIClient(transport: BrokenTransport()))
        await failed.load(); XCTAssertNotNil(failed.errorMessage); XCTAssertFalse(failed.loading)
        await failed.send(title: "Title", body: "Body")
        XCTAssertNotNil(failed.errorMessage); XCTAssertFalse(failed.sending); XCTAssertNil(failed.receipt)
    }
}
