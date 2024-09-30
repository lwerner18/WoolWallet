//
//  WoolWalletApp.swift
//  WoolWallet
//
//  Created by Mac on 3/8/24.
//

import SwiftUI

enum MainTab {
    case stash
    case patterns
    case projects
}

@main
struct WoolWalletApp: App {
    let persistenceController = PersistenceController.shared
    
    @State private var selectedTab = MainTab.stash
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                YarnList()
                    .tabItem {
                        Label("My Stash", systemImage: "volleyball")
                    }
                    .tag(MainTab.stash)
                
                PatternList()
                    .tabItem {
                        Label("Patterns", systemImage: "newspaper")
                    }
                    .tag(MainTab.patterns)
                
                ProjectList()
                    .tabItem {
                        Label("Projects", systemImage: "hammer")
                    }
                    .tag(MainTab.projects)
            }
            .colorScheme(.light) // Set color scheme to light mode
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
//            .onAppear {
//                // correct the transparency bug for Tab bars
//                let tabBarAppearance = UITabBarAppearance()
//                tabBarAppearance.configureWithOpaqueBackground()
//                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
//                // correct the transparency bug for Navigation bars
//                let navigationBarAppearance = UINavigationBarAppearance()
//                navigationBarAppearance.configureWithOpaqueBackground()
//                UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
//            }
        }
    
    }
}
