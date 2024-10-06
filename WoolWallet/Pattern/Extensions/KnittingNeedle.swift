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
    static func from(size: String, context: NSManagedObjectContext) -> KnittingNeedle {
        let newKnittingNeedle = KnittingNeedle(context: context)
        
        newKnittingNeedle.size = size
        
        return newKnittingNeedle
    }
}

