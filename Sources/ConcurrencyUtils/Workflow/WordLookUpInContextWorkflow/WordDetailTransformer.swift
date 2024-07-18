//
//  WordDetailTransformer.swift
//
//
//  Created by Kai Shao on 2024/7/16.
//

import Foundation

public class WordDetailTransformer {
    private var hasReturnedSenseChunk = false
    private var accumutedString = ""

    let sep = "#;;;"

    public typealias Item = WordLookUpInContextWorkflow.Output

    public init() {}

    public func transformWordDetail(word: String, chunk: String) -> (item: Item, shouldTerminate: Bool)? {
        self.accumutedString += chunk

        // print("acc", accumutedString)

        let reg = #/(.*?)(\^\^|$)/#
        let match = accumutedString.firstMatch(of: reg)

        guard let substring = match?.output.1 else {
            return nil
        }

        // print("substring", substring)

        let item = String(substring)
            .split(separator: sep)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let pos = item.element(at: 0, defaultsTo: "")
        let lemma = item.element(at: 1, defaultsTo: "")
        let synonym = item.element(at: 2)
        let sense = handleMultipleLocales(item.element(at: 3) ?? "")
        let descString = item.element(at: 4, defaultsTo: "")

        if !self.hasReturnedSenseChunk && !descString.isEmpty {
            self.hasReturnedSenseChunk = true

            return (item: Item(word: word, pos: pos, lemma: lemma, synonym: synonym, sense: sense, desc: [:]), shouldTerminate: false)
        }

        if self.hasReturnedSenseChunk && !descString.isEmpty && self.accumutedString.contains("^^") {
            let desc = handleMultipleLocales(descString)

            assert(desc.isEmpty == false)

            let item = Item(word: word, pos: pos, lemma: lemma, synonym: synonym, sense: sense, desc: desc)

            return (item: item, shouldTerminate: true)
        }

        return nil
    }

    private func handleMultipleLocales(_ str: String) -> LocaledStringDict {
        let items = str.split(separator: "||").map { $0.trimmingCharacters(in: .whitespaces) }

        return items.reduce(into: [:]) { (acc, el) in
            guard let match = el.firstMatch(of: #/(.+?):\s?(.+?)$/#) else {
                return
            }

            let locale = CTLocale(rawValue: String(match.output.1))
            let content = String(match.output.2)

            if let locale {
                acc[locale] = content
            }
        }
    }
}

extension Array {
    func element(at index: Int) -> Element? {
        guard index >= 0 && index < self.count else {
            return nil
        }
        return self[index]
    }

    func element(at index: Int, defaultsTo: Element) -> Element {
        guard index >= 0 && index < self.count else {
            return defaultsTo
        }
        return self[index]
    }
}
