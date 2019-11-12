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
    
    static let sharedInstance = ReflectionResponseService()
    
    private init() {
        self.firestoreService = FirestoreService.sharedInstance
    }
    
    func getCollectionRef() -> CollectionReference {
        return self.firestoreService.getCollection(FirestoreCollectionName.reflectionResponses)
    }
    
    func observeById(id: String, _ onData: @escaping (ReflectionResponse?, Any?) -> Void) -> ListenerRegistration? {
        return self.firestoreService.observeById(id, onData)
    }
    
    func observeForPromptId(id: String, _ onData: @escaping ([ReflectionResponse]?, Any?) -> Void) -> ListenerRegistration? {
        guard let currentMember = CactusMemberService.sharedInstance.getCurrentMember(), let memberId = currentMember.id else {
            onData([], "No cactus member")
            return nil
        }
        let query = self.getCollectionRef().whereField(ReflectionResponse.Field.cactusMemberId, isEqualTo: memberId).whereField(ReflectionResponseField.promptId, isEqualTo: id)
    
        return self.firestoreService.addListener(query, onData)
        
    }
    
    func save(_ response: ReflectionResponse, _ onData: @escaping (ReflectionResponse?, Any?) -> Void) {
        self.firestoreService.save(response, onComplete: onData)
    }
    
    func delete(_ response: ReflectionResponse, _ onData: @escaping (_ error: Any?) -> Void) {
        self.firestoreService.delete(response, onComplete: onData)
    }
    
    func createReflectionResponse(_ prompt: ReflectionPrompt, medium: ResponseMedium = .JOURNAL_IOS) -> ReflectionResponse {
        let response = ReflectionResponse()
        response.promptId = prompt.id
        response.promptQuestion = prompt.question
        
        response.responseMedium = medium
        if let member = CactusMemberService.sharedInstance.currentMember {
            response.cactusMemberId = member.id
            response.userId = member.userId
            response.memberEmail = member.email
            if let listMember = member.mailchimpListMember {
                response.mailchimpMemberId = listMember.id
                response.mailchimpUniqueEmailId = listMember.unique_email_id
            }
        } else {
            print("Warning: no cactus member was found")
        }
        
        return response
    }
    
    func createReflectionResponse(_ promptId: String, promptQuestion: String?, element: CactusElement?) -> ReflectionResponse? {
        guard let member = CactusMemberService.sharedInstance.currentMember else {
            return nil
        }
        
        let response = ReflectionResponse()
        response.promptId = promptId
        response.cactusMemberId = member.id
        response.promptQuestion = promptQuestion
        response.userId = member.userId
        response.memberEmail = member.email
        response.responseMedium = ResponseMedium.JOURNAL_IOS
        response.cactusElement = element
        if let listMember = member.mailchimpListMember {
            response.mailchimpMemberId = listMember.id
            response.mailchimpUniqueEmailId = listMember.unique_email_id
        }
        
        return response
    }
    
    func shareReflection(_ response: ReflectionResponse, _ completed: @escaping (ReflectionResponse?, Any?) -> Void) {
        response.shared = true
        response.sharedAt = Date()
        self.save(response, completed)
    }
}
