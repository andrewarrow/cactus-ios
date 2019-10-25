//
//  ApiTypes.swift
//  Cactus
//
//  Created by Neil Poulin on 10/24/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import Foundation

struct MagicLinkRequest: Codable {
    var email: String
    var continuePath: String
    var referredBy: String?
//    var reflectionResponseIds: String[]?
//    var queryParams: [String: String]
    
    init(email: String, continuePath: String, referredBy: String? = nil) {
        self.email = email
        self.continuePath = continuePath
        self.referredBy = referredBy
    }
}

struct MagicLinkResponse: Codable {
    var exists: Bool = false
    var success: Bool = false
    var email: String
    var error: String?
    var message: String?
    
    init(email: String, success: Bool, message: String? = nil) {
        self.email = email
        self.success = success
        self.message = message
    }
}