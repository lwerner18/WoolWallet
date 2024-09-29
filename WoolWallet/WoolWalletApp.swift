//
//  WoolWalletApp.swift
//  WoolWallet
//
//  Created by Mac on 3/8/24.
//

import SwiftUI

@main
struct WoolWalletApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            TabView {
                YarnList()
                    .tabItem {
                        Label("My Stash", systemImage: "volleyball")
                    }
                
                PatternList()
                    .tabItem {
                        Label("Patterns", systemImage: "newspaper")
                    }
                
                ProjectList()
                    .tabItem {
                        Label("Projects", systemImage: "hammer")
                    }
            }
            .colorScheme(.light) // Set color scheme to light mode
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    
    }
}
