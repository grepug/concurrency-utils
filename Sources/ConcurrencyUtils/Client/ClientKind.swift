//
//  ClientKind.swift
//
//
//  Created by Kai Shao on 2024/7/16.
//

import Foundation

#if !os(Linux)
    import EventSource
#endif

public protocol ClientKind: Sendable {
    func data(for request: ClientRequest) async throws -> Data
    func stream(for request: ClientRequest) -> AsyncThrowingStream<String, Error>
    func shutdown() async throws
}

extension ClientKind {
    public func shutdown() async throws {}
}

#if !os(Linux)
    public struct URLSessionClient: ClientKind {
        public init() {}

        public func data(for request: ClientRequest) async throws -> Data {
            let urlRequest = request.urlRequest

            let (data, _) = try await URLSession.shared.data(for: urlRequest)

            return data
        }

        public func stream(for request: ClientRequest) -> AsyncThrowingStream<String, Error> {
            EventSourceClient(request: request.urlRequest).stream
        }
    }
#endif
