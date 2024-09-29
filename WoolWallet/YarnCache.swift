//
//  YarnCache.swift
//  WoolWallet
//
//  Created by Mac on 8/25/24.
//

import Foundation
import CoreData
import SwiftUI

class YarnCache {
    static let shared = YarnCache()
    
    private var managedObjectContext: NSManagedObjectContext
    @Published private(set) var yarns: [Yarn] = []
    
    
    private init() {
        // Assuming you have a way to get the Core Data context
        // This context should be set when initializing the singleton
        self.managedObjectContext = PersistenceController.shared.container.viewContext
    }
    
    func updateYarn(_ yarn: Yarn) {
        if let index = yarns.firstIndex(where: { $0.id == yarn.id }) {
            yarns[index] = yarn
        } else {
            yarns.append(yarn)
        }
    }
    
    func removeYarn(_ yarn: Yarn) {
        yarns.removeAll { $0.id == yarn.id }
    }
    
    func setYarns(_ yarns: [Yarn]) {
        self.yarns = yarns
    }
    
    // Method to load yarns into the cache
    func loadYarns(from context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Yarn> = Yarn.fetchRequest()
        do {
            yarns = try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch yarns: \(error)")
        }
    }
    
    // Method to refresh the cache
    func refresh(from context: NSManagedObjectContext) {
        loadYarns(from: context)
    }
}
