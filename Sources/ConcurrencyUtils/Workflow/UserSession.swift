//
//  UserSession.swift
//
//
//  Created by Kai Shao on 2024/7/15.
//

import Foundation

public struct UserSession {
    let accessToken: String
    let userID: String
    
    public init(accessToken: String = "", userID: String = "testing") {
        self.accessToken = accessToken
        self.userID = userID
    }
}
