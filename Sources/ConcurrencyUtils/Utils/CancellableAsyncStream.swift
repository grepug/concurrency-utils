import Foundation

/// A utility class that provides methods to create AsyncThrowingStreams with automatic cancellation handling.
/// This eliminates the need to manually set up onTermination handlers for every stream.
public struct CancellableAsyncStream {

    /// Create a cancellable throwing stream with a processing task that will be automatically cancelled when the stream is terminated.
    /// - Parameters:
    ///   - bufferingPolicy: The buffering policy for the stream
    ///   - process: The closure that processes the stream
    ///   - onCancel: Optional closure that will be called when the stream is cancelled
    /// - Returns: An AsyncThrowingStream that will automatically cancel its processing task when terminated
    public static func makeThrowingStream<T>(
        bufferingPolicy: AsyncThrowingStream<T, Error>.Continuation.BufferingPolicy = .unbounded,
        _ process: @escaping (AsyncThrowingStream<T, Error>.Continuation) async throws -> Void,
        onCancel: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) -> AsyncThrowingStream<T, Error> {
        let (stream, continuation) = AsyncThrowingStream<T, Error>.makeStream(bufferingPolicy: bufferingPolicy)

        let processingTask = Task {
            do {
                try await process(continuation)
                continuation.finish()
            } catch {
                onError?(error)
                continuation.finish(throwing: error)
            }
        }

        continuation.onTermination = { reason in
            if case .cancelled = reason {
                processingTask.cancel()
                onCancel?()
            }
        }

        return stream
    }

    /// Create a cancellable stream with a processing task that will be automatically cancelled when the stream is terminated.
    /// - Parameters:
    ///   - bufferingPolicy: The buffering policy for the stream
    ///   - process: The closure that processes the stream
    ///   - onCancel: Optional closure that will be called when the stream is cancelled
    /// - Returns: An AsyncStream that will automatically cancel its processing task when terminated
    public static func makeStream<T>(
        bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .unbounded,
        _ process: @escaping (AsyncStream<T>.Continuation) async -> Void,
        onCancel: (() -> Void)? = nil
    ) -> AsyncStream<T> {
        let (stream, continuation) = AsyncStream<T>.makeStream(bufferingPolicy: bufferingPolicy)

        let processingTask = Task {
            await process(continuation)
            continuation.finish()
        }

        continuation.onTermination = { reason in
            if case .cancelled = reason {
                processingTask.cancel()
                onCancel?()
            }
        }

        return stream
    }
}

// Extension for AsyncThrowingStream to create a cancellable stream statically
extension AsyncThrowingStream where Failure == Error {
    /// Create a cancellable throwing stream with a processing task that will be automatically cancelled when the stream is terminated.
    /// - Parameters:
    ///   - bufferingPolicy: The buffering policy for the stream
    ///   - process: The closure that processes the stream
    ///   - onCancel: Optional closure that will be called when the stream is cancelled
    /// - Returns: An AsyncThrowingStream that will automatically cancel its processing task when terminated
    public static func makeCancellable(
        bufferingPolicy: Continuation.BufferingPolicy = .unbounded,
        _ process: @escaping (Continuation) async throws -> Void,
        onError: ((Error) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> AsyncThrowingStream<Element, Error> {
        return CancellableAsyncStream.makeThrowingStream(
            bufferingPolicy: bufferingPolicy,
            process,
            onCancel: onCancel,
            onError: onError
        )
    }
}

// Extension for AsyncStream to create a cancellable stream statically
extension AsyncStream {
    /// Create a cancellable stream with a processing task that will be automatically cancelled when the stream is terminated.
    /// - Parameters:
    ///   - bufferingPolicy: The buffering policy for the stream
    ///   - process: The closure that processes the stream
    ///   - onCancel: Optional closure that will be called when the stream is cancelled
    /// - Returns: An AsyncStream that will automatically cancel its processing task when terminated
    public static func makeCancellable(
        bufferingPolicy: Continuation.BufferingPolicy = .unbounded,
        _ process: @escaping (Continuation) async -> Void,
        onCancel: (() -> Void)? = nil
    ) -> AsyncStream<Element> {
        return CancellableAsyncStream.makeStream(
            bufferingPolicy: bufferingPolicy,
            process,
            onCancel: onCancel
        )
    }
}
