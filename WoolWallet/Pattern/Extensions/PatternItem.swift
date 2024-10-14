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
    static func from(item: PatternItemField, order: Int, context: NSManagedObjectContext) -> PatternItem {
        let newPatternItem = PatternItem(context: context)
        
        newPatternItem.item = item.item.rawValue
        newPatternItem.itemDescription = item.description
        newPatternItem.order = Int16(order)
        
        return newPatternItem
    }
}
