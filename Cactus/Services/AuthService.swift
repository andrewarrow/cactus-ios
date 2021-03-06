//
//  UserService.swift
//  Cactus
//
//  Created by Neil Poulin on 7/25/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import Foundation
import FirebaseAuth

class AuthService {
    
    static let sharedInstance = AuthService()
    let firestore: FirestoreService
    let logger = Logger("AuthService")
    var listenerQueue: [(Auth, User?) -> Void] = []
    var initFinished = false
    
    private init() {
        self.firestore = FirestoreService.sharedInstance
    }
    
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    func getAuthStateChangeHandler(completion: @escaping (Auth, User?) -> Void) -> AuthStateDidChangeListenerHandle {
        let handle = Auth.auth().addStateDidChangeListener(completion)
        return handle
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.logger.error("Failed to sign out", error)
        }        
    }
    
    func removeAuthStateChangeListener(_ listener: AuthStateDidChangeListenerHandle?) {
        if listener != nil {
            Auth.auth().removeStateDidChangeListener(listener!)
        }
    }
}
