import EndpointBuilder
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPTypes

/// An API endpoint client that uses `URLSession` to create requests
public protocol EndpointBuilderURLSession: Sendable {

	/// The base server URL on which endpoint paths will be appended
	var serverBaseURL: URL { get }

	/// The URLSession object that will make requests
	var urlSession: @Sendable () -> URLRequestHandler { get }

	/// JSON encoder
	var encoder: @Sendable () -> JSONEncoder { get }

	/// JSON decoder
	var decoder: @Sendable () -> JSONDecoder { get }

}

// Default values
extension EndpointBuilderURLSession {

	public var urlSession: @Sendable () -> URLSession {
		{ URLSession.shared }
	}

	public var encoder: @Sendable () -> JSONEncoder {
		{
			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .iso8601
			return encoder
		}
	}

	public var decoder: @Sendable () -> JSONDecoder {
		{ 
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			return decoder
		}
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
		let (data, response) = try await requestData(endpoint)
		do {
			return try decoder().decode(E.responseType, from: data)
		} catch {
			throw EndpointBuilderError.unableToDeserialize(data: data, response: response)
		}
	}

	@discardableResult
	@usableFromInline
	func requestData<E: Endpoint>(_ endpoint: E) async throws -> (Data, URLResponse) {
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
		let (data, response) = try await urlSession().data(for: request)
		return (data, response)
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

public enum EndpointBuilderError: Error {
	case unableToDeserialize(data: Data, response: URLResponse)
}
