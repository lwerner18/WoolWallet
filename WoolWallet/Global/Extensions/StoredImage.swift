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
    // Create a StoredColor instance from a SwiftUI Color
    static func from(image: UIImage, order: Int, context: NSManagedObjectContext) -> StoredImage {
        let newStoredImage = StoredImage(context: context)
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return newStoredImage
        }
        
        newStoredImage.image = imageData
        newStoredImage.order = Int16(order)
    
        return newStoredImage
    }
}
