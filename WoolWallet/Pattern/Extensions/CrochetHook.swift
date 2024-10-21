//
//  CrochetHook.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

extension CrochetHook {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: CrochetHook.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    static func from(hook: Hook, order: Int, context: NSManagedObjectContext) -> CrochetHook {
        var crochetHook : CrochetHook
        
        if hook.existingItem != nil {
            crochetHook = hook.existingItem!
        } else {
            crochetHook = CrochetHook(context: context)
        }
        
        crochetHook.size = hook.hook.rawValue
        crochetHook.order = Int16(order)
        
        return crochetHook
    }
}

