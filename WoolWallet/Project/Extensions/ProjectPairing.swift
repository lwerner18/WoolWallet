//
//  ProjectPairing.swift
//  WoolWallet
//
//  Created by Mac on 10/29/24.
//

import Foundation
import SwiftUI
import CoreData

extension ProjectPairing {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: ProjectPairing.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    static func from(data: ProjectPairingItem, context: NSManagedObjectContext) -> ProjectPairing {
        var pairing : ProjectPairing
        
        if data.existingItem != nil {
            pairing = data.existingItem!
        } else {
            pairing = ProjectPairing(context: context)
        }
        
        pairing.patternWeightAndYardage = data.patternWeightAndYardage
        pairing.yarnWeightAndYardage = data.yarnWeightAndYardage
        
        return pairing
    }
}
