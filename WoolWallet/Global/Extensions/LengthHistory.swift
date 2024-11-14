//
//  LengthHistory.swift
//  WoolWallet
//
//  Created by Mac on 11/11/24.
//

import Foundation
import SwiftUI
import CoreData

extension LengthHistory {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: LengthHistory.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
}
