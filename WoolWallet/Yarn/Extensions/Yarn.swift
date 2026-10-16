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
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Yarn.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
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
        StoredImage.imageData(from: images, maxPixelSize: StoredImage.displayMaxPixelSize)
    }
    
    var hasImages: Bool {
        (images?.count ?? 0) > 0
    }
    
    /// Yarn colors sorted by name so list cards don't reshuffle swatches
    var sortedYarnColors: [Color] {
        colorPickerItems.sorted { $0.name < $1.name }.map(\.color)
    }
    
    /// Short weight label for list cards, e.g. "DK"
    var primaryWeightLabel: String? {
        guard let weight = weightAndYardageArray.first.map({ Weight.fromStored($0.weight) }) else { return nil }
        let label = weight.getDisplay()
        return label.isEmpty ? nil : label
    }
    
    var weightAndYardageItems: [WeightAndYardageData] {
        return weightAndYardageArray.map { item in
            return WeightAndYardageData(
                id                : item.id!,
                weight            : Weight.fromStored(item.weight),
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
    
    /// Form data for duplicating a yarn: new IDs, no Core Data links, full original amounts.
    var weightAndYardageItemsForCopy: [WeightAndYardageData] {
        return weightAndYardageArray.map { item in
            let fullLength = item.originalLength != 0 ? item.originalLength : item.currentLength
            let fullSkeins = item.originalSkeins != 0 ? item.originalSkeins : item.currentSkeins
            
            return WeightAndYardageData(
                id                : UUID(),
                weight            : Weight.fromStored(item.weight),
                unitOfMeasure     : item.unitOfMeasure != nil ? UnitOfMeasure(rawValue: item.unitOfMeasure!)! : UnitOfMeasure.yards,
                yardage           : item.yardage != 0 ? item.yardage : nil,
                grams             : item.grams != 0 ? Int(item.grams) : nil,
                hasBeenWeighed    : 0,
                totalGrams        : nil,
                skeins            : fullSkeins,
                hasPartialSkein   : false,
                length            : fullLength,
                parent            : WeightAndYardageParent(rawValue: item.parent!)!,
                hasExactLength    : Int(item.hasExactLength),
                existingItem      : nil
            )
        }
    }
    
    var compositionItemsForCopy: [CompositionItem] {
        compositionItems.map { item in
            CompositionItem(
                id: UUID(),
                percentage: item.percentage,
                material: item.material,
                materialDescription: item.materialDescription,
                existingItem: nil
            )
        }
    }
    
    var colorPickerItemsForCopy: [ColorPickerItem] {
        let items = colorPickerItems
        if items.isEmpty {
            return [ColorPickerItem(color: Color.white, name: "White")]
        }
        
        return items.map { item in
            ColorPickerItem(
                id: UUID(),
                color: item.color,
                name: item.name,
                description: item.description,
                existingItem: nil
            )
        }
    }
    
    var weightAndYardageArray : [WeightAndYardage] {
        let weightsAndYardages = weightAndYardages?.allObjects as? [WeightAndYardage] ?? []
        
        return weightsAndYardages.sorted { $0.order < $1.order}
    }
    
    /// Adds newly bought skeins of this same yarn. A sock set gains whole sets, so each of its skeins goes up.
    func addSkeins(_ count: Double) {
        var items = weightAndYardageArray
        
        // Yarn saved without any amounts still needs somewhere to count its skeins
        if items.isEmpty, let context = managedObjectContext {
            let item = WeightAndYardage(context: context)
            item.parent = WeightAndYardageParent.yarn.rawValue
            item.weight = Weight.none.rawValue
            item.unitOfMeasure = UnitOfMeasure.yards.rawValue
            item.hasExactLength = -1
            item.yarn = self
            items = [item]
        }
        
        for item in isSockSet ? items : Array(items.prefix(1)) {
            item.currentSkeins += count
            // An original of 0 was never recorded, and from() treats that as the current amount
            item.originalSkeins = item.originalSkeins == 0 ? item.currentSkeins : item.originalSkeins + count
            
            if item.yardage > 0 {
                let addedLength = item.yardage * count
                item.currentLength += addedLength
                item.originalLength = item.originalLength == 0 ? item.currentLength : item.originalLength + addedLength
            }
            
            if item.hasBeenWeighed == 1 && item.grams > 0 {
                item.totalGrams += Double(item.grams) * count
            }
        }
        
        // Yarn is archived automatically once it's used up
        if isArchived {
            isArchived = false
        }
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
