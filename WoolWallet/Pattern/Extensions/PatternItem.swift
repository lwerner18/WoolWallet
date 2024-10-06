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
    static func from(item: String, context: NSManagedObjectContext) -> PatternItem {
        let newPatternItem = PatternItem(context: context)
        
        newPatternItem.item = item
        
        return newPatternItem
    }
}
