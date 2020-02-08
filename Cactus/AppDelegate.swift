//
//  AppDelegate.swift
//  Cactus
//
//  Created by Neil Poulin on 7/25/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDynamicLinks
import FirebaseUI
import FirebaseMessaging
import Fabric
import Crashlytics
import Sentry
import FacebookCore
import Branch
import FirebaseInAppMessaging
import StoreKit

typealias SentryUser = Sentry.User

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let logger = Logger(fileName: String(describing: AppDelegate.self))
    var fcmToken: String?
    var window: UIWindow?
    var branchInstance: Branch?
    private var currentUser: FirebaseAuth.User?
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
//        Analytics.level
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        logger.info("Loading app will start", functionName: #function)
        SKPaymentQueue.default().add(StoreObserver.sharedInstance)

        let isFacebokIntent = FacebookCore.ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        logger.debug("Is facebook intent: \(isFacebokIntent)", functionName: #function, line: #line)
        
        Branch.setBranchKey(CactusConfig.branchPublicKey)
        
        let branchInstance = Branch.getInstance()
        self.branchInstance = branchInstance
        branchInstance.initSession(launchOptions: launchOptions) { (params, error) in
            defer {
                self.startAuthListener()
            }
            if let error = error {
                self.logger.error("Failed to initialize Branch", error)
                return
            }
            
            if let originalParams = branchInstance.getFirstReferringParams() {
                StorageService.sharedInstance.setBranchParameters(originalParams)
            }
            
            self.logger.info("Branch started")
            self.logger.info("Branch init params: \(String(describing: params as? [String: Any]))")
            StorageService.sharedInstance.setBranchParameters(params)
        }
        
        Fabric.with([Crashlytics.self])
        // Create a Sentry client and start crash handler
        do {
            Client.shared = try Client(dsn: "https://728bdc63f41d4c93a6ce0884a01b58ea@sentry.io/1515431")
            try Client.shared?.startCrashHandler()
            Client.shared?.environment = CactusConfig.environment.rawValue
            Client.shared?.releaseName = getReleaseName()
            Client.shared?.dist = getBuildVersion()
            Client.shared?.beforeSerializeEvent = { event in
                guard let email = Auth.auth().currentUser?.email else {
                    return
                }
                
                var tags = event.tags ?? [:]
                tags["user.email"] = email
                if let member = CactusMemberService.sharedInstance.currentMember, let memberId = member.id {
                    tags["cactusMemberId"] = memberId
                }
                event.tags = tags
            }
        } catch let error {
            self.logger.error("error setting up the sentry client \(error)")
        }
       
        Messaging.messaging().delegate = self
        let inAppDelegate = FirebaseInAppMessageDelegate()
        inAppDelegate.fetchId()
        InAppMessaging.inAppMessaging().delegate = inAppDelegate

        NotificationService.sharedInstance.clearIconBadge()
        NotificationService.sharedInstance.registerForPushIfEnabled(application: application)
                
        return true
    }
    
    func startAuthListener() {
        self.logger.debug("Starting auth listener")
        Auth.auth().addStateDidChangeListener {_, user in
            Analytics.logEvent("auth_state_changed", parameters: ["userId": user?.uid ?? "", "previousUserId": self.currentUser?.uid ?? ""])
            Crashlytics.sharedInstance().setUserEmail(user?.email)
            Crashlytics.sharedInstance().setUserIdentifier(user?.uid)
            Crashlytics.sharedInstance().setUserName(user?.displayName)
            if let user = user {
                let sentryUser = SentryUser(userId: user.uid)
                sentryUser.email = user.email
                Client.shared?.user = sentryUser
            } else {
                if let currentUser = self.currentUser {
                    let logoutEvent = Sentry.Event(level: .info)
                    logoutEvent.message = "\(currentUser.email ?? currentUser.uid) has logged out of the app"
                    Client.shared?.send(event: logoutEvent)
                }
                Client.shared?.user = nil
            }
            self.currentUser = user
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        // or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks.
        // Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application
        // state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate:
        // when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        NotificationService.sharedInstance.registerForPushIfEnabled(application: application)
        NotificationService.sharedInstance.clearIconBadge()
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppEvents.activateApp()
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        // See also applicationDidEnterBackground:.
        SKPaymentQueue.default().remove(StoreObserver.sharedInstance)
    }
    
    //handle handler for result of URL signup flows
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        FacebookCore.ApplicationDelegate.shared.application(
            app,
            open: url,
            options: options
        )
       
        guard let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String? else {
            return false
        }
        self.logger.debug("Starting application open url method (line 79)", functionName: #function, line: #line)
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            self.logger.debug("Handled by firebase auth ui")
            return true
        }
        // other URL handling goes here.
        self.logger.debug("handling custom link scheme \(url)", functionName: #function, line: #line)
//        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
//            // Handle the deep link. For example, show the deep-linked content or
//            // apply a promotional offer to the user's account.
//            // ...
//            self.logger.debug("handling dynamic link \(dynamicLink)", functionName: #function, line: #line)
//            return false
//        }
                
        if Branch.getInstance().application(app, open: url, options: options) {
            self.logger.info("Branch handled the URL open \(url.absoluteString)", functionName: #function)
            return true
        }
           
        if UserService.sharedInstance.handleActivityURL(url) {
            return true
        } else if LinkHandlerUtil.handlePromptContent(url) {
            return true
        } else if LinkHandlerUtil.handleSharedResponse(url) {
            return true
        } else if LinkHandlerUtil.handleSignupUrl(url) {
            return true
        } else {
            self.logger.warn("url \(url.absoluteString) not supported, sending back to the browser")
        }
        
        if let scheme = url.scheme,
            scheme.localizedCaseInsensitiveCompare("app.cactus") == .orderedSame,
            let viewName = url.host {
            
            var parameters: [String: String] = [:]
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
                parameters[$0.name] = $0.value
            }
            self.logger.info("handling deep link: \(viewName), \(parameters)")
        }
        
        return false
    }
    
    //handle firebase dynamic links
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        self.logger.info("continue User activity webpageurl \(userActivity.webpageURL?.absoluteString ?? "none")", functionName: #function, line: #line)
        
        if let url = userActivity.webpageURL, CactusMemberService.sharedInstance.currentUser == nil {
            let queryParams = url.getQueryParams()
            self.logger.info("Adding signup query params \(String(describing: queryParams))")
            StorageService.sharedInstance.setLocalSignupQueryParams(queryParams)
        }
        
//        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
//            //TODO: What the holy hell is this all even for??
//            if let error = error {
//                self.logger.error("error getting dynamic link", error)
//            }
//            self.logger.info("handling dynamic link \(String(describing: dynamiclink))")
//            guard let dynamiclink = dynamiclink, let url = dynamiclink.url else {return}
//            let host = url.host
//            let path = url.path
//            let parameters = url.getQueryParams()
//            let link = parameters["link"]
//            self.logger.info("host: \(host ?? "no host found")")
//            self.logger.info("path: \(path)")
//            self.logger.info("Parameters \(parameters)")
//            self.logger.info("Link \(link ?? "no links")")
//        }
//        self.logger.info("link handled via dynamic link... = \(handled)")
        
        if Branch.getInstance().continue(userActivity) {
           return true
       }
        
        if let activityUrl = userActivity.webpageURL {
            if Branch.getInstance().handleDeepLink(activityUrl) {
                self.logger.info("URL was a branch link, letting branch handle it.")
                return true
            } else if UserService.sharedInstance.handleActivityURL(activityUrl) {
                return true
            } else if LinkHandlerUtil.handlePromptContent(activityUrl) {
                return true
            } else if LinkHandlerUtil.handleSharedResponse(activityUrl) {
                return true
            } else {
                self.logger.warn("url not supported, sending back to the browser")
                application.open(activityUrl)
            }
        }
        
        return false
    }
    
    //NOTE: See https://github.com/firebase/quickstart-ios/blob/master/messaging/MessagingExampleSwift/AppDelegate.swift
    func registerForPushNotifications(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {success, error in
                    self.logger.info("Register for notifications permissions: bool = \(success)")
                    if let error = error {
                        self.logger.error("Failed to register for nofitications", error)
                    }
            })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
    }
    
    // Support for background fetch
    //    func application(_ application: UIApplication,
    //                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    //        guard let vc = (AppDelegate.shared.rootViewController.current as? UINavigationController)?.viewControllers.first as? JournalHomeViewController else {
    //            completionHandler(.noData)
    //            return
    //        }
    
    //        vc.journalFeedDataSource.checkForNewPrompts { (sentPrompts) in
    //            if (sentPrompts?.count ?? 0) > 0 {
    //                self.logger.info("Background fetch found new data")
    //                completionHandler(.newData)
    //                vc.journalFeedViewController?.reloadVisibleViews()
    //            } else {
    //                self.logger.info("Background fetch did not have any new data")
    //                completionHandler(.noData)
    //            }
    //        }
    //    }
}

extension AppDelegate: MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        self.logger.info("\(Emoji.flame) Firebase registration token: \(fcmToken)")
        self.fcmToken = fcmToken
        let dataDict: [String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        self.logger.debug("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}

// swiftlint:disable force_cast
extension AppDelegate {
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    var rootViewController: AppMainViewController {
        return window!.rootViewController as! AppMainViewController
    }
}
// swiftlint:enable force_cast

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        self.logger.warn("Unable to register for remote notifications: \(error.localizedDescription)", functionName: #function, line: #line)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.logger.info("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        self.logger.debug("didReceiveRemoteNotification triggered line 243", functionName: #function, line: #line)
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            self.logger.debug("Message ID: \(messageID)", functionName: #function, line: #line)
        }
        
        // Print full message.
        self.logger.debug("Message Info: \(userInfo)", functionName: #function, line: #line)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.logger.info("didReceiveRemoteNotification triggered line 260", functionName: #function, line: #line)
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            self.logger.debug("Message ID: \(messageID)", functionName: #function, line: #line)
        }
        
        // Print full message.
        self.logger.debug("Message Info: \(userInfo)", functionName: #function, line: #line)
        if let promptContentEntryId = userInfo["promptEntryId"] as? String {
            AppDelegate.shared.rootViewController.loadPromptContent(promptContentEntryId: promptContentEntryId, link: nil)
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        self.logger.info("Receive displayed notificications for ios 10", functionName: #function, line: #line)
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            self.logger.debug("Message ID: \(messageID)", functionName: #function, line: #line)
        }
        
        // Print full message.
        self.logger.debug("Message Info: \(userInfo)", functionName: #function, line: #line)
        NotificationService.sharedInstance.handlePushMessage(userInfo)
        // Change this to your preferred presentation option
        if let promptContentEntryId = userInfo["promptEntryId"] as? String {
            AppDelegate.shared.rootViewController.loadPromptContent(promptContentEntryId: promptContentEntryId, link: nil)
        }
        
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        self.logger.info("User notification received", functionName: #function, line: #line)
        if let messageID = userInfo[gcmMessageIDKey] {
            self.logger.debug("Message ID: \(messageID)", functionName: #function, line: #line)
        }
        // Print full message.
        self.logger.debug("Message Info: \(userInfo)", functionName: #function, line: #line)
        
        if let promptContentEntryId = userInfo["promptEntryId"] as? String {
            AppDelegate.shared.rootViewController.loadPromptContent(promptContentEntryId: promptContentEntryId, link: nil)
        }
        
        completionHandler()
    }
}
// [END ios_10_message_handling]
