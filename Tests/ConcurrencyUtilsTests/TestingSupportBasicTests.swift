import Testing
@testable import ConcurrencyUtils
import ConcurrencyUtilsTestingSupport
import Foundation

@Suite("TestingSupport Basic Tests")
struct TestingSupportBasicTests {
    
    @Test("MockClient can be created with default values")
    func mockClientCreation() {
        let mockClient = MockClientService()
        #expect(!mockClient.shouldFail)
        #expect(!mockClient.shouldFailOnShutdown)
        #expect(mockClient.streamChunks.count == 2)
        #expect(mockClient.data == nil)
        #expect(mockClient.delay == nil)
    }
    
    @Test("MockClient can be configured with custom values")
    func mockClientConfiguration() {
        let customChunks = ["Custom", "Test", "Chunks"]
        let customData = Data("Custom test data".utf8)
        let customDelay: TimeInterval = 0.5
        
        let mockClient = MockClientService(
            shouldFail: true,
            data: customData,
            streamChunks: customChunks,
            shouldFailOnShutdown: true,
            delay: customDelay
        )
        
        #expect(mockClient.shouldFail)
        #expect(mockClient.shouldFailOnShutdown)
        #expect(mockClient.streamChunks == customChunks)
        #expect(mockClient.data == customData)
        #expect(mockClient.delay == customDelay)
    }
    
    @Test("MockClientError cases are distinct")
    func mockClientErrorDistinction() {
        let networkError = MockClientError.networkError
        let streamError = MockClientError.streamError
        let shutdownError = MockClientError.shutdownError
        
        #expect(networkError == MockClientError.networkError)
        #expect(streamError == MockClientError.streamError)
        #expect(shutdownError == MockClientError.shutdownError)
        
        #expect(networkError != streamError)
        #expect(streamError != shutdownError)
        #expect(networkError != shutdownError)
    }
    
    @Test("ClientRequest initializes correctly with basic parameters")
    func clientRequestBasicInit() {
        let url = URL(string: "https://example.com")!
        let request = ClientRequest(url: url, body: nil)
        
        #expect(request.url == url)
        #expect(request.method == .get)
        #expect(request.headers.isEmpty)
        #expect(request.body == nil)
    }
    
    @Test("ClientRequest supports different HTTP methods")
    func clientRequestMethods() {
        let url = URL(string: "https://example.com")!
        
        let getRequest = ClientRequest(url: url, method: .get, body: nil)
        #expect(getRequest.method == .get)
        
        let postRequest = ClientRequest(url: url, method: .post, body: nil)
        #expect(postRequest.method == .post)
        
        let putRequest = ClientRequest(url: url, method: .put, body: nil)
        #expect(putRequest.method == .put)
        
        let deleteRequest = ClientRequest(url: url, method: .delete, body: nil)
        #expect(deleteRequest.method == .delete)
        
        let patchRequest = ClientRequest(url: url, method: .patch, body: nil)
        #expect(patchRequest.method == .patch)
    }
    
    @Test("ClientRequest handles headers correctly")
    func clientRequestHeaders() {
        let url = URL(string: "https://example.com")!
        let request = ClientRequest(
            url: url,
            headers: [.contentTypeJSON, .authorization(bearer: "test-token")],
            body: nil
        )
        
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.headers["Authorization"] == "Bearer test-token")
    }
    
    @Test("ClientRequest string URL convenience initializer works")
    func clientRequestStringURL() {
        let urlString = "https://api.example.com/endpoint"
        let request = ClientRequest(urlString: urlString, body: nil)
        
        #expect(request.url.absoluteString == urlString)
    }
}
