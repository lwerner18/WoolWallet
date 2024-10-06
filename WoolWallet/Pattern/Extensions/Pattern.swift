//
//  Pattern.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI

extension Pattern {
    var patternItems: [Item] {
        let patternItems = items?.allObjects as? [PatternItem] ?? []
        
        return patternItems.map { patternItem in
            return Item(rawValue: patternItem.item!)!
        }
    }
}
