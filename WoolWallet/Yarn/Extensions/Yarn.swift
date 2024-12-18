//
//  Yarn.swift
//  WoolWallet
//
//  Created by Mac on 8/21/24.
//

import Foundation
import SwiftUI
import CoreData

extension Yarn {
    var colorPickerItems: [ColorPickerItem] {
        let storedColors = colors?.allObjects as? [StoredColor] ?? []
        
        return storedColors.map { item in
            let color = Color(
                red: item.red,
                green: item.green,
                blue: item.blue,
                opacity: item.alpha
            )
            
            return ColorPickerItem(
                id: item.id!,
                color: color,
                name: item.name!,
                description : item.colorDescription ?? "",
                existingItem: item
            )
        }
    }
    
    var compositionItems: [CompositionItem] {
        let compositions = composition?.allObjects as? [Composition] ?? []
        
        return compositions.map { composition in
            return CompositionItem(
                id : composition.id!,
                percentage: Int(composition.percentage),
                material: composition.material!,
                materialDescription: composition.materialDescription!,
                existingItem: composition
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
    
    var weightAndYardageItems: [WeightAndYardageData] {
        return weightAndYardageArray.map { item in
            return WeightAndYardageData(
                id                : item.id!,
                weight            : item.weight != nil ? Weight(rawValue: item.weight!)! : Weight.none,
                unitOfMeasure     : item.unitOfMeasure != nil ? UnitOfMeasure(rawValue: item.unitOfMeasure!)! : UnitOfMeasure.yards,
                yardage           : item.yardage != 0 ? item.yardage : nil,
                grams             : item.grams != 0 ? Int(item.grams) : nil,
                hasBeenWeighed    : Int(item.hasBeenWeighed),
                totalGrams        : item.totalGrams != 0 ? item.totalGrams : nil,
                skeins            : item.currentSkeins,
                hasPartialSkein   : item.hasPartialSkein,
                length            : item.currentLength,
                parent            : WeightAndYardageParent(rawValue: item.parent!)!,
                hasExactLength    : Int(item.hasExactLength),
                existingItem      : item
            )
        }
    }
    
    var weightAndYardageArray : [WeightAndYardage] {
        let weightsAndYardages = weightAndYardages?.allObjects as? [WeightAndYardage] ?? []
        
        return weightsAndYardages.sorted { $0.order < $1.order}
    }
    
    // Static function to create the fetch request with propertiesToFetch
    static func fetchPartialRequest() -> NSFetchRequest<Yarn> {
        let request = NSFetchRequest<Yarn>(entityName: "Yarn")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Yarn.dyer, ascending: true)]
        
        // Specify the properties you want to fetch
        request.propertiesToFetch = ["dyer", "isArchived"] // List properties to fetch
        request.resultType = .managedObjectResultType
        
        return request
    }
}
