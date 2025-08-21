//
//  ClientRequest.swift
//
//
//  Created by Kai Shao on 2024/7/16.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public struct ClientRequest: Sendable {
    public enum Method: String, Sendable {
        case post, get, delete, patch, put
    }

    public enum Header: Sendable {
        case authorization(bearer: String)
        case contentTypeJSON
        case multiparFormData(boundary: String)
        case custom(key: String, value: String)

        var dict: [String: String] {
            switch self {
            case .authorization(let bearer):
                return ["Authorization": "Bearer \(bearer)"]
            case .contentTypeJSON:
                return ["Content-Type": "application/json"]
            case .multiparFormData(let boundary):
                return ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
            case .custom(let key, let value):
                return [key: value]
            }
        }
    }

    public let url: URL
    public let method: Method
    public let headers: [String: String]
    public let body: Data?

    public init(url: URL, method: Method = .get, headers: [Header] = [], body: Data? = nil) {
        self.url = url
        self.method = method
        self.headers = headers.reduce([:], { $0.merging($1.dict, uniquingKeysWith: { a, b in a }) })
        self.body = body
    }

    public init(urlString: String, method: Method = .get, headers: [Header] = [], body: Data? = nil) {
        self.url = .init(string: urlString)!
        self.method = method
        self.headers = headers.reduce([:], { $0.merging($1.dict, uniquingKeysWith: { a, b in a }) })
        self.body = body
    }

    public init<T: Codable>(urlString: String, method: Method = .get, headers: [Header] = [], body: T?) {
        self.url = .init(string: urlString)!
        self.method = method
        self.headers = headers.reduce([:], { $0.merging($1.dict, uniquingKeysWith: { a, b in a }) })

        if let body, let data = try? JSONEncoder().encode(body) {
            self.body = data
        } else {
            self.body = nil
        }
    }

    public var urlRequest: URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue.uppercased()
        for (key, val) in headers {
            req.setValue(val, forHTTPHeaderField: key)
        }
        req.httpBody = body

        return req
    }
}
