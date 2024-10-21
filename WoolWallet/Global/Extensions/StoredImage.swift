//
//  StoredImage.swift
//  WoolWallet
//
//  Created by Mac on 9/25/24.
//

import Foundation
import SwiftUI
import CoreData

extension StoredImage {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: StoredImage.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    // Create a StoredColor instance from a SwiftUI Color
    static func from(data: ImageData, order: Int, context: NSManagedObjectContext) -> StoredImage {
        var storedImage : StoredImage
        
        if data.existingItem != nil {
            storedImage = data.existingItem!
        } else {
            storedImage = StoredImage(context: context)
        }
        
        guard let imageData = data.image.jpegData(compressionQuality: 1.0) else {
            return storedImage
        }
        
        storedImage.image = imageData
        storedImage.order = Int16(order)
    
        return storedImage
    }
}
