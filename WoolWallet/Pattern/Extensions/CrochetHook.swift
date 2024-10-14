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
    static func from(size: String, order: Int, context: NSManagedObjectContext) -> CrochetHook {
        let newChrochetHook = CrochetHook(context: context)
        
        newChrochetHook.size = size
        newChrochetHook.order = Int16(order)
        
        return newChrochetHook
    }
}

