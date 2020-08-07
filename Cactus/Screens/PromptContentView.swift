//
//  PromptContentView.swift
//  Cactus
//
//  Created by Neil Poulin on 7/20/20.
//  Copyright © 2020 Cactus. All rights reserved.
//

import SwiftUI

struct PromptContentController: UIViewControllerRepresentable {
    var entry: JournalEntry
    @EnvironmentObject var session: SessionStore
//    weak var delegate: PromptContentPageViewControllerDelegate?
    var onDismiss: ((PromptContent) -> Void)?
    
    func makeUIViewController(context: Context) -> PromptContentPageViewController {
        let view = ScreenID.promptContentPageView.getViewController() as! PromptContentPageViewController
        view.promptContent = self.entry.promptContent
        view.reflectionResponse = self.entry.responses?.first
        view.promptDelegate = context.coordinator
        view.member = session.member
        view.appSettings = session.settings
        return view
    }
    
    func updateUIViewController(_ uiViewController: PromptContentPageViewController, context: Context) {
        uiViewController.promptDelegate = context.coordinator
        uiViewController.member = session.member
        uiViewController.appSettings = session.settings
        uiViewController.promptContent = self.entry.promptContent
        uiViewController.reflectionResponse = self.entry.responses?.first
    }
    
    class Coordinator: PromptContentPageViewControllerDelegate {
        var parent: PromptContentController
        
        init(_ parent: PromptContentController) {
            self.parent = parent
        }
        
        func didDismissPrompt(promptContent: PromptContent) {
            Logger.shared.info("Coordiator: prompt was dismissed")
            self.parent.onDismiss?(promptContent)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

struct PromptContentView: View {
    @EnvironmentObject var session: SessionStore
    var entry: JournalEntry

    var onPromptDismiss: ((PromptContent) -> Void)?
    
    var body: some View {
        Group {
            if self.entry.promptContent == nil || !self.entry.loadingComplete {
                HStack{
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    Loading("Loading...")
                }
            } else {
                PromptContentController(entry: self.entry, onDismiss: self.onPromptDismiss)
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
        
    }
}

struct PromptContentView_Previews: PreviewProvider {
    
    static func getEntry() -> JournalEntry {
        var entry = JournalEntry(promptId: "testId")
        entry.loadingComplete = false
        return entry
    }
    
    static var previews: some View {
        PromptContentView(entry: getEntry()).environmentObject(SessionStore.mockLoggedIn())
    }
}
