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
//            TabView {
//                
//                    .tabItem {
//                        Image(systemName: "list.triangle")
//                        Text("My Yarn")
//                    }
//                AddYarnForm()
//                    .tabItem {
//                        Image(systemName: "plus")
//                        Text("Add Yarn")
//                    }
//            }
            YarnList()
            .colorScheme(.light) // Set color scheme to light mode
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    
    }
}
