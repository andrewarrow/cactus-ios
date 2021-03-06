//
//  Screens.swift
//  Cactus
//
//  Created by Neil Poulin on 7/26/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import Foundation
import UIKit

enum ScreenID: String {
    //main
    case AppMain = "AppMain"
    case Login = "Login"
    case LaunchScreen = "LaunchScreen"
    case JournalFeed
    case JournalHome
    case elementsPageView
    case journalEmpty
    case promptContentPageView
    case Welcome
    case WelcomeVC
    case LoadingFullScreen
    case BrowsePrompts
    case PromptContentCollection
    case CoreValuesAssessment

    //settings
    case settingsTable
    case inviteScreen
    case notificationsScreen
    case ProfileSettings
    case LinkedAccounts
    case AskQuestions
    case TermsOfService
    case PrivacyPolicy
    case SendFeedback
    case DownloadData
    
    //Onboarding
    case notificationOnboarding
    
    //Social
    case inviteFriend
    
    //payment
    case Pricing
    case ManageSubscription
    case PricingFeatureItem
        
    //NIBs
    case WebView
    case MemberInsights
    
    var name: String {
        return self.rawValue
    }
    
    func loadFromNib() -> UIViewController? {
        switch self {
        default:
            return nil
        }
    }
    
    var storyboardID: StoryboardID {
        switch self {
        case .settingsTable,
             .inviteScreen,
             .ProfileSettings,
             .LinkedAccounts,
             .AskQuestions,
             .TermsOfService,
             .PrivacyPolicy,
             .SendFeedback,
             .DownloadData,
             .notificationsScreen:
            return StoryboardID.Settings
        case .notificationOnboarding:
            return StoryboardID.Onboarding
        case .inviteFriend:
            return StoryboardID.Social
        case .Pricing,
             .PricingFeatureItem,
             .ManageSubscription:        
            return StoryboardID.Payment
        default:
            return StoryboardID.Main
        }
    }
    
    func getViewController() -> UIViewController {
        if let nibVc = self.loadFromNib() {
            return nibVc
        }
        
        let storyboardId = self.storyboardID
        let storyboard = storyboardId.getStoryboard()
        return storyboard.instantiateViewController(withIdentifier: self.name)
    }
    
    func getURL() -> URL? {
        return URL(string: "\(CactusConfig.customScheme)://vc/\(self.rawValue)")                    
    }
}

enum ReuseIdentifier: String {
    case JournalEntryCell
}

enum NibName: String {
    case TextContent = "TextContentViewController"

    var name: String {
        return self.rawValue
    }
}

enum StoryboardID: String {
    case LaunchScreen
    case Main
    case Settings
    case Onboarding
    case Social
    case Payment

    var name: String {
        return self.rawValue
    }
    
    func getStoryboard() -> UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }
}

enum SegueID: String {
    case ShowPromptContentModal
    case embedJournalFeed

    var name: String {
        return self.rawValue
    }
    
    static func fromString(_ input: String?) -> SegueID? {
        guard let input = input else {return nil}
        return SegueID(rawValue: input)
    }
}
