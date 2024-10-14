//
//  Yarn.swift
//  WoolWallet
//
//  Created by Mac on 8/21/24.
//

import Foundation
import SwiftUI

extension Yarn {
    var colorPickerItems: [ColorPickerItem] {
        let storedColors = colors?.allObjects as? [StoredColor] ?? []
        
        return storedColors.map { storedColor in
            let color = Color(
                red: storedColor.red,
                green: storedColor.green,
                blue: storedColor.blue,
                opacity: storedColor.alpha
            )
            
            return ColorPickerItem(color: color, name: storedColor.name!)
        }
    }
    
    var compositionItems: [CompositionItem] {
        let compositions = composition?.allObjects as? [Composition] ?? []
        
        return compositions.map { composition in
            return CompositionItem(
                percentage: Int(composition.percentage),
                material: composition.material!,
                materialDescription: composition.materialDescription!
            )
        }
    }
    
    var uiImages: [UIImage] {
        let storedImages = images?.allObjects as? [StoredImage] ?? []
        
        let sortedImages = storedImages.sorted { $0.order < $1.order}
        
        return sortedImages.map { storedImage in
            return UIImage(data: storedImage.image ?? Data())!
        }
    }
    
    var weightAndYardageItems: [WeightAndYardageData] {
        let weightsAndYardages = weightAndYardages?.allObjects as? [WeightAndYardage] ?? []
        
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
