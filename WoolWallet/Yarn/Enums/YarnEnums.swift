//
//  Enums.swift
//  WoolWallet
//
//  Created by Mac on 9/25/24.
//

import Foundation

enum YarnTab : String, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case active = "Active"
    case archived = "Archived"
}

enum Weight : String, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case none = "--"
    case zero = "0 - Lace"
    case one = "1 - Fingering"
    case two = "2 - Sport"
    case three = "3 - DK"
    case four = "4 - Worsted"
    case five = "5 - Chunky"
    case six = "6 - Super Bulky"
    case seven = "7 - Jumbo"
}

enum UnitOfMeasure : String, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case yards = "Yards"
    case meters = "Meters"
}
