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
        stampDatesOnSave()
    }
    
    /// Records when yarn, patterns and projects are added and last changed, counting changes to their own details
    /// (colors, photos, amounts, row counters...) as changes to them. Runs after the startup fixes so those don't count.
    private func stampDatesOnSave() {
        let context = container.viewContext
        
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextWillSave, object: context, queue: nil) { _ in
            let now = Date()
            var changed: [NSManagedObjectID: any Timestamped] = [:]
            
            for case let object as any Timestamped in context.insertedObjects {
                if object.dateAdded == nil {
                    object.dateAdded = now
                }
                object.dateUpdated = now
            }
            
            for object in context.updatedObjects {
                let changedKeys = Set(object.changedValues().keys)
                
                if let object = object as? any Timestamped {
                    if !changedKeys.subtracting(Self.keysNotCountedAsChanges).isEmpty {
                        changed[object.objectID] = object
                    }
                } else if let owner = Self.owner(of: object), !owner.isInserted, !owner.isDeleted,
                          // Links to other entities, like a skein's favorites, aren't changes to the yarn itself
                          !changedKeys.isDisjoint(with: object.entity.attributesByName.keys) {
                    changed[owner.objectID] = owner
                }
            }
            
            for object in changed.values {
                object.dateUpdated = now
            }
        }
    }
    
    /// Starting a project from a pattern links it to the pattern, but doesn't change the pattern
    private static let keysNotCountedAsChanges: Set<String> = ["dateAdded", "dateUpdated", "projects"]
    
    private static func owner(of object: NSManagedObject) -> (any Timestamped)? {
        switch object {
        case let item as StoredColor:      return item.yarn
        case let item as Composition:      return item.yarn as (any Timestamped)? ?? item.pattern
        case let item as WeightAndYardage: return item.yarn as (any Timestamped)? ?? item.pattern
        case let item as StoredImage:      return item.yarn as (any Timestamped)? ?? item.pattern ?? item.project
        case let item as CrochetHook:      return item.pattern
        case let item as KnittingNeedle:   return item.pattern
        case let item as Notion:           return item.pattern
        case let item as PatternItem:      return item.pattern
        case let item as Technique:        return item.pattern
        case let item as ProjectPairing:   return item.project
        case let item as RowCounter:       return item.project
        default:                           return nil
        }
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

protocol Timestamped: NSManagedObject {
    var dateAdded: Date? { get set }
    var dateUpdated: Date? { get set }
}

extension Yarn: Timestamped {}
extension Pattern: Timestamped {}
extension Project: Timestamped {}
