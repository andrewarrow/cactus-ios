//
//  JournalFeedDataSource.swift
//  Cactus
//
//  Created by Neil Poulin on 9/24/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseFirestore

class PageLoader<T: FirestoreIdentifiable> {
    var result: PageResult<T>?
    var finishedLoading: Bool { result != nil }
    var listener: ListenerRegistration?
    
    init() {}
}

protocol JournalFeedDataSourceDelegate: class {
    func updateEntry(_ journalEntry: JournalEntry, at: Int?)
    func insert(_ journalEntry: JournalEntry, at: Int?)
//    func remove(_ journalEntry: JournalEntry, at: Int)
    func removeItems(_ indexes: [Int])
    func insertItems(_ indexes: [Int])
    func batchUpdate(addedIndexes: [Int], removedIndexes: [Int])
    func dataLoaded()
    func handleEmptyState(hasResults: Bool)
}

class JournalFeedDataSource {
    var logger = Logger(fileName: "JournalFeedDataSource")
    var currentMember: CactusMember?
    var journalEntryDataBySentPromptId: [String: JournalEntryData] = [:]
    var sentPrompts: [SentPrompt] = []
    var count: Int {
        return self.orderedPromptIds.count
    }
    var orderedPromptIds: [String] = []
    
    var promptsListener: ListenerRegistration?
    var memberUnsubscriber: (() -> Void)?
    
    weak var delegate: JournalFeedDataSourceDelegate?
    var hasLoaded = false
    func resetData() {
        self.orderedPromptIds.removeAll()
        self.unsubscribeAll()
        journalEntryDataBySentPromptId.removeAll()
        self.delegate?.dataLoaded()
    }
    
    func unsubscribeAll() {
        memberUnsubscriber?()
        promptsListener?.remove()
    }
    
    var currentStreak: Int {
        return calculateStreak(self.responses)
    }
    
    var responses: [ReflectionResponse] {
        return journalEntryDataBySentPromptId.values.flatMap { (entry) -> [ReflectionResponse] in
            return entry.responseData.responses
        }
    }
    
    var totalReflections: Int {
        return responses.count
    }
    
    var totalReflectionDurationMs: Int {
        return self.responses.reduce(0) { (totalMs, response) -> Int in
            return totalMs + (response.reflectionDurationMs ?? 0)
        }
    }
    
    var loadingCompleted: Bool {
        return !journalEntryDataBySentPromptId.values.contains(where: { (entry) -> Bool in
            return !entry.loadingComplete
        })
    }
    
    var pageListeners: [ListenerRegistration] = []
    var pages: [PageLoader<SentPrompt>] = []
    var pageSize: Int = 3
    var mightHaveMore: Bool {self.pages.last?.result?.mightHaveMore ?? false}
    
    var isLoading: Bool {self.pages.isEmpty ? !self.hasLoaded : self.pages.contains { !$0.finishedLoading } }
    
    deinit {
        logger.info("Deinit JournalFeedDataSource. Unsubscribing from all data")
        self.unsubscribeAll()
        self.delegate = nil
        self.resetData()
    }
    
    init(member: CactusMember?=nil) {
        self.currentMember = member
    }
    
    var startDate: Date?
    var hasStarted: Bool = false
    func start() {
        if hasStarted {
            self.logger.warn("data source has already been started. Returning")
            return
        }
                
        if self.currentMember == nil {
            self.logger.info("No member found, returning", functionName: #function)
//            self.resetData()
            return
        }
        self.logger.info("Starting journal feed data source")
        self.hasStarted = true
        self.initializePages()
    
//        logger.info("Creating JournalFeedDataSource", functionName: #function)
//        self.memberUnsubscriber = CactusMemberService.sharedInstance.observeCurrentMember({ (member, _, _) in
//            if self.currentMember != member {
//                self.logger.info("No member found, resetting data", functionName: #function)
//                self.resetData()
//            }
//            self.currentMember = member
//            self.initializePages()
////            self.loadNextPage()
//        })
    }
    
    func initializePages() {
        guard let member = self.currentMember else {
            self.logger.warn("[JouranlFeedDataSource] No current member found, can't start pages")
            return
        }
        
        let futurePage = PageLoader<SentPrompt>()
        self.pages.insert(futurePage, at: 0)
        
        let startDate = Date()
        self.startDate = startDate
        futurePage.listener = SentPromptService.sharedInstance.observeFuturePrompts(member: member, since: startDate, limit: nil, { (pageResult) in
            futurePage.result = pageResult
            self.logger.info("Got \"future\" data with \(pageResult.results?.count ?? 0) results", fileName: "JournalFeedDataSource", line: #line)
            self.configurePages()
        })
        
        let firstPage = PageLoader<SentPrompt>()
        self.pages.insert(firstPage, at: 1)
        firstPage.listener = SentPromptService.sharedInstance.observeSentPromptsPage(member: member, beforeOrEqualTo: startDate, limit: self.pageSize, lastResult: nil, { (pageResult) in
            firstPage.result = pageResult
            self.logger.info("Got first page data with \(pageResult.results?.count ?? 0) results", fileName: "JournalFeedDataSource", line: #line)
            
            if !self.hasLoaded {
                self.delegate?.handleEmptyState(hasResults: !(pageResult.results?.isEmpty ?? true))
            }
            
            self.configurePages()
            self.hasLoaded = true
        })
    }
    
    func loadNextPage() {
        self.logger.info("attempting to load  next page", functionName: #function)
        
        guard !self.isLoading else {
            logger.info("Already loading more, can't fetch next page", functionName: #function)
            return
        }
        guard let member = self.currentMember else {
            logger.warn("No current member found, can't load next page", functionName: #function)
            return
        }
        let nextIndex = self.pages.count
        let previousResult = self.pages.last?.result
        
        if previousResult == nil && nextIndex != 0 {
            logger.info("Page hasn't finished loading yet, can't fetch next page", functionName: #function, line: #line)
            return
        }
        
        self.logger.info("Creating page loader. This will be the \(self.pages.count) page", functionName: #function, line: #line)
        let page = PageLoader<SentPrompt>()
        self.pages.append(page)
        page.listener = SentPromptService.sharedInstance.observeSentPromptsPage(member: member, limit: self.pageSize, lastResult: previousResult, { (pageResult) in
            page.result = pageResult
            self.logger.info("Got page data with \(pageResult.results?.count ?? 0) results", functionName: "JournalFeedDataSource", line: #line)
            self.configurePages()
        })
    }
    
    func configurePages() {
        self.logger.info("configuring page data", functionName: #function, line: #line)
        let prompts: [SentPrompt] = self.pages.compactMap {$0.result?.results}.flatMap {$0}
        self.sentPrompts = prompts
        
        self.initSentPrompts()
    }
    
    func checkForNewPrompts(_ completed: (([SentPrompt]?) -> Void)? = nil) {
        logger.info("checkForNewPrompts called")
        guard let member = self.currentMember else {
            return
        }
        let first = self.pages.first?.result?.firstSnapshot
        SentPromptService.sharedInstance.getSentPrompts(member: member, limit: 10, before: first) { (sentPrompts, error) in
            if let error = error {
                self.logger.error("Error checking for new prompts", error)
            }
            
            guard let sentPrompts = sentPrompts else {
                self.logger.info("NO sent prompts found")
                return
            }
                        
            sentPrompts.reversed().forEach { (sentPrompt) in
                if !self.sentPrompts.contains(sentPrompt) {
                    self.logger.custom("found a new prompt!", icon: Emoji.tada)
                    self.sentPrompts.insert(sentPrompt, at: 0)
                }
            }
            self.initSentPrompts()
        }
    }
    
    func get(at index: Int) -> JournalEntry? {
        guard index < self.orderedPromptIds.count && index >= 0 else {
            return nil
        }
        let promptId = self.orderedPromptIds[index]
        guard let data = self.journalEntryDataBySentPromptId[promptId] else {
            return nil
        }
        
        return data.getJournalEntry()
    }
    
    func indexOf(_ journalEntry: JournalEntry) -> Int? {
        guard let promptId = journalEntry.sentPrompt.promptId else {
            return nil
        }
        
        return self.orderedPromptIds.firstIndex(of: promptId)
    }
    
    func initSentPrompts() {
        guard let memberId = self.currentMember?.id else {
            self.logger.warn("No member or memberId was found on the data feed", functionName: #function, line: #line)
            return
        }

        var createdEntries: [JournalEntryData] = []
        var insertedIndexes: [Int] = []
        var orderedPromptIds = [String]()
        for (index, sentPrompt) in self.sentPrompts.enumerated() {
            guard let promptId = sentPrompt.promptId, !orderedPromptIds.contains(promptId) else {
                return
            }
            if self.journalEntryDataBySentPromptId[promptId] == nil {
                self.logger.debug("Setting up journal entry data source for promptId \(promptId)")
                let journalEntry = JournalEntryData(sentPrompt: sentPrompt, memberId: memberId)
                journalEntry.delegate = self
                createdEntries.append(journalEntry)
                self.journalEntryDataBySentPromptId[promptId] = journalEntry
                insertedIndexes.append(index)
            }
            orderedPromptIds.append(promptId)
        }
        
        //get removed indexes
        var removedIndexes: [Int] = []
        for (index, id) in self.orderedPromptIds.enumerated() {
            if !orderedPromptIds.contains(id) {
                removedIndexes.append(index)
            }
        }
        self.logger.info("found \(removedIndexes.count) removed indexes")
        
        self.orderedPromptIds = orderedPromptIds
        
        if !removedIndexes.isEmpty && !insertedIndexes.isEmpty {
            self.logger.info("Performing batch update")
            self.delegate?.batchUpdate(addedIndexes: insertedIndexes, removedIndexes: removedIndexes)
        } else if !removedIndexes.isEmpty {
            self.delegate?.removeItems(removedIndexes)
        } else if !insertedIndexes.isEmpty {
            self.delegate?.insertItems(insertedIndexes)
        }
        
        createdEntries.forEach {$0.start()}
    }
}

extension JournalFeedDataSource: JournalEntryDataDelegate {
    func onData(_ journalEntry: JournalEntry) {
        let index = self.indexOf(journalEntry)
        self.delegate?.updateEntry(journalEntry, at: index)
    }
}
