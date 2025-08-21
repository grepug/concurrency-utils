import Testing
@testable import ConcurrencyUtils
import ConcurrencyUtilsTestingSupport
import Foundation

@Suite("ConcurrencyUtils Swift Testing Suite")
struct SwiftTestingTests {
    
    // MARK: - MockClient Tests
    
    @Test("MockClient data request succeeds")
    func mockClientDataSuccess() async throws {
        let mockData = Data("Test response".utf8)
        let mockClient = MockClientService(data: mockData)
        let request = ClientRequest(urlString: "https://example.com", body: nil)
        
        let result = try await mockClient.data(for: request)
        #expect(result == mockData)
    }
    
    @Test("MockClient data request fails when configured to fail")
    func mockClientDataFailure() async throws {
        let mockClient = MockClientService(shouldFail: true)
        let request = ClientRequest(urlString: "https://example.com", body: nil)
        
        await #expect(throws: MockClientError.networkError) {
            try await mockClient.data(for: request)
        }
    }
    
    @Test("MockClient data request respects delay")
    func mockClientDataWithDelay() async throws {
        let startTime = Date()
        let delayTime: TimeInterval = 0.1
        let mockClient = MockClientService(delay: delayTime)
        let request = ClientRequest(urlString: "https://example.com", body: nil)
        
        _ = try await mockClient.data(for: request)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        #expect(elapsedTime >= delayTime)
    }
    
    @Test("MockClient stream succeeds with expected chunks")
    func mockClientStreamSuccess() async throws {
        let expectedChunks = ["Chunk 1", "Chunk 2", "Chunk 3"]
        let mockClient = MockClientService(streamChunks: expectedChunks)
        let request = ClientRequest(urlString: "https://example.com", body: nil)
        
        let stream = mockClient.stream(for: request)
        var receivedChunks: [String] = []
        
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        #expect(receivedChunks == expectedChunks)
    }
    
    @Test("MockClient stream fails when configured to fail")
    func mockClientStreamFailure() async throws {
        let mockClient = MockClientService(shouldFail: true)
        let request = ClientRequest(urlString: "https://example.com", body: nil)
        
        let stream = mockClient.stream(for: request)
        
        await #expect(throws: MockClientError.streamError) {
            for try await _ in stream {
                // Should not receive any chunks
            }
        }
    }
    
    @Test("MockClient shutdown succeeds by default")
    func mockClientShutdownSuccess() async throws {
        let mockClient = MockClientService()
        
        try await mockClient.shutdown()
        // Should complete without throwing
    }
    
    @Test("MockClient shutdown fails when configured to fail")
    func mockClientShutdownFailure() async throws {
        let mockClient = MockClientService(shouldFailOnShutdown: true)
        
        await #expect(throws: MockClientError.shutdownError) {
            try await mockClient.shutdown()
        }
    }
    
    // MARK: - ClientRequest Tests
    
    @Test("ClientRequest initializes with all parameters correctly")
    func clientRequestInitialization() {
        let url = URL(string: "https://api.example.com/test")!
        let body = Data("test body".utf8)
        
        let request = ClientRequest(
            url: url,
            method: .post,
            headers: [.contentTypeJSON, .authorization(bearer: "test-token")],
            body: body
        )
        
        #expect(request.url == url)
        #expect(request.method == .post)
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.headers["Authorization"] == "Bearer test-token")
        #expect(request.body == body)
    }
    
    @Test("ClientRequest initializes with string URL")
    func clientRequestWithStringURL() {
        let urlString = "https://api.example.com/test"
        let request = ClientRequest(urlString: urlString, method: .get, body: nil)
        
        #expect(request.url.absoluteString == urlString)
        #expect(request.method == .get)
    }
    
    @Test("ClientRequest encodes Codable body correctly")
    func clientRequestWithCodableBody() throws {
        struct TestBody: Codable, Equatable {
            let name: String
            let value: Int
        }
        
        let testBody = TestBody(name: "test", value: 42)
        let request = ClientRequest(
            urlString: "https://api.example.com/test",
            method: .post,
            body: testBody
        )
        
        #expect(request.body != nil)
        
        // Verify the body can be decoded back
        let decoder = JSONDecoder()
        let decodedBody = try decoder.decode(TestBody.self, from: request.body!)
        #expect(decodedBody == testBody)
    }
    
    @Test("ClientRequest creates URLRequest correctly")
    func clientRequestURLRequest() {
        let request = ClientRequest(
            urlString: "https://api.example.com/test",
            method: .post,
            headers: [.contentTypeJSON],
            body: Data("test".utf8)
        )
        
        let urlRequest = request.urlRequest
        #expect(urlRequest.url?.absoluteString == "https://api.example.com/test")
        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest.httpBody == Data("test".utf8))
    }
    
    // MARK: - Integration Tests with MockClient
    
    @Test("Workflow integration with MockClient")
    func workflowIntegrationWithMockClient() async throws {
        struct TestWorkflowInput: Codable, Equatable {
            let query: String
        }
        
        let input = TestWorkflowInput(query: "test query")
        let encoder = JSONEncoder()
        let inputData = try encoder.encode(input)
        
        let mockClient = MockClientService(data: inputData)
        let request = ClientRequest(urlString: "https://api.example.com/workflow", body: nil)
        
        let result = try await mockClient.data(for: request)
        let decodedInput = try JSONDecoder().decode(TestWorkflowInput.self, from: result)
        
        #expect(decodedInput == input)
    }
    
    @Test("Concurrent MockClient requests execute efficiently")
    func concurrentMockClientRequests() async throws {
        let mockClient = MockClientService(delay: 0.1)
        let requests = (1...5).map { i in
            ClientRequest(urlString: "https://api.example.com/test/\(i)", body: nil)
        }
        
        let startTime = Date()
        
        // Execute requests concurrently
        let results = try await withThrowingTaskGroup(of: Data.self) { group in
            for request in requests {
                group.addTask {
                    try await mockClient.data(for: request)
                }
            }
            
            var results: [Data] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(results.count == 5)
        // Should take roughly 0.1 seconds (not 0.5) due to concurrency
        #expect(elapsedTime < 0.3)
    }
    
    @Test("MockClientError types are equatable")
    func mockClientErrorTypes() {
        #expect(MockClientError.networkError == MockClientError.networkError)
        #expect(MockClientError.streamError == MockClientError.streamError)
        #expect(MockClientError.shutdownError == MockClientError.shutdownError)
        
        #expect(MockClientError.networkError != MockClientError.streamError)
        #expect(MockClientError.streamError != MockClientError.shutdownError)
    }
    
    // MARK: - Stream Processing Tests
    
    @Test("MockClient stream processes chunks in order")
    func streamProcessingOrder() async throws {
        let chunks = ["First", "Second", "Third", "Fourth", "Fifth"]
        let mockClient = MockClientService(streamChunks: chunks)
        let request = ClientRequest(urlString: "https://example.com/stream", body: nil)
        
        let stream = mockClient.stream(for: request)
        var receivedChunks: [String] = []
        
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        #expect(receivedChunks == chunks)
        
        // Verify order is maintained
        for (index, chunk) in receivedChunks.enumerated() {
            #expect(chunk == chunks[index])
        }
    }
    
    @Test("MockClient stream with delay respects timing")
    func streamWithDelay() async throws {
        let chunks = ["Delayed chunk 1", "Delayed chunk 2"]
        let delay: TimeInterval = 0.05
        let mockClient = MockClientService(streamChunks: chunks, delay: delay)
        let request = ClientRequest(urlString: "https://example.com/stream", body: nil)
        
        let startTime = Date()
        let stream = mockClient.stream(for: request)
        var receivedChunks: [String] = []
        
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(receivedChunks == chunks)
        #expect(elapsedTime >= delay)
    }
    
    // MARK: - Parameterized Tests
    
    @Test("MockClient handles different delay values", 
          arguments: [0.0, 0.05, 0.1, 0.2])
    func mockClientDelayValues(delay: TimeInterval) async throws {
        let mockClient = MockClientService(delay: delay)
        let request = ClientRequest(urlString: "https://example.com/delay", body: nil)
        
        let startTime = Date()
        _ = try await mockClient.data(for: request)
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        if delay > 0 {
            #expect(elapsedTime >= delay)
        }
    }
    
    @Test("MockClient handles different chunk counts",
          arguments: [[], ["single"], ["first", "second"], ["one", "two", "three", "four"]])
    func mockClientChunkCounts(chunks: [String]) async throws {
        let mockClient = MockClientService(streamChunks: chunks)
        let request = ClientRequest(urlString: "https://example.com/chunks", body: nil)
        
        let stream = mockClient.stream(for: request)
        var receivedChunks: [String] = []
        
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        #expect(receivedChunks == chunks)
        #expect(receivedChunks.count == chunks.count)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("MockClient handles multiple error scenarios", 
          arguments: [
            (true, false, false),
            (false, true, false),
            (false, false, true)
          ])
    func errorHandlingScenarios(shouldFail: Bool, shouldFailStream: Bool, shouldFailOnShutdown: Bool) async throws {
        let mockClient = MockClientService(
            shouldFail: shouldFail || shouldFailStream,
            shouldFailOnShutdown: shouldFailOnShutdown
        )
        let request = ClientRequest(urlString: "https://example.com", body: nil)
        
        if shouldFail {
            await #expect(throws: MockClientError.networkError) {
                _ = try await mockClient.data(for: request)
            }
        }
        
        if shouldFailStream {
            let stream = mockClient.stream(for: request)
            await #expect(throws: MockClientError.streamError) {
                for try await _ in stream {
                    // Should not receive any chunks
                }
            }
        }
        
        if shouldFailOnShutdown {
            await #expect(throws: MockClientError.shutdownError) {
                try await mockClient.shutdown()
            }
        }
    }
    
    // MARK: - HTTP Method Tests
    
    @Test("ClientRequest supports all HTTP methods",
          arguments: ClientRequest.Method.allCases)
    func httpMethodSupport(method: ClientRequest.Method) {
        let request = ClientRequest(
            urlString: "https://example.com/test",
            method: method,
            body: nil
        )
        
        #expect(request.method == method)
        
        let urlRequest = request.urlRequest
        #expect(urlRequest.httpMethod?.lowercased() == method.rawValue.lowercased())
    }
}

// Extension to make Method conform to CaseIterable for parameterized tests
extension ClientRequest.Method: CaseIterable {
    public static var allCases: [ClientRequest.Method] {
        [.get, .post, .put, .patch, .delete]
    }
}
