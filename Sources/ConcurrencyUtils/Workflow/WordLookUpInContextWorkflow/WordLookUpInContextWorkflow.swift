//
//  WordLookUpInContextWorkflow.swift
//
//
//  Created by Kai Shao on 2024/7/16.
//

import Foundation
import AsyncAlgorithms

public struct WordLookUpInContextWorkflow: Workflow {
    public var id: String {
        "wordLookUpInContext"
    }
    
    public var url: URL {
        .init(string: "https://visdify.zeabur.app/v1/completion-messages")!
    }
    
    public static var timeout: Duration {
        .seconds(15)
    }
    
    public struct Input: Codable {
        var text: String
        var langs: String
        var word: String
        var adja: String
        
        public init(text: String, langs: [CTLocale] = [.en, .zh_Hans], word: String, adja: String) {
            self.text = text
            self.langs = langs.map(\.rawValue).joined(separator: ",")
            self.word = word
            self.adja = adja
        }
    }
    
    public struct Output: Codable, Identifiable, Hashable, Sendable {
        public var word: String
        public var pos: String
        public var synonym: String?
        public var lemma: String
        public var sense: LocaledStringDict
        public var desc: LocaledStringDict
        
        public var id: String {
            word + pos
        }
        
        public init(word: String = "", pos: String = "", lemma: String = "", synonym: String? = nil, sense: LocaledStringDict = [:], desc: LocaledStringDict = [:]) {
            self.word = word
            self.pos = pos
            self.lemma = lemma
            self.synonym = synonym
            self.sense = sense
            self.desc = desc
        }
        
        public init(word: String, pos: String, lemma: String, synonym: String?, sense: String, desc: String) {
            self.word = word
            self.pos = pos
            self.lemma = lemma
            self.synonym = synonym
            self.sense = [.en: sense]
            self.desc = [.en: desc]
        }
    }
    
    public var input: Input
    
    public init(input: Input) {
        self.input = input
    }
    
    public func request(session: UserSession, client: any ClientKind) async throws -> Output? {
        try await rawBlockRequest(session: session, client: client, decoding: Output.self).answer
    }
    
    public func stream(session: UserSession, client: any ClientKind) -> AsyncThrowingStream<Output, Error> {
        let transformer = WordDetailTransformer()
        let stream = rawStream(session: session, client: client)
        
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await result in stream {
                        switch result {
                        case .retry:
                            continuation.yield(.init())
                        case .value(let response):
                            if let answer = response.answer {
                                if let (item, shouldTermintate) = transformer.transformWordDetail(word: input.word, chunk: answer) {
                                    if shouldTermintate {
                                        continuation.finish()
                                    } else {
                                        continuation.yield(item)
                                    }
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

public enum CTLocale: String, Codable, CodingKeyRepresentable {
    case en, zh_Hans = "zh-Hans", zh_Hant = "zh-Hant", ja, fr
}

public typealias LocaledStringDict = [CTLocale: String]
