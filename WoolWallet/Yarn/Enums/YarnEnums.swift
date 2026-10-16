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

enum YarnSort: String, CaseIterable, Identifiable {
    case name          = "Name"
    case recentlyAdded = "Recently Added"
    case dyer          = "Dyer"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .name:          return "textformat"
        case .recentlyAdded: return "clock"
        case .dyer:          return "person"
        }
    }
    
    var sortDescriptors: [NSSortDescriptor] {
        let byName = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        
        switch self {
        case .name:
            return [byName]
        case .recentlyAdded:
            // Yarn from before dates were tracked has none and goes last
            return [NSSortDescriptor(key: "dateAdded", ascending: false), byName]
        case .dyer:
            return [NSSortDescriptor(key: "dyer", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))), byName]
        }
    }
}

enum Weight : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case none  = "--"
    case zero  = "0 - Lace"
    case one   = "1 - Fingering"
    case two   = "2 - Sport"
    case three = "3 - DK"
    case four  = "4 - Worsted"
    case five  = "5 - Bulky"
    case six   = "6 - Super Bulky"
    case seven = "7 - Jumbo"
    
    /// Parses stored Core Data values, including the legacy "5 - Chunky" label.
    static func fromStored(_ value: String?) -> Weight {
        guard let value else { return .none }
        if let weight = Weight(rawValue: value) {
            return weight
        }
        if value == "5 - Chunky" {
            return .five
        }
        return .none
    }
    
    func getDisplay() -> String {
        switch self {
        case .none  : return ""
        case .zero  : return "Lace"
        case .one   : return "Fingering"
        case .two   : return "Sport"
        case .three : return "DK"
        case .four  : return "Worsted"
        case .five  : return "Bulky"
        case .six   : return "Super Bulky"
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
    case suri     = "Suri"
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
