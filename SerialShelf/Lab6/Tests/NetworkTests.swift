import XCTest
@testable import SerialShelf

private actor StubTransport: HTTPTransport {
    let payload: HTTPPayload
    private(set) var requests: [URLRequest] = []
    init(status: Int = 200, json: String) { payload = HTTPPayload(status: status, data: Data(json.utf8)) }
    func send(_ request: URLRequest) async throws -> HTTPPayload { requests.append(request); return payload }
}

final class NetworkTests: XCTestCase {
    let remote = #"{"id":1,"name":"Swift","url":"https://www.tvmaze.com/shows/1","premiered":"2020-01-01","genres":["Drama"],"summary":"<p>Story</p>","runtime":45,"averageRuntime":null,"rating":{"average":8},"image":null}"#

    func testGETSearchDecodesAndBuildsQuery() async throws {
        let stub = StubTransport(json: "[{\"show\":" + remote + "}]")
        let shows = try await CatalogAPI(transport: stub).shows(query: " Swift ")
        XCTAssertEqual(shows.first?.summary, "Story")
        XCTAssertEqual(shows.first?.year, "2020")
        let requests = await stub.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/search/shows")
        XCTAssertTrue(request.url?.query?.contains("q=Swift") == true)
    }
    func testPOSTEncodesReviewAndParsesReceipt() async throws {
        let stub = StubTransport(status: 201, json: #"{"id":101,"title":"Swift","body":"Great","userId":1}"#)
        let show = Show(id: 1, name: "Swift", year: "2020", genres: [], summary: "", runtime: 45,
            rating: nil, imageURL: nil, sourceURL: "https://www.tvmaze.com")
        let result = try await CatalogAPI(transport: stub).sendReview(show: show, text: " Great ")
        XCTAssertEqual(result.id, 101)
        let requests = await stub.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["body"] as? String, "Great")
    }
    func testHTTPDataAndJSONErrorsAreDistinct() {
        XCTAssertThrowsError(try ResponseParser.decode([RemoteShow].self, from: HTTPPayload(status: 404, data: Data()))) {
            guard case APIError.http(404) = $0 else { return XCTFail("Expected HTTP 404") }
        }
        XCTAssertThrowsError(try ResponseParser.decode([RemoteShow].self, from: HTTPPayload(status: 200, data: Data()))) {
            guard case APIError.emptyData = $0 else { return XCTFail("Expected empty data") }
        }
        XCTAssertThrowsError(try ResponseParser.decode([RemoteShow].self, from: HTTPPayload(status: 200, data: Data("bad".utf8)))) {
            guard case APIError.decoding = $0 else { return XCTFail("Expected decoding error") }
        }
    }
}
