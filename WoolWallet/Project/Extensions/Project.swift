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
        StoredImage.imageData(from: images, maxPixelSize: StoredImage.displayMaxPixelSize)
    }
    
    var hasImages: Bool {
        (images?.count ?? 0) > 0
    }
    
    var projectPairingItems: [ProjectPairingItem] {
        let pairingItems = pairings?.allObjects as? [ProjectPairing] ?? []
        
        let sortedPairings = pairingItems.sorted {
            ($0.patternWeightAndYardage?.order ?? 0) < ($1.patternWeightAndYardage?.order ?? 0)
        }
        
        return sortedPairings.compactMap { pairing in
            guard let id = pairing.id,
                  let patternWeightAndYardage = pairing.patternWeightAndYardage,
                  let yarnWeightAndYardage = pairing.yarnWeightAndYardage else {
                return nil
            }
            
            return ProjectPairingItem(
                id : id,
                patternWeightAndYardage : patternWeightAndYardage,
                yarnWeightAndYardage : yarnWeightAndYardage,
                lengthUsed: pairing.lengthUsed,
                existingItem: pairing
            )
        }
    }
    
    var rowCounterItems: [RowCounter] {
        return rowCounters?.allObjects as? [RowCounter] ?? []
    }
    
    // Static function to create the fetch request with propertiesToFetch
    static func fetchPartialRequest() -> NSFetchRequest<Project> {
        let request = NSFetchRequest<Project>(entityName: "Project")
        request.sortDescriptors = []
        
        // Specify the properties you want to fetch
        request.propertiesToFetch = ["inProgress", "complete"] // List properties to fetch
        request.resultType = .managedObjectResultType
        
        return request
    }
}
