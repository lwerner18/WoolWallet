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
   
        
        weightAndYardage.id                = data.id != nil ? data.id : UUID()
        weightAndYardage.weight            = data.weight.rawValue
        weightAndYardage.unitOfMeasure     = data.unitOfMeasure.rawValue
        weightAndYardage.yardage           = data.yardage ?? 0
        weightAndYardage.grams             = Int16(data.grams ?? 0)
        weightAndYardage.hasBeenWeighed    = Int16(data.hasBeenWeighed)
        weightAndYardage.totalGrams        = data.totalGrams ?? 0
        weightAndYardage.skeins            = data.skeins
        weightAndYardage.hasPartialSkein   = data.hasBeenWeighed == 0 ? data.hasPartialSkein : false
        weightAndYardage.exactLength       = data.exactLength ?? 0
        weightAndYardage.approxLength      = weightAndYardage.exactLength == 0 ? data.approximateLength ?? 0 : 0
        weightAndYardage.parent            = data.parent.rawValue
        weightAndYardage.hasExactLength    = Int16(data.hasExactLength)
        weightAndYardage.order             = Int16(order)
        
        return weightAndYardage
    }
}
