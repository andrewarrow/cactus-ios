//
//  ReflectionResponseService.swift
//  Cactus
//
//  Created by Neil Poulin on 7/26/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import Foundation
import FirebaseFirestore

class ReflectionResponseService {
    
    let firestoreService: FirestoreService
    
    static let sharedInstance = ReflectionResponseService();
    
    private init(){
        self.firestoreService = FirestoreService.sharedInstance
    }
    
    func getCollectionRef() -> CollectionReference {
        return self.firestoreService.getCollection(FirestoreCollectionName.reflectionResponses)
    }
    
    func observeById(id:String, _ onData: @escaping (ReflectionResponse?, Any?) -> Void) -> ListenerRegistration? {
        return self.firestoreService.observeById(id, onData)
    }
    
    func observeForPromptId(id:String, _ onData: @escaping ([ReflectionResponse]?, Any?) -> Void) -> ListenerRegistration? {
        guard let currentMember = CactusMemberService.sharedInstance.getCurrentMember(), let memberId = currentMember.id else {
            onData([], "No cactus member")
            return nil
        }
        let query = self.getCollectionRef().whereField(ReflectionResponse.Field.cactusMemberId, isEqualTo: memberId)
    
        return self.firestoreService.addListener(query, onData)
        
    }
}
