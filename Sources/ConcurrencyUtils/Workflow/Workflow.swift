//
//  Workflow.swift
//
//
//  Created by Kai Shao on 2024/7/16.
//

import Foundation

public protocol Workflow {
    associatedtype Input: Codable
    associatedtype Output
    associatedtype Stream: AsyncSequence where Stream.Element == Output
    
    var id: String { get }
    var input: Input { get }
    var url: URL { get }
    
    static var timeout: Duration { get }
    
    init(input: Input)
    
    func stream(session: UserSession, client: any ClientKind) -> Stream
    func request(session: UserSession, client: any ClientKind) async throws -> Output?
}

public extension Workflow {
    func stream(session: UserSession) -> Stream {
        stream(session: session, client: URLSessionClient())
    }
    
    func request(session: UserSession) async throws -> Output? {
        try await request(session: session, client: URLSessionClient())
    }
    
    var url: URL {
        .init(string: "functions/v1/dify")!
    }
    
    static var timeout: Duration {
        .seconds(60)
    }
    
    func request(session: UserSession, client: any ClientKind) async throws -> Output? {
        nil
    }
}

public extension Workflow {
    func clientRequest(session: UserSession, stream: Bool) -> ClientRequest {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let body = WorkflowRequestBody(id: id, userID: session.userID, inputs: input, stream: stream)
        let data = try! encoder.encode(body)
        
        return .init(url: url,
                     method: .post,
                     headers: [.authorization(bearer: session.accessToken)],
                     body: data)
    }
    
    func rawStream<Answer: Codable>(session: UserSession, client: some ClientKind, decoding: Answer.Type = String.self) -> AsyncThrowingStream<WithTimeoutAndRetryForStreamResult<WorkflowResponse<Answer>>, any Error> {
        let request = clientRequest(session: session, stream: true)
        
        return withTimeoutAndRetryForStream(maxRetries: 1, timeout: Self.timeout) {
            client.stream(for: request)
        } transform: { item in
            guard let data = item.data(using: .utf8) else {
                assertionFailure()
                return nil
            }
            
            guard let response = try? JSONDecoder().decode(WorkflowResponse<Answer>.self, from: data) else {
                assertionFailure()
                return nil
            }
            
            return response
        }
    }
    
    func rawBlockRequest<Answer: Codable>(session: UserSession, client: some ClientKind, decoding: Answer.Type = String.self) async throws -> WorkflowResponse<Answer> {
        let request = clientRequest(session: session, stream: true)
        
        let result = try await withTimeoutAndRetry(maxRetries: 1, timeout: Self.timeout) {
            let data = try await client.data(for: request)
            
            return try JSONDecoder().decode(WorkflowResponse<Answer>.self, from: data)
        }
        
        return result
    }
}
