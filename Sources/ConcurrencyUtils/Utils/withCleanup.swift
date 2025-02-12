public func withCleanup<T>(handler: @escaping () async throws -> T, cleanup: @escaping () async -> Void, mapError: ((Error) -> Error)? = nil) async throws -> T {
    do {
        let result = try await handler()
        await cleanup()
        return result
    } catch {
        await cleanup()

        if let mapError {
            throw mapError(error)
        }

        throw error
    }
}