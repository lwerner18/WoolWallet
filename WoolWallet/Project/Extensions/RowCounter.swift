//
//  RowCounter.swift
//  WoolWallet
//
//  Created by Mac on 10/31/24.
//

import Foundation
import CoreData

extension RowCounter {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: RowCounter.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
}
