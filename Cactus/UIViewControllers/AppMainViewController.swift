//
//  AppMainViewController.swift
//  Cactus
//
//  Created by Neil Poulin on 7/26/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import UIKit
import FirebaseAuth
//import FirebaseFirestore
class AppMainViewController: UIViewController {
    static var shared: AppMainViewController!
    var current: UIViewController
    let logger = Logger(fileName: "AppMainViewController")
    var member: CactusMember?
    var memberUnsubscriber: Unsubscriber?
    var appSettings: AppSettings?
    
//    var currentStatusBarStyle: UIStatusBarStyle = .default
    var pendingAction: (() -> Void)?
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        if #available(iOS 13.0, *) {
//            return self.currentStatusBarStyle
//        } else {
//            // Fallback on earlier versions
//            return .default
//        }
//    }
    
//    func setStatusBarStyle(_ updatedStyle: UIStatusBarStyle) {
//        self.currentStatusBarStyle = updatedStyle
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let launchStoryboard = UIStoryboard(name: StoryboardID.LaunchScreen.name, bundle: nil)
        self.current = launchStoryboard.instantiateViewController(withIdentifier: ScreenID.LaunchScreen.name)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        AppMainViewController.shared = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        let launchStoryboard = UIStoryboard(name: StoryboardID.LaunchScreen.name, bundle: nil)
        self.current = launchStoryboard.instantiateViewController(withIdentifier: ScreenID.LaunchScreen.name)
        super.init(coder: aDecoder)
        AppMainViewController.shared = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(current)
        current.view.frame = view.bounds
        view.addSubview(current.view)
        current.didMove(toParent: self)
                
        AppSettingsService.sharedInstance.getSettings { (settings, error) in
            if let error = error {
                self.logger.error("Failed to get app settings and can not start the app properly.", error)
            }
            self.appSettings = settings
            self.logger.info("***** setting up auth*****")
            self.setupAuth()
        }
    }
    
    func setupAuth() {        
        self.memberUnsubscriber = CactusMemberService.sharedInstance.observeCurrentMember { (member, _, user) in
            self.logger.info("setup auth onData \(member?.email ?? "no email")" )
            
            if member == nil && user == nil {
                self.logger.info("found member is null. showing loign screen.")
                self.showWelcomeScreen()
            } else if member == nil && user != nil {
                self.logger.info("User is logged in but no member was found (yet). We're probably still creating the member. Don't do anything!")
            } else if let member = member, member.id != self.member?.id {
                self.logger.info("Found member, not null. showing journal home page")
                CactusAnalytics.shared.setSubscriptionTier(member: member)
                self.showJournalHome(member: member, wrapInNav: true)
            }
            self.member = member
            
            self.runPendingActions()
        }
    }
    
    func runPendingActions() {
        DispatchQueue.main.async {
            guard self.member != nil else {
                return
            }
            self.pendingAction?()
            self.pendingAction = nil
        }
    }
    
    // @Deprecated - use SessionStore instead
    func addPendingAction(_ action: @escaping () -> Void) {
        self.pendingAction = action
        self.runPendingActions()
    }
    
    func showWelcomeScreen() {
//        self.setStatusBarStyle(.lightContent)
        if self.current as? WelcomeViewController == nil {
            self.logger.info("Showing welcome screen")
            _ = self.showScreen(ScreenID.Welcome, wrapInNav: false)
        } else {
            self.logger.info("already showing welcome, don't do anything")
        }
    }
    
    func getJournalFeedViewController() -> JournalFeedCollectionViewController {
        guard let vc = self.getScreen(ScreenID.JournalFeed) as? JournalFeedCollectionViewController else {
            self.logger.error("Unable to get JournalFeedCollectionViewController from storyboard")
            fatalError("Unable to get journal feed view controller")
        }
        return vc
    }
    
    func showJournalHome(member: CactusMember, wrapInNav: Bool) {
        self.logger.info("Showing Journal Home screen for member email \(member.email ?? "none set")")
        guard let vc = self.getScreen(ScreenID.JournalHome) as? JournalHomeViewController else {
            return
        }
        vc.member = member
        _ = showScreen(vc, wrapInNav: true)        
    }
    
    func getScreen(_ screen: ScreenID) -> UIViewController {
        //        let storyboard = screen.storyboardID.getStoryboard()
        //        return storyboard.instantiateViewController(withIdentifier: screen.name)
        return screen.getViewController()
    }
    
    func showScreen(_ screenId: ScreenID, wrapInNav: Bool=false, animate: ((_ new: UIViewController, _ completion: (() -> Void)?) -> Void)? = nil) -> UIViewController {
        let screen = getScreen(screenId)
        let vc = showScreen(screen, wrapInNav: wrapInNav)
        return vc
    }
    
    // @Deprecated - use SessionStore
//    func loadPromptContent(promptContentEntryId: String, link: String?=nil) {
//        self.addPendingAction {
//            let vc = LoadablePromptContentViewController.loadFromNib()
//            vc.originalLink = link
//            vc.promptContentEntryId = promptContentEntryId
//            vc.modalPresentationStyle = .overFullScreen
//            vc.modalTransitionStyle = .coverVertical
//            self.present(vc, animated: true, completion: nil)
//        }
//    }
    
//    func loadSharedReflection(reflectionId: String, link: String?=nil) {
//        self.addPendingAction {
//            let vc = LoadableSharedReflectionViewController.loadFromNib()
//            vc.originalLink = link
//            vc.reflectionId = reflectionId
//            self.present(vc, animated: true, completion: nil)
//        }
//    }
    
//    func sendLoginEvent(_ loginEvent: LoginEvent) {
//        DispatchQueue.global(qos: .background).async {
//            var loginEvent = loginEvent
//            loginEvent.signupQueryParams = StorageService.sharedInstance.getLocalSignupQueryParams()
//
//            ApiService.sharedInstance.sendLoginEvent(loginEvent, completed: { error in
//                if let error = error {
//                    self.logger.error("Failed to send login event", error)
//                    return
//                }
//                self.logger.info("login event completed")
//            })
//        }
//    }
    
    func showScreen(_ screen: UIViewController, wrapInNav: Bool=false) -> UIViewController {
        var newVc = screen
        if wrapInNav {
            newVc = UINavigationController(rootViewController: screen)
        }
        
        addChild(newVc)
        newVc.view.frame = view.bounds
        self.view.addSubview(newVc.view)
        newVc.didMove(toParent: self)
        current.willMove(toParent: nil)
        current.view.removeFromSuperview()
        current.removeFromParent()
        current = newVc
        self.logger.info("showScreen...", functionName: #function)
        return newVc
    }
    
    func pushScreen(_ screenId: ScreenID, animate: Bool=true) {
        let screen = screenId.getViewController()
        
        if  let nav = self.current as? UINavigationController {
            self.logger.info("Pushing view controller")
            nav.pushViewController(screen, animated: animate)
        } else {
            self.logger.info("Presenting view controller")
            self.current.present(screen, animated: animate)
        }
    }
    
    func deleteAccount() {
        self.logger.info("attempting to delete the user's account")
        guard let loadingVc = ScreenID.LoadingFullScreen.getViewController() as? LoadingViewController else {
            return
        }
        DispatchQueue.main.async {
            loadingVc.message = "Deleting Account..."
            NavigationService.shared.present(loadingVc)
        }
        
        UserService.sharedInstance.deleteUserPermenantly { (result) in
            self.logger.info("\(Emoji.skullAndCrossbones) Account deleted = \(result.success)")
            DispatchQueue.main.async {
                loadingVc.dismiss(animated: true) {
                    if result.success {
                        AuthService.sharedInstance.logout()
                        let alert = UIAlertController(title: "Account Deleted", message: "Your account as been successfully deleted.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                        NavigationService.shared.present(alert)
                    }
                }
            }
        }
    }
    
    func logOut(_ vc: UIViewController, sender: UIView) {
        var  message = "Are you sure you want to log out?"
        if let user = AuthService.sharedInstance.getCurrentUser(), (user.displayName != nil || user.email != nil) {
            var name = user.email
            if name == nil {
                name = user.displayName
            }
            if name != nil {
                message = "Are you sure you want to log out of \(name!)?"
            }
        }
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            CactusMemberService.sharedInstance.removeFCMToken(onCompleted: { (error) in
                if let error = error {
                    self.logger.error("Failed to remove tokens from Cactus User. Oh well - still logging out", error)
                }
                do {
                    try Auth.auth().signOut()
                    vc.dismiss(animated: false, completion: nil)
                    _ = self.showScreen(ScreenID.Login)
                } catch {
                    self.logger.error("error signing out", error)
                    let alert = UIAlertController(title: "Error Logging Out", message: "An unexpected error occurred while logging out. \n\n\(error)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    vc.present(alert, animated: true)
                }
            })
        })
        vc.present(alert, animated: true)
    }
    
}
