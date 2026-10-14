//
//  PersistenceController.swift
//  WoolWallet
//
//  Created by Mac on 3/11/24.
//

import Foundation
import CoreData

struct PersistenceController {
    // A singleton for our entire app to use
    static let shared = PersistenceController()
    
    // Storage for Core Data
    let container: NSPersistentContainer
    
    // A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        return controller
    }()
    
    // An initializer to load Core Data, optionally able
    // to use an in-memory store.
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Data")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        migrateLegacyWeightLabels()
        assignMissingYarnIDs()
    }
    
    /// Renames stored "5 - Chunky" values to "5 - Bulky" so filters and charts keep matching.
    private func migrateLegacyWeightLabels() {
        let context = container.viewContext
        let request: NSFetchRequest<WeightAndYardage> = WeightAndYardage.fetchRequest()
        request.predicate = NSPredicate(format: "weight == %@", "5 - Chunky")
        
        do {
            let items = try context.fetch(request)
            guard !items.isEmpty else { return }
            
            for item in items {
                item.weight = Weight.five.rawValue
            }
            try context.save()
        } catch {
            print("Failed to migrate legacy weight labels: \(error.localizedDescription)")
        }
    }
    
    /// Yarn.id is optional in the model; views and lookups rely on every yarn having one.
    private func assignMissingYarnIDs() {
        let context = container.viewContext
        let request: NSFetchRequest<Yarn> = Yarn.fetchRequest()
        request.predicate = NSPredicate(format: "id == nil")
        
        do {
            let yarns = try context.fetch(request)
            guard !yarns.isEmpty else { return }
            
            for yarn in yarns {
                yarn.id = UUID()
            }
            try context.save()
        } catch {
            print("Failed to assign missing yarn IDs: \(error.localizedDescription)")
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save failed: \(error.localizedDescription)")
            }
        }
    }
}
