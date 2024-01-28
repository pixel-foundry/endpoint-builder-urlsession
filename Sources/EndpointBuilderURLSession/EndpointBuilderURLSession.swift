import EndpointBuilder
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPTypes

/// An API endpoint client that uses `URLSession` to create requests
public struct EndpointBuilderURLSession: Sendable {

	/// The base server URL on which endpoint paths will be appended
	public let serverBaseURL: URL

	/// The URLSession object that will make requests
	public let urlSession: @Sendable () -> URLSession

	/// JSON encoder
	public let encoder: @Sendable () -> JSONEncoder

	/// JSON decoder
	public let decoder: @Sendable () -> JSONDecoder

	/// Creates a new `EndpointBuilderURLSession`.
	public init(
		serverBaseURL: URL,
		urlSession: @Sendable @escaping () -> URLSession = { URLSession.shared },
		encoder: @Sendable @escaping () -> JSONEncoder = { JSONEncoder() },
		decoder: @Sendable @escaping () -> JSONDecoder = { JSONDecoder() }
	) {
		self.serverBaseURL = serverBaseURL
		self.urlSession = urlSession
		self.encoder = encoder
		self.decoder = decoder
	}

}

extension EndpointBuilderURLSession {

	/// A request with no response body
	@inlinable
	public func request<E: Endpoint>(_ endpoint: E) async throws where E.Response == Never {
		try await requestData(endpoint)
	}

	/// A request with a response body
	@inlinable
	public func request<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
		let data = try await requestData(endpoint)
		return try decoder().decode(E.responseType, from: data)
	}

	@discardableResult
	@usableFromInline
	func requestData<E: Endpoint>(_ endpoint: E) async throws -> Data {
		// construct URL
		let url: URL = serverBaseURL.appendingPath(endpoint.path)

		// construct request
		var request = URLRequest(url: url)
		request.httpMethod = E.httpMethod.rawValue

		if E.BodyContent.self != Never.self {
			request.setValue("application/json", forHTTPHeaderField: HTTPField.Name.contentType.rawName)
			request.httpBody = try encoder().encode(endpoint.body)
		}

		if let authorization = endpoint.authorization {
			request.setValue(authorization.headerValue, forHTTPHeaderField: HTTPField.Name.authorization.rawName)
		}

		// perform request
		return try await urlSession().responseData(for: request)
	}

}

extension URL {

	func appendingPath(_ path: String) -> URL {
		#if canImport(FoundationNetworking)
		return self.appendingPathComponent(path)
		#else
		if #available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *) {
			return self.appending(path: path)
		} else {
			return self.appendingPathComponent(path)
		}
		#endif
	}

}

extension URLSession {

	func responseData(for request: URLRequest) async throws -> Data {
		#if canImport(FoundationNetworking)
		await withCheckedContinuation { continuation in
			self.dataTask(with: request) { data, _, _ in
				guard let data = data else {
					continuation.resume(returning: Data())
					return
				}
				continuation.resume(returning: data)
			}.resume()
		}
		#else
		let (data, _) = try await self.data(for: request)
		return data
		#endif
	}

}
