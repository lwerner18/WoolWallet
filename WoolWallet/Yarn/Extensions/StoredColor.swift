//
//  StoredColor.swift
//  WoolWallet
//
//  Created by Mac on 8/20/24.
//

import Foundation
import SwiftUI
import CoreData

extension StoredColor {
    
    static func from(data: ColorPickerItem, context: NSManagedObjectContext) -> StoredColor {
        let components = data.color.cgColor?.components ?? [0, 0, 0, 1]
        
        var storedColor : StoredColor
        
        if data.existingItem != nil {
            storedColor = data.existingItem!
        } else {
            storedColor = StoredColor(context: context)
        }
        
        storedColor.red = Double(components[0])
        storedColor.green = Double(components[1])
        storedColor.blue = Double(components[2])
        storedColor.alpha = Double(components[3])
        storedColor.name = data.name
        
        return storedColor
    }
}
