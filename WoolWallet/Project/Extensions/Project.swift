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
        let pairingItems = pairings?.allObjects as? [ProjectPairing] ?? []
        
        let sortedPairings = pairingItems.sorted { $0.patternWeightAndYardage!.order < $1.patternWeightAndYardage!.order}
        
        return sortedPairings.map { pairing in
            return ProjectPairingItem(
                id : pairing.id!,
                patternWeightAndYardage : pairing.patternWeightAndYardage!,
                yarnWeightAndYardage : pairing.yarnWeightAndYardage!,
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
