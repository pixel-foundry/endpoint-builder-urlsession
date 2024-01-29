import EndpointBuilder
import EndpointBuilderURLSession
import HTTPTypes
import RoutingKit
import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct MockURLSession: URLRequestHandler {

	let requestHandler: @Sendable (URLRequest) -> Data

	func data(for request: URLRequest) async throws -> (Data, URLResponse) {
		let data = requestHandler(request)
		return (
			data,
			URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
		)
	}

}

final class EndpointBuilderURLSessionTests: XCTestCase {

	@Endpoint
	struct EndpointWithNoResponse {
		static let path: [PathComponent] = ["blank"]
		static let httpMethod = HTTPRequest.Method.get
	}

	@Endpoint
	struct EndpointWithStringResponseAndPathComponent {
		static let path: [PathComponent] = ["echo", ":id"]
		static let httpMethod = HTTPRequest.Method.post
		static let responseType = String.self
		let body: String
	}

	struct APIClient: EndpointBuilderURLSession {

		let serverBaseURL = URL(string: "https://api.shipyard.studio")!
		let urlSession: @Sendable () -> URLRequestHandler

		init(mockSession: MockURLSession) {
			let session: @Sendable () -> URLRequestHandler = { mockSession }
			self.urlSession = session
		}

	}

	func testEndpointWithNoResponse() async throws {
		let endpoint = EndpointWithNoResponse()
		let client = APIClient(mockSession: MockURLSession(requestHandler: { urlRequest in
			XCTAssertEqual(urlRequest.url?.pathComponents, ["/", "blank"])
			XCTAssertEqual(urlRequest.httpMethod, "GET")
			return Data()
		}))
		try await client.request(endpoint)
	}

	func testEndpointWithStringResponse() async throws {
		let endpoint = EndpointWithStringResponseAndPathComponent(
			body: "hello",
			pathParameters: EndpointWithStringResponseAndPathComponent.PathParameters(id: "my-ids")
		)
		let client = APIClient(mockSession: MockURLSession(requestHandler: { urlRequest in
			XCTAssertEqual(urlRequest.url?.pathComponents, ["/", "echo", "my-ids"])
			XCTAssertEqual(urlRequest.httpMethod, "POST")
			XCTAssertEqual(urlRequest.httpBody, try? JSONEncoder().encode("hello"))
			return (try? JSONEncoder().encode("world")) ?? Data()
		}))
		let response = try await client.request(endpoint)
		XCTAssertEqual(response, "world")
	}

}
