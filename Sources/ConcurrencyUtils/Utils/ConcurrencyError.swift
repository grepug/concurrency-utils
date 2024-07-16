//
//  File.swift
//  
//
//  Created by Kai Shao on 2024/7/16.
//

import Foundation

public enum ConcurrencyError: Error, Codable, Hashable {
    case timeout, reachedMaxRetryCount
}
