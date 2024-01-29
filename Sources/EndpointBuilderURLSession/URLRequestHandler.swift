import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol URLRequestHandler: Sendable {

	func data(for request: URLRequest) async throws -> (Data, URLResponse)

}

extension URLSession: URLRequestHandler {}

#if canImport(FoundationNetworking)
enum URLRequestHandlerError: Error {
	case noResponse
}

extension URLSession {

	public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
		try await withCheckedThrowingContinuation { continuation in
			self.dataTask(with: request) { data, response, error in
				guard let data = data, let response = response else {
					continuation.resume(throwing: error ?? URLRequestHandlerError.noResponse)
					return
				}
				continuation.resume(returning: (data, response))
			}.resume()
		}
	}

}
#endif
