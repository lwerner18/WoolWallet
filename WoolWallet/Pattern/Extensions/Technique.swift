//
//  Technique.swift
//  WoolWallet
//
//  Created by Mac on 11/14/24.
//

import Foundation
import SwiftUI
import CoreData

extension Technique {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Technique.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    static func from(techniqueItem: TechniqueItem, order: Int, context: NSManagedObjectContext) -> Technique {
        var technique : Technique
        
        if techniqueItem.existingItem != nil {
            technique = techniqueItem.existingItem!
        } else {
            technique = Technique(context: context)
        }
        
        technique.technique = techniqueItem.technique.rawValue
        technique.techniqueDescription = techniqueItem.description
        technique.order = Int16(order)
        
        return technique
    }
}
