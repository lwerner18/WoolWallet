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
        
        if let description = container.persistentStoreDescriptions.first {
            // Keep existing installs opening after lightweight model changes
            // (new optional attributes, new entities). Without this, a store
            // load failure used to fatalError and look like a launch crash.
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        
        loadStores(allowRecovery: !inMemory)
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        migrateLegacyWeightLabels()
        assignMissingYarnIDs()
        stampDatesOnSave()
    }
    
    /// Loads the store. If an existing install can't migrate, deletes the
    /// incompatible file once and retries so the app still launches for review
    /// and for users — better than crashing on every open.
    private func loadStores(allowRecovery: Bool) {
        var loadError: NSError?
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                loadError = error
            }
        }
        
        guard let error = loadError else { return }
        
        print("Core Data failed to load: \(error), \(error.userInfo)")
        
        guard allowRecovery,
              let storeURL = container.persistentStoreDescriptions.first?.url else {
            // Previews / in-memory: nothing to recover
            assertionFailure("Core Data store failed to load: \(error)")
            return
        }
        
        print("Attempting Core Data recovery by resetting the store at \(storeURL)")
        removeStoreFiles(at: storeURL)
        
        var retryError: NSError?
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                retryError = error
            }
        }
        
        if let retryError {
            // Still unusable — log loudly but do not abort the process.
            // Views will see an empty context rather than a hard launch crash.
            print("Core Data recovery failed: \(retryError), \(retryError.userInfo)")
            assertionFailure("Core Data recovery failed: \(retryError)")
        }
    }
    
    private func removeStoreFiles(at url: URL) {
        let fileManager = FileManager.default
        // SQLite sidecar files sit beside the store as path-shm / path-wal
        let candidates = [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal")
        ]
        
        for fileURL in candidates {
            guard fileManager.fileExists(atPath: fileURL.path) else { continue }
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Failed to remove store file \(fileURL.lastPathComponent): \(error)")
            }
        }
    }
    
    /// Records when yarn, patterns and projects are added and last changed, counting changes to their own details
    /// (colors, photos, amounts, pairings...) as changes to them. Row-counter ticks are excluded so every +1
    /// doesn't rewrite the project's Updated date. Runs after the startup fixes so those don't count.
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
        case let item as PatternDocument:  return item.pattern
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
    
    /// Returns `false` when the store rejected the change (context is rolled back).
    @discardableResult
    func save() -> Bool {
        let context = container.viewContext
        
        guard context.hasChanges else { return true }
        
        do {
            try context.save()
            return true
        } catch {
            // Leave the UI consistent with the store — a failed delete used to look gone until relaunch
            print("Core Data save failed: \(error)")
            if let details = (error as NSError).userInfo["NSDetailedErrors"] as? [NSError] {
                details.forEach { print("  \($0.localizedDescription) \($0.userInfo)") }
            }
            context.rollback()
            return false
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
