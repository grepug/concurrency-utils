import ConcurrencyUtils
import Foundation

public struct MockClientService: ClientKind {
    public var shouldFail: Bool
    public var data: Data?
    public var streamChunks: [String]
    public var shouldFailOnShutdown: Bool
    public var delay: TimeInterval?

    public init(
        shouldFail: Bool = false,
        data: Data? = nil,
        streamChunks: [String] = ["Mock stream chunk 1", "Mock stream chunk 2"],
        shouldFailOnShutdown: Bool = false,
        delay: TimeInterval? = nil
    ) {
        self.shouldFail = shouldFail
        self.data = data
        self.streamChunks = streamChunks
        self.shouldFailOnShutdown = shouldFailOnShutdown
        self.delay = delay
    }

    public func data(for request: ClientRequest) async throws -> Data {
        if let delay = delay {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldFail {
            throw MockClientError.networkError
        }

        return data ?? Data("Mock response data".utf8)
    }

    public func stream(for request: ClientRequest) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                if let delay {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }

                if shouldFail {
                    continuation.finish(throwing: MockClientError.streamError)
                    return
                }

                for chunk in streamChunks {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
        }
    }

    public func shutdown() async throws {
        if shouldFailOnShutdown {
            throw MockClientError.shutdownError
        }
    }
}

public enum MockClientError: Error, Equatable {
    case networkError
    case streamError
    case shutdownError
}
