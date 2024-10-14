//
//  Pattern.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

extension Pattern {
    var patternItems: [PatternItemField] {
        let patternItems = items?.allObjects as? [PatternItem] ?? []
        
        let sortedItems = patternItems.sorted { $0.order < $1.order}
        
        return sortedItems.map { patternItem in
            return PatternItemField(
                item: Item(rawValue: patternItem.item!)!,
                description: patternItem.itemDescription!
            )
        }
    }
    
    var crochetHooks: [CrochetHookSize] {
        let crochetHooks = hooks?.allObjects as? [CrochetHook] ?? []
        
        let sortedHooks = crochetHooks.sorted { $0.order < $1.order}
        
        return sortedHooks.map { hook in
            return CrochetHookSize(rawValue: hook.size!)!
        }
    }
    
    func matchingYarns(in context: NSManagedObjectContext) -> [Yarn] {
        let fetchRequest: NSFetchRequest<Yarn> = Yarn.fetchRequest()
        
        return []
        
//        // Set a predicate to filter yarns based on composition weights
//        fetchRequest.predicate = NSPredicate(format: "ANY weight == %@", self.recWeight ?? "")
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch matching yarns: \(error)")
            return []
        }
    }
    
    var weightAndYardageItems: [WeightAndYardageData] {
        let weightsAndYardages = recWeightAndYardages?.allObjects as? [WeightAndYardage] ?? []
        
        let sortedWeightsAndYardages = weightsAndYardages.sorted { $0.order < $1.order}
        
        return sortedWeightsAndYardages.map { item in
            return WeightAndYardageData(
                weight            : item.weight != nil ? Weight(rawValue: item.weight!)! : Weight.none,
                unitOfMeasure     : item.unitOfMeasure != nil ? UnitOfMeasure(rawValue: item.unitOfMeasure!)! : UnitOfMeasure.yards,
                yardage           : item.yardage != 0 ? item.yardage : nil,
                grams             : item.grams != 0 ? Int(item.grams) : nil,
                hasBeenWeighed    : Int(item.hasBeenWeighed),
                totalGrams        : item.totalGrams != 0 ? item.totalGrams : nil,
                skeins            : item.skeins,
                hasPartialSkein   : item.hasPartialSkein,
                exactLength       : item.exactLength,
                approximateLength : item.approxLength,
                parent            : WeightAndYardageParent(rawValue: item.parent!)!,
                hasExactLength    : Int(item.hasExactLength)
            )
        }
    }
}
