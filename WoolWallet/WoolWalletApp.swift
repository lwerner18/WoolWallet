//
//  WoolWalletApp.swift
//  WoolWallet
//
//  Created by Mac on 3/8/24.
//

import SwiftUI

enum MainTab {
    case dashboard
    case stash
    case patterns
    case projects
}

@main
struct WoolWalletApp: App {
    let persistenceController = PersistenceController.shared
    
    @State private var selectedTab = MainTab.dashboard
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                Dashboard()
                    .tabItem {
                        Label("Dashboard", systemImage: "house")
                    }
                    .tag(MainTab.dashboard)
                
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
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onAppear {
                print("Documents Directory: \(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "Not found")")

            }
        }
    
    }
}
