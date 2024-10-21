//
//  Composition.swift
//  WoolWallet
//
//  Created by Mac on 9/18/24.
//

import Foundation
import CoreData

extension Composition {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Composition.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    // Create a StoredColor instance from a SwiftUI Color
    static func from(compositionItem : CompositionItem, context: NSManagedObjectContext) -> Composition {
        var composition : Composition
        
        if compositionItem.existingItem != nil {
            composition = compositionItem.existingItem!
        } else {
            composition = Composition(context: context)
        }
        
        composition.id = compositionItem.id
        composition.percentage = Int16(compositionItem.percentage)
        composition.material = compositionItem.material
        composition.materialDescription = compositionItem.materialDescription
        
        return composition
    }
}

