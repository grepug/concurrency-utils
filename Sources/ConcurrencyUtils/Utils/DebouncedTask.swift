//
//  DebouncedTask.swift
//  ContextApp
//
//  Created by Kai Shao on 2025/6/13.
//

import Foundation

/// `DebouncedTask` provides a way to debounce asynchronous operations.
///
/// It ensures that an operation is only executed after a specified delay has passed
/// since the last call, cancelling any pending operations. This is useful for
/// operations that should not be executed too frequently, such as network requests
/// triggered by user input.
///
/// Note: This class should not be instantiated directly.
/// Use the `withDebouncedTask` function instead.
///
/// Example usage:
/// ```swift
/// let searchTask = withDebouncedTask(debounceFor: 0.5) {
///    try await searchService.performSearch(query: query)
/// }
///
/// // Each call will cancel the previous one and only execute after 0.5 seconds
/// try await searchTask.call()
/// ```
public class DebouncedTask<T> {
    // MARK: - Properties

    /// The operation to be executed when the debounce period completes
    let operation: () async throws -> T

    /// Optional debounce interval in seconds
    /// If nil, the operation will execute immediately without delay
    let debounce: TimeInterval?

    /// The current task that will execute the operation
    private var task: Task<T, Error>?

    // MARK: - Lifecycle

    /// Creates a new debounced task
    ///
    /// - Parameters:
    ///   - debounce: Time interval to wait before executing the operation (in seconds)
    ///   - operation: The closure to execute after the debounce period
    init(debounce: TimeInterval? = nil, operation: @escaping () async throws -> T) {
        self.operation = operation
        self.debounce = debounce
    }

    // MARK: - Public Methods

    /// Calls the debounced operation
    ///
    /// - Returns: The result of the operation, or nil if the operation was cancelled
    /// - Throws: Any error thrown by the operation
    @discardableResult
    public func call() async throws -> T? {
        try await callImpl()
    }

    /// Cancels any pending operation
    public func cancel() {
        task?.cancel()
    }

    // MARK: - Private Methods

    /// Implementation of the debounced call
    ///
    /// - Returns: The result of the operation, or nil if the operation was cancelled
    /// - Throws: Any error thrown by the operation except for CancellationError
    private func callImpl() async throws -> T? {
        // Cancel previous task if it exists
        task?.cancel()

        // Create a new task for this operation
        task = Task {
            // Wait for the debounce period if specified
            if let debounce {
                try await Task.sleep(for: .seconds(debounce))
            }

            // Execute the operation
            return try await operation()
        }

        do {
            return try await task!.value
        } catch is CancellationError {
            // Ignore cancellation errors as they are expected
            // when debouncing multiple calls
        } catch {
            // Forward any other errors to the caller
            throw error
        }

        return nil
    }
}

/// Creates and returns a debounced task with the specified parameters
///
/// This is the recommended way to create a `DebouncedTask` instance.
///
/// - Parameters:
///   - debounce: Time interval to wait before executing the operation (in seconds)
///   - operation: The closure to execute after the debounce period
/// - Returns: A configured `DebouncedTask` instance
public func withDebouncedTask<T>(
    debounceFor debounce: TimeInterval? = nil,
    operation: @escaping () async throws -> T
) -> DebouncedTask<T> {
    return DebouncedTask(debounce: debounce, operation: operation)
}
