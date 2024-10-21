//
//  PatternUtils.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import CoreData
import SwiftUI

struct ItemDisplay {
    var color : Color
    var custom : Bool = false
    var icon : String

}

// Array of letters
let letters: [String] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }

class PatternUtils {
    static let shared = PatternUtils()
    
    private init() {}
    
    func removePattern(at pattern: Pattern, with context: NSManagedObjectContext) {
        context.delete(pattern)
        
        PersistenceController.shared.save()
    }
    
    func getItemDisplay(for item: Item?) -> ItemDisplay {
        
        if item == nil || item == Item.none {
            return ItemDisplay(color: Color.gray.opacity(0.5), icon: "minus")
        }
        
        switch item {
        case .shirt         : return ItemDisplay(color: Color(hex : "#FFB3BA"), icon: "tshirt")
        case .sweater       : return ItemDisplay(color: Color(hex : "#FFA500"), custom: true, icon: "sweater")
        case .beanie        : return ItemDisplay(color: Color(hex : "#A6B65C"), custom: true, icon: "beanie")
        case .socks         : return ItemDisplay(color: Color(hex : "#C76A4D"), custom: true, icon: "sock")
        case .blanket       : return ItemDisplay(color: Color(hex : "#FFD2A6"), custom: true, icon: "blanket")
        case .scarf         : return ItemDisplay(color: Color(hex : "#6587B0"), custom: true, icon: "scarf")
        case .mittens       : return ItemDisplay(color: Color(hex : "#A7C9E8"), icon: "hand.raised")
        case .cardigan      : return ItemDisplay(color: Color(hex : "#B68BCE"), custom: true, icon: "cardigan")
        case .bag           : return ItemDisplay(color: Color(hex : "#76B2B8"), icon: "handbag")
        case .tankTop       : return ItemDisplay(color: Color(hex : "#B0E0E6"), custom: true, icon: "tanktop")
        case .householdItem : return ItemDisplay(color: Color(hex : "#DAA520"), icon: "house")
        default             : return ItemDisplay(color: Color(hex : "#E7D46E"), icon: "questionmark")
        }
    }
    
    func getLetter(for index: Int) -> String {
        if index > letters.count {
            return String(index)
        }
        
        return letters[index]
    }
}
