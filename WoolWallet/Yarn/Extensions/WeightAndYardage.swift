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
    static func from(data: WeightAndYardageData, order: Int, context: NSManagedObjectContext) -> WeightAndYardage {
        let newWeightAndYardage = WeightAndYardage(context: context)
        
        newWeightAndYardage.weight            = data.weight.rawValue
        newWeightAndYardage.unitOfMeasure     = data.unitOfMeasure.rawValue
        newWeightAndYardage.yardage           = data.yardage ?? 0
        newWeightAndYardage.grams             = Int16(data.grams ?? 0)
        newWeightAndYardage.hasBeenWeighed    = Int16(data.hasBeenWeighed)
        newWeightAndYardage.totalGrams        = data.totalGrams ?? 0
        newWeightAndYardage.skeins            = data.skeins
        newWeightAndYardage.hasPartialSkein   = data.hasBeenWeighed == 0 ? data.hasPartialSkein : false
        newWeightAndYardage.exactLength       = data.hasBeenWeighed == 1 ? data.exactLength ?? 0 : 0
        newWeightAndYardage.approxLength      = (newWeightAndYardage.exactLength == 0 && data.yardage != nil) ? data.yardage! * data.skeins : 0
        newWeightAndYardage.parent            = data.parent.rawValue
        newWeightAndYardage.hasExactLength    = Int16(data.hasExactLength)
        newWeightAndYardage.order             = Int16(order)
        
        return newWeightAndYardage
    }
}
