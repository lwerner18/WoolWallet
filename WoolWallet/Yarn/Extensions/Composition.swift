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
        let newComposition = Composition(context: context)
        newComposition.id = compositionItem.id
        newComposition.percentage = Int16(compositionItem.percentage)
        newComposition.material = compositionItem.material
        return newComposition
    }
}

