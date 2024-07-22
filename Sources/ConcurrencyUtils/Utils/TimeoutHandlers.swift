//
//  TimeoutHandlers.swift
//
//
//  Created by Kai Shao on 2024/7/16.
//

import Foundation

public enum WithTimeoutAndRetryForStreamResult<Value: Sendable & Codable>: Sendable, Codable {
    case value(Value), retry
}

public func withTimeoutThrowingHandler<T>(timeout: Duration, operation: @escaping @Sendable () async throws -> T) async rethrows -> T {
    try await withThrowingTaskGroup(of: T.self, returning: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try? await Task.sleep(for: timeout)
            throw ConcurrencyError.timeout
        }
        
        for try await result in group {
            group.cancelAll()
            return result
        }
        
        // cancel all on either of the tasks finishes
        group.cancelAll()
        throw ConcurrencyError.timeout
    }
}

public func withTimeoutAndRetryForStream<T, Result, S: AsyncSequence>(
    maxRetries: Int,
    timeout: Duration,
    delay: Duration = .seconds(2),
    streamProvider: @escaping () -> S,
    transform: @escaping (T) -> Result?
) -> AsyncThrowingStream<WithTimeoutAndRetryForStreamResult<Result>, any Error> where S.Element == T {
    return AsyncThrowingStream { continuation in
        let taskManager = ActorIsolated<Task<Void, Never>?>(nil)

        @Sendable func startStream(retryCount: Int = 0) {
            let task = Task {
                @Sendable func handleRetry() {
                    if retryCount < maxRetries {
                        Task {
                            try await Task.sleep(for: delay) // 2 seconds delay before retrying
                            await taskManager.value?.cancel()
                            continuation.yield(.retry)
                            startStream(retryCount: retryCount + 1)
                        }
                    } else {
                        continuation.finish(throwing: ConcurrencyError.reachedMaxRetryCount)
                    }
                }
                
                do {
                    try await withTimeoutThrowingHandler(timeout: timeout) {
                        for try await item in streamProvider() {
                            if let transformed = transform(item) {
                                continuation.yield(.value(transformed))
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    if let error = error as? ConcurrencyError, error == .timeout {
                        handleRetry()
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
            
            // Set the new task in the actor
            Task {
                await taskManager.setValue(task)
            }
        }

        startStream()

        continuation.onTermination = { _ in
            Task {
                await taskManager.value?.cancel()
            }
        }
    }
}

public func withTimeoutAndRetry<T>(
    maxRetries: Int = 3,
    timeout: Duration,
    delay: Duration = .seconds(2),
    task: @escaping @Sendable () async throws -> T
) async throws -> T {
    var currentRetry = 0

    while currentRetry <= maxRetries {
        do {
            return try await withTimeoutThrowingHandler(timeout: timeout) {
                try await task()
            }
        } catch {
            if let error = error as? ConcurrencyError, error == .timeout {
                currentRetry += 1
                if currentRetry > maxRetries {
                    throw ConcurrencyError.reachedMaxRetryCount
                } else {
                    try await Task.sleep(for: delay) // 2 seconds delay before retrying
                }
            } else {
                throw error
            }
        }
    }
    
    throw ConcurrencyError.reachedMaxRetryCount
}
