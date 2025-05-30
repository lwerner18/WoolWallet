//
//  YarnUtils.swift
//  WoolWallet
//
//  Created by Mac on 3/22/24.
//

import Foundation
import CoreData

class YarnUtils {
    static let shared = YarnUtils()
    
    private init() {}
    
    func getSkeinsText(skeins : Double) -> String {
        return "\(skeins.formatted) skein\(skeins > 1 ? "s" : "")"
    }
    
    func toggleYarnArchived(at yarn: Yarn) {
        yarn.isArchived = !yarn.isArchived
        
        PersistenceController.shared.save()
    }
    
    func removeYarn(at yarn: Yarn, with context: NSManagedObjectContext) {
        yarn.colors?.forEach            { context.delete($0 as! NSManagedObject) }
        yarn.composition?.forEach       { context.delete($0 as! NSManagedObject) }
        yarn.images?.forEach            { context.delete($0 as! NSManagedObject) }
            // delete projects with this yarn in a pairing
        
        yarn.weightAndYardages?.forEach {
            let item = $0 as! WeightAndYardage
            
            item.yarnFavorites?.forEach{context.delete($0 as! NSManagedObject) }
            item.yarnPairings?.forEach{context.delete($0 as! NSManagedObject) }
            
            context.delete(item)
        }
        
        
        context.delete(yarn)
        
        do {
            try PersistenceController.shared.save()
        } catch {
            // Handle the error appropriately.
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    func getMaterial(item : CompositionItem) -> String {
        return item.material != MaterialCategory.other.rawValue ? item.material : item.materialDescription
    }
    
    func getMatchingPatterns(for weightAndYardage: WeightAndYardageData, in context: NSManagedObjectContext) -> [WeightAndYardage] {
        let fetchRequest: NSFetchRequest<WeightAndYardage> = WeightAndYardage.fetchRequest()
        
        let allowedDeviation = 0.15
        let availableLength = weightAndYardage.existingItem!.availableLength
        var ratio = 0.0
        
        if weightAndYardage.yardage != nil && weightAndYardage.grams != nil {
            ratio = weightAndYardage.yardage! / Double(weightAndYardage.grams!)
        }
        
        // return empty list when length or ratio is 0
        if availableLength == 0 || ratio == 0 {
            return []
        }
        
        var predicates: [NSPredicate] = []
        
        // only yarn parents
        predicates.append(NSPredicate(format: "parent == %@", WeightAndYardageParent.pattern.rawValue))
        
        // weight filter
        predicates.append(NSPredicate(format: "weight == %@", weightAndYardage.weight.rawValue))
        
        predicates.append(NSPredicate(format: "currentLength > 0 AND currentLength <= %@", NSNumber(value: availableLength)))
        
        // ratio filter
        predicates.append(
            NSPredicate(
                format: "grams > 0 AND (yardage / grams >= %@) AND (yardage / grams <= %@)",
                NSNumber(value: ratio - allowedDeviation),
                NSNumber(value: ratio + allowedDeviation)
            )
        )
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch matching patterns: \(error)")
            return []
        }
    }
    
    func favoritedPatterns(for yarn : Yarn, in context: NSManagedObjectContext) -> [FavoritePairing] {
        let favoritesRequest: NSFetchRequest<FavoritePairing> = FavoritePairing.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        yarn.weightAndYardageItems.forEach { element in
            predicates.append(NSPredicate(format: "yarnWeightAndYardage.id == %@", element.id as any CVarArg))
        }
        
        favoritesRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        do {
            return try context.fetch(favoritesRequest)
        } catch {
            print("Failed to fetch favorites: \(error)")
            return []
        }
    }
    
    func getProjects(for yarn : Yarn, in context: NSManagedObjectContext) -> [Project] {
        let projectsRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        yarn.weightAndYardageItems.forEach { element in
            predicates.append(NSPredicate(format: "ANY pairings.yarnWeightAndYardage.id == %@", element.id as any CVarArg))
        }
        
        projectsRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        do {
            return try context.fetch(projectsRequest)
        } catch {
            print("Failed to fetch projects: \(error)")
            return []
        }
    }
}
