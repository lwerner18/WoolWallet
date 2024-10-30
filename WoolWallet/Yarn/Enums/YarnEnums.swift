//
//  Enums.swift
//  WoolWallet
//
//  Created by Mac on 9/25/24.
//

import Foundation

enum YarnTab : String, CaseIterable, Identifiable, Equatable, CustomStringConvertible {
    var id: String { self.rawValue }
    
    case active = "Active"
    case archived = "Archived"
    
    // CustomStringConvertible
    var description: String {
        self.rawValue
    }
}

enum Weight : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case none = "--"
    case zero = "0 - Lace"
    case one = "1 - Fingering"
    case two = "2 - Sport"
    case three = "3 - DK"
    case four = "4 - Worsted"
    case five = "5 - Chunky"
    case six = "6 - Super Bulky"
    case seven = "7 - Jumbo"
    
    func getDisplay() -> String {
        switch self {
        case .none : return ""
        case .zero : return "Lace"
        case .one : return "Fingering"
        case .two : return "Sport"
        case .three : return "DK"
        case .four : return "Worsted"
        case .five : return "Chunky"
        case .six : return "Super Bulky"
        case .seven : return "Jumbo"
        }
    }
}

enum UnitOfMeasure : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case yards = "Yards"
    case meters = "Meters"
}


enum MaterialCategory : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case wool     = "Wool"
    case alpaca   = "Alpaca"
    case cashmere = "Cashmere"
    case mohair   = "Mohair"
    case cotton   = "Cotton"
    case linen    = "Linen"
    case bamboo   = "Bamboo"
    case silk     = "Silk"
    case acrylic  = "Acrylic"
    case nylon    = "Nylon"
    case rayon    = "Rayon"
    case other    = "Other"
}

enum ColorType : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case tonal = "Tonal"
    case variegated = "Variegated"
}
