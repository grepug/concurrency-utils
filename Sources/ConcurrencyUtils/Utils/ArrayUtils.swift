public extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    func asyncReduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: (_ partialResult: Result, _ item: Element) async throws -> Result
    ) async rethrows -> Result {
        var result = initialResult

        for element in self {
            result = try await nextPartialResult(result, element)
        }

        return result
    }

    func asyncReduce<Result>(
        into initialResult: Result,
        _ updateAccumulatingResult: (_ partialResult: inout Result, _ item: Element) async throws -> ()
    ) async rethrows -> Result {
        var result = initialResult

        for element in self {
            try await updateAccumulatingResult(&result, element)
        }

        return result
    }
}

public extension Sequence where Element: Sendable {
    func concurrentMap<T>(
        _ transform: @Sendable @escaping (Element) async throws -> T
    ) async throws -> [T] where T: Sendable {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }

        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}