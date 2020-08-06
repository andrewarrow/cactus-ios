//
//  SettingsHome.swift
//  Cactus
//
//  Created by Neil Poulin on 8/4/20.
//  Copyright © 2020 Cactus. All rights reserved.
//

import SwiftUI

struct SettingsItem: Identifiable {
    
    var id = UUID()
    var title: String
    var subtitle: String?
    var destination: AnyView
    var setNavigationTitle: Bool
    init<V>(_ title: String, _ subtitle: String?=nil, destination: V, setNavigationTitle: Bool=true) where V: View {
        self.title = title
        self.subtitle = subtitle
        self.destination = AnyView(destination)
        self.setNavigationTitle = setNavigationTitle
    }
}

struct SettingsHome: View {
    @EnvironmentObject var session: SessionStore
    
    var items: [SettingsItem] {
        let email = self.session.member?.email
        var profileSubTitle: String? = email
        if let displayName = self.session.member?.fullName {
            profileSubTitle = isBlank(email) ? displayName : "\(displayName) (\(email!))"
        }
        
        let tier = self.session.member?.tier ?? .BASIC
        let providers = self.session.user?.providerData.map {$0.providerID} ?? ["password"]
        
        return [
            SettingsItem("Profile", profileSubTitle, destination: ProfileSettingsView()),
            SettingsItem("Notifications", destination: NotificationSettingsView()),
            SettingsItem("Subscription", tier.displayName, destination: SubscriptionSettingsView()),
            SettingsItem("Linked Accounts", destination: LinkedAccountsView(providers: providers).navigationBarTitle("Linked Accounts")),
            SettingsItem("Help", destination: HelpView(), setNavigationTitle: false),
            SettingsItem("Send Feedback", destination: FeedbackView(), setNavigationTitle: false),
            SettingsItem("Terms of Service", destination: TermsOfServiceView(), setNavigationTitle: false),
            SettingsItem("Privacy Policy", destination: PrivacyPolicyView(), setNavigationTitle: false),
        ]
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.items) { item in
                    SettingsItemView(item: item)
                }
            }
            .onAppear {
                UITableView.appearance().separatorStyle = .singleLine
            }
            .font(CactusFont.normal.font)
                .onAppear {
                    UITableView.appearance().separatorInset = .zero
            }
                .navigationBarTitle("Settings")
        }
        
    }
}

struct SettingsHome_Previews: PreviewProvider {
    static var previews: some View {
        SettingsHome().environmentObject(SessionStore.mockLoggedIn())
    }
}

struct SettingsItemView: View {
    var item: SettingsItem
    
    var body: some View {
        NavigationLink(destination: self.item.destination
            .ifMatches(self.item.setNavigationTitle) { content in
                content.navigationBarTitle(item.title)
            }            
        ) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.title)
                    if item.subtitle != nil {
                        Text(item.subtitle!).font(CactusFont.normal(FontSize.subTitle).font)
                    }
                }
            }
        }
        .minHeight(44)
        .padding()
        .listRowInsets(EdgeInsets())
    }
}