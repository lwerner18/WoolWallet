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
            YarnList()
            .colorScheme(.light) // Set color scheme to light mode
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    
    }
}
