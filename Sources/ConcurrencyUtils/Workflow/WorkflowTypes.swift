//
//  WorkflowTypes.swift
//
//
//  Created by Kai Shao on 2024/7/16.
//

import Foundation

public struct WorkflowRequestBody<Input: Codable>: Codable {
    var id: String
    var userID: String
    var inputs: Input
    var stream: Bool
}

public struct WorkflowResponse<Answer: Codable>: Codable {
    let message_id: String?
    let answer: Answer?
}
