//
//  CrochetHook.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

extension KnittingNeedle {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: KnittingNeedle.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    static func from(needle: Needle, order: Int, context: NSManagedObjectContext) -> KnittingNeedle {
        var knittingNeedle : KnittingNeedle
        
        if needle.existingItem != nil {
            knittingNeedle = needle.existingItem!
        } else {
            knittingNeedle = KnittingNeedle(context: context)
        }
        
        knittingNeedle.size = needle.needle.rawValue
        knittingNeedle.order = Int16(order)
        
        return knittingNeedle
    }
}

