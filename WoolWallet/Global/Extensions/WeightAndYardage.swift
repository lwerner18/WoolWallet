//
//  WeightAndYardage.swift
//  WoolWallet
//
//  Created by Mac on 10/11/24.
//

import Foundation
import SwiftUI
import CoreData

extension WeightAndYardage {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: WeightAndYardage.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    static func from(data: WeightAndYardageData, order: Int, context: NSManagedObjectContext) -> WeightAndYardage {
        var weightAndYardage : WeightAndYardage
        
        if data.existingItem != nil {
            weightAndYardage = data.existingItem!
        } else {
            weightAndYardage = WeightAndYardage(context: context)
        }
        
        let updateOriginalLength = weightAndYardage.originalLength == 0 || weightAndYardage.originalLength == weightAndYardage.currentLength
        let updateOriginalSkeins = weightAndYardage.originalSkeins == 0 || weightAndYardage.originalSkeins == weightAndYardage.currentSkeins
   
        
        weightAndYardage.id                = data.id
        weightAndYardage.weight            = data.weight.rawValue
        weightAndYardage.unitOfMeasure     = data.unitOfMeasure.rawValue
        weightAndYardage.yardage           = data.yardage ?? 0
        weightAndYardage.grams             = Int16(data.grams ?? 0)
        weightAndYardage.hasBeenWeighed    = Int16(data.hasBeenWeighed)
        weightAndYardage.totalGrams        = data.totalGrams ?? 0
        weightAndYardage.currentLength     = data.length ?? 0
        weightAndYardage.currentSkeins     = data.skeins
        weightAndYardage.hasPartialSkein   = data.hasBeenWeighed == 0 ? data.hasPartialSkein : false
        weightAndYardage.parent            = data.parent.rawValue
        weightAndYardage.hasExactLength    = Int16(data.hasExactLength)
        weightAndYardage.order             = Int16(order)
        
        if updateOriginalLength {
            weightAndYardage.originalLength = weightAndYardage.currentLength
        }
        
        if updateOriginalSkeins {
            weightAndYardage.originalSkeins = weightAndYardage.currentSkeins
        }
        
        return weightAndYardage
    }
    
    var yarnPairingItems: [ProjectPairing] {
        return yarnPairings?.allObjects as? [ProjectPairing] ?? []
    }
    
    var availableLength : Double {
//        var yardsUsed = 0.0
//        
//        if currentLength == 0 {
//            return yardsUsed
//        }
//        
//        yarnPairingItems.forEach { pairing in
//            if pairing.project!.inProgress {
//                yardsUsed += pairing.patternWeightAndYardage!.currentLength
//            }
//        }
        
        let available = currentLength - yardsUsed
        
        return available < 0 ? 0 : available
    }
    
    var yardsUsed : Double {
        var yardsUsed = 0.0
        
        if currentLength == 0 {
            return yardsUsed
        }
        
        yarnPairingItems.forEach { pairing in
            if pairing.project!.inProgress {
                yardsUsed += pairing.patternWeightAndYardage!.currentLength
            }
        }
        
        return yardsUsed
    }
    
    var isExact: Bool {
        return hasBeenWeighed == 1 || hasExactLength == 1
    }
    
    // Static function to create the fetch request with propertiesToFetch
    static func fetchWeightsAndSkeins() -> NSFetchRequest<WeightAndYardage> {
        let request = NSFetchRequest<WeightAndYardage>(entityName: "WeightAndYardage")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightAndYardage.order, ascending: true)]
        
        // Specify the properties you want to fetch
        request.propertiesToFetch = ["weight", "currentSkeins"]
        request.resultType = .managedObjectResultType
        
        request.predicate = NSPredicate(format: "parent == %@", WeightAndYardageParent.yarn.rawValue)
        
        return request
    }
}
