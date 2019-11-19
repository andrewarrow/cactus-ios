//
//  LinkHandlerUtil.swift
//  Cactus
//
//  Created by Neil Poulin on 11/14/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import Foundation

protocol HandleLinkResponse {
    var handled: Bool {get}
}

struct PromptContentHandler: HandleLinkResponse {
    let handled: Bool
    var promptContentEntryId: String?
    
    init(handled: Bool) {
        self.handled = handled
    }
}

class LinkHandlerUtil {
    static func getPath(_ link: String) -> String? {
        guard let url = URL(string: link) else {
            return nil
        }
        
        return url.path
    }
    
    static func getPathId(_ link: String, for name: String) -> String? {
        guard let url = URL(string: link) else {
            return nil
        }
       
        return LinkHandlerUtil.getPathId(url, for: name)
    }
    
    static func getPathId(_ url: URL, for name: String) -> String? {
       let parts = url.pathComponents
       guard let nameIndex = parts.firstIndex(of: name), parts.endIndex > nameIndex + 1 else {
           return nil
       }
       
       return  parts[nameIndex + 1]
   }
    
    static func handlePromptContent(_ url: URL) -> Bool {
        let entryId = LinkHandlerUtil.getPathId(url, for: "prompts")
        
        if let entryId = entryId {
            AppDelegate.shared.rootViewController.loadPromptContent(promptContentEntryId: entryId, link: url.absoluteString)
            return true
        }
        
        return false
    }
    
    static func handleSharedResponse(_ url: URL) -> Bool {
        if let responseId = LinkHandlerUtil.getPathId(url, for: "reflection") {
            AppDelegate.shared.rootViewController.loadSharedReflection(reflectionId: responseId, link: url.absoluteString)
            return true
        }
        return false
        
    }
}