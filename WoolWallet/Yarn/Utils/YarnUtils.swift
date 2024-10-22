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
        let formattedSkeins = GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: skeins)) ?? "1"
        
        return "\(formattedSkeins) skein\(skeins > 1 ? "s" : "")"
    }
    
    func toggleYarnArchived(at yarn: Yarn) {
        yarn.isArchived = !yarn.isArchived
        
        PersistenceController.shared.save()
    }
    
    func removeYarn(at yarn: Yarn, with context: NSManagedObjectContext) {
        context.delete(yarn)
        
        PersistenceController.shared.save()
    }
    
    func getMaterial(item : CompositionItem) -> String {
        return item.material != MaterialCategory.other.rawValue ? item.material : item.materialDescription
    }
    
    func getMatchingPatterns(for weightAndYardage: WeightAndYardageData, in context: NSManagedObjectContext) -> [WeightAndYardage] {
        let fetchRequest: NSFetchRequest<WeightAndYardage> = WeightAndYardage.fetchRequest()
        
        var length = 0.0
        
        if weightAndYardage.exactLength != nil && weightAndYardage.exactLength! > 0 {
            length = weightAndYardage.exactLength!
        } else if weightAndYardage.approximateLength != nil && weightAndYardage.approximateLength! > 0 {
            length = weightAndYardage.approximateLength!
        }
        
        let allowedDeviation = 0.15
        var ratio = 0.0
        
        if weightAndYardage.yardage != nil && weightAndYardage.grams != nil {
            ratio = weightAndYardage.yardage! / Double(weightAndYardage.grams!)
        }
        
        // return empty list when length or ratio is 0
        if length == 0 || ratio == 0 {
            return []
        }
        
        var predicates: [NSPredicate] = []
        
        // only yarn parents
        predicates.append(NSPredicate(format: "parent == %@", WeightAndYardageParent.pattern.rawValue))
        
        // weight filter
        predicates.append(NSPredicate(format: "weight == %@", weightAndYardage.weight.rawValue))
        
        // length filter
        predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "exactLength > 0 AND exactLength < %@", NSNumber(value: length)),
            NSPredicate(format: "approxLength > 0 AND approxLength < %@", NSNumber(value: length))
        ]))
        
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
}
