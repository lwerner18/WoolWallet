//
//  FavoritePairing.swift
//  WoolWallet
//
//  Created by Mac on 10/28/24.
//

import Foundation
import SwiftUI
import CoreData

extension FavoritePairing {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: FavoritePairing.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
}

