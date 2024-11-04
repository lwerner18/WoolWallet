//
//  Project.swift
//  WoolWallet
//
//  Created by Mac on 10/29/24.
//

import Foundation
import SwiftUI
import CoreData

extension Project {
    var uiImages: [ImageData] {
        let storedImages = images?.allObjects as? [StoredImage] ?? []
        
        let sortedImages = storedImages.sorted { $0.order < $1.order}
        
        return sortedImages.map { storedImage in
            return ImageData(
                id : storedImage.id!,
                image: UIImage(data: storedImage.image ?? Data())!,
                existingItem: storedImage
            )
        }
    }
    
    var projectPairingItems: [ProjectPairingItem] {
        let pairings = pairings?.allObjects as? [ProjectPairing] ?? []
        
        return pairings.map { pairing in
            return ProjectPairingItem(
                id : pairing.id!,
                patternWeightAndYardage : pairing.patternWeightAndYardage!,
                yarnWeightAndYardage : pairing.yarnWeightAndYardage!,
                existingItem: pairing
            )
        }
    }
    
    var rowCounterItems: [RowCounter] {
        return rowCounters?.allObjects as? [RowCounter] ?? []
    }
}
