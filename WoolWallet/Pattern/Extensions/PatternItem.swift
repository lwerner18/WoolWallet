//
//  PatternItem.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

extension PatternItem {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: PatternItem.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    static func from(item: PatternItemField, order: Int, context: NSManagedObjectContext) -> PatternItem {
        var patternItem : PatternItem
        
        if item.existingItem != nil {
            patternItem = item.existingItem!
        } else {
            patternItem = PatternItem(context: context)
        }
        
        patternItem.item = item.item.rawValue
        patternItem.itemDescription = item.description
        patternItem.order = Int16(order)
        
        return patternItem
    }
    
    // Static function to create the fetch request with propertiesToFetch
    static func fetchItems() -> NSFetchRequest<PatternItem> {
        let request = NSFetchRequest<PatternItem>(entityName: "PatternItem")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternItem.item, ascending: true)]
        
        // Specify the properties you want to fetch
        request.propertiesToFetch = ["item"]
        request.resultType = .managedObjectResultType
        
        return request
    }
}
