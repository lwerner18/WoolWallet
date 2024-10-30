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
                id : patternItem.id!,
                item: Item(rawValue: patternItem.item!)!,
                description: patternItem.itemDescription!,
                existingItem: patternItem
            )
        }
    }
    
    var crochetHooks: [Hook] {
        let crochetHooks = hooks?.allObjects as? [CrochetHook] ?? []
        
        let sortedHooks = crochetHooks.sorted { $0.order < $1.order}
        
        return sortedHooks.map { hook in
            return Hook(
                id: hook.id!,
                hook: CrochetHookSize(rawValue: hook.size!)!,
                existingItem: hook
            )
        }
    }
    
    var knittingNeedles: [Needle] {
        let knittingNeedles = needles?.allObjects as? [KnittingNeedle] ?? []
        
        let sortedNeedles = knittingNeedles.sorted { $0.order < $1.order}
        
        return sortedNeedles.map { needle in
            return Needle(
                id: needle.id!,
                needle: KnitNeedleSize(rawValue: needle.size!)!,
                existingItem: needle
            )
        }
    }
    
    var weightAndYardageItems: [WeightAndYardageData] {
        let weightsAndYardages = recWeightAndYardages?.allObjects as? [WeightAndYardage] ?? []
        
        let sortedWeightsAndYardages = weightsAndYardages.sorted { $0.order < $1.order}
        
        return sortedWeightsAndYardages.map { item in
            return WeightAndYardageData(
                id                : item.id!,
                weight            : item.weight != nil ? Weight(rawValue: item.weight!)! : Weight.none,
                unitOfMeasure     : item.unitOfMeasure != nil ? UnitOfMeasure(rawValue: item.unitOfMeasure!)! : UnitOfMeasure.yards,
                yardage           : item.yardage != 0 ? item.yardage : nil,
                grams             : item.grams != 0 ? Int(item.grams) : nil,
                hasBeenWeighed    : Int(item.hasBeenWeighed),
                totalGrams        : item.totalGrams != 0 ? item.totalGrams : nil,
                skeins            : item.skeins,
                hasPartialSkein   : item.hasPartialSkein,
                exactLength       : item.exactLength != 0 ? item.exactLength : nil,
                approximateLength : item.approxLength != 0 ? item.approxLength : nil,
                parent            : WeightAndYardageParent(rawValue: item.parent!)!,
                hasExactLength    : Int(item.hasExactLength),
                existingItem      : item
            )
        }
    }
    
    var uiImages: [ImageData] {
        let storedImages = images?.allObjects as? [StoredImage] ?? []
        
        let sortedImages = storedImages.sorted { $0.order < $1.order}
        
        return sortedImages.map { storedImage in
            return ImageData(
                id : storedImage.id!,
                image: UIImage(data: storedImage.image ?? Data())!,
                existingItem: storedImage
            )
        }
    }
}
