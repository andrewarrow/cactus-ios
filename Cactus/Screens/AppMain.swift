//
//  AppMain.swift
//  Cactus
//
//  Created by Neil Poulin on 7/20/20.
//  Copyright © 2020 Cactus. All rights reserved.
//

import SwiftUI

struct AppMain: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var checkout: CheckoutStore
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if !self.session.authLoaded {
                    LaunchScreenView()
                        .frame(minWidth: geo.size.width, maxWidth: .infinity, minHeight: geo.size.height, maxHeight: .infinity)
                        .transition(AnyTransition.opacity.animation(Animation.easeInOut(duration: 0.3).delay(1)))
                        .zIndex(2)
                        .edgesIgnoringSafeArea(.all)
                } else if self.session.authLoaded {
                    Group {
                        if self.session.member == nil {
                            Welcome().background(named: .Background)
                        } else if !self.session.journalLoaded {
                            Loading("Loading Journal...")
                        } else if self.session.showOnboarding == true {
                            if self.session.onboardingEntry != nil {
                                PromptContentView(entry: self.session.onboardingEntry!, onPromptDismiss: { _ in
                                    self.session.showOnboarding = false
                                })
                                .foregroundColor(named: .TextDefault)
                                .edgesIgnoringSafeArea(.top)
                            } else {
                                Loading("Loading Onboarding...")
                            }
                        } else if !self.session.showOnboarding {
                            AppTabs().background(named: .Background)
                        } else {
                            LaunchScreenView().edgesIgnoringSafeArea(.all)
                        }
                    }
                    .zIndex(1)
    //                .transition( AnyTransition.opacity.animation(.easeInOut(duration: 1)))
                }
            }
        }
    }
}

struct AppMain_Previews: PreviewProvider {
    static var MockAppData = SessionStore.mockLoggedIn()
    static var LoadingAppData = SessionStore()
    static var MockLoggedOut = SessionStore.mockLoggedOut()
    static var previews: some View {
        Group {
            AppMain().environmentObject(self.LoadingAppData)
                .environmentObject(CheckoutStore.mock())
                .previewDisplayName("Auth Loading")
            
            AppMain().environmentObject(self.LoadingAppData)
            .environmentObject(CheckoutStore.mock())
                .colorScheme(.dark)
            .previewDisplayName("Auth Loading (Dark)")
            
            AppMain().environmentObject(self.MockAppData)
                .environmentObject(CheckoutStore.mock())
                .previewDisplayName("Logged In")
            
            AppMain().environmentObject(self.MockAppData)
            .environmentObject(CheckoutStore.mock())
                .colorScheme(.dark)
            .previewDisplayName("Logged In (Dark)")
                
            AppMain().environmentObject(self.MockLoggedOut)
                .environmentObject(CheckoutStore.mock())
                .previewDisplayName("Logged Out")
                
        }
    }
}
