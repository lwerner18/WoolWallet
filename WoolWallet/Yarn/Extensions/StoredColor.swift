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
    // Create a StoredColor instance from a SwiftUI Color
    static func from(color: Color, name: String, context: NSManagedObjectContext) -> StoredColor {
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        let newStoredColor = StoredColor(context: context)
        newStoredColor.red = Double(components[0])
        newStoredColor.green = Double(components[1])
        newStoredColor.blue = Double(components[2])
        newStoredColor.alpha = Double(components[3])
        newStoredColor.name = name
        return newStoredColor
    }
}
