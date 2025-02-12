public func withCleanup<T>(handler: @escaping () async throws -> T, cleanup: @escaping () async -> Void) async throws -> T {
    do {
        let result = try await handler()
        await cleanup()
        return result
    } catch {
        await cleanup()
        throw error
    }
}