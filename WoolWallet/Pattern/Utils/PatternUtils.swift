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
        pattern.hooks?.forEach                { context.delete($0 as! NSManagedObject) }
        pattern.images?.forEach               { context.delete($0 as! NSManagedObject) }
        pattern.items?.forEach                { context.delete($0 as! NSManagedObject) }
        pattern.needles?.forEach              { context.delete($0 as! NSManagedObject) }
        pattern.projects?.forEach             { context.delete($0 as! NSManagedObject) }
        pattern.recCompositions?.forEach      { context.delete($0 as! NSManagedObject) }
        
        pattern.recWeightAndYardages?.forEach {
            let item = $0 as! WeightAndYardage
            
            item.patternFavorites?.forEach{ context.delete($0 as! NSManagedObject) }
            
            context.delete(item)
        }
        
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
    
    // Function to join color names with commas
    func joinedItems(patternItems : [PatternItemField]) -> String {
        var itemsSet = Set<String>()
        
        for pattern in patternItems {
            if pattern.item == Item.other {
                if pattern.description != "" {
                    itemsSet.insert(pattern.description.lowercased())
                }
            } else if pattern.item != Item.none {
                itemsSet.insert(pattern.item.rawValue.lowercased())
            }
        }
        
        var items = Array(itemsSet)
        
        if items.isEmpty {
            return ""
        }
        
        if items.count == 1 && (items.first == Item.socks.rawValue.lowercased() || items.first == Item.mittens.rawValue.lowercased()) {
            return "Makes \(items.first!)"
        } else if items.count == 1 && !Item.allCases.contains(where: { $0.rawValue.lowercased() == items.first })  {
            return "Makes: \(items.first!)"
        } else if items.count == 1 {
            return "Makes a \(items.first!)"
        } else if items.count == 2 {
            return "Makes a \(items[0]) and \(items[1])"
        }
        
        let lastItem = items.removeLast()
        
        return "Makes \(items.joined(separator: ", ")), and \(lastItem)"
    }
    
    func getMatchingYarns(for weightAndYardage: WeightAndYardageData, in context: NSManagedObjectContext) -> [WeightAndYardage] {
        let fetchRequest: NSFetchRequest<WeightAndYardage> = WeightAndYardage.fetchRequest()
        
        var length = 0.0
        
        if weightAndYardage.exactLength != nil && weightAndYardage.exactLength! > 0 {
            length = weightAndYardage.exactLength!
        } else if weightAndYardage.approximateLength != nil && weightAndYardage.approximateLength! > 0 {
            length = weightAndYardage.approximateLength!
        }
        
        let allowedDeviation = 0.15
        var ratio = 0.0
        
        if weightAndYardage.yardage != nil && weightAndYardage.grams != nil {
            ratio = weightAndYardage.yardage! / Double(weightAndYardage.grams!)
        }
        
        // return empty list when length or ratio is 0
        if length == 0 || ratio == 0{
            return []
        }
        
        var predicates: [NSPredicate] = []
        
        // only yarn parents
        predicates.append(NSPredicate(format: "parent == %@", WeightAndYardageParent.yarn.rawValue))
        
        // weight filter
        predicates.append(NSPredicate(format: "weight == %@", weightAndYardage.weight.rawValue))
        
        // length filter
        predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "exactLength > 0 AND exactLength > %@", NSNumber(value: length)),
            NSPredicate(format: "approxLength > 0 AND approxLength > %@", NSNumber(value: length))
        ]))
        
        // ratio filter
        predicates.append(
            NSPredicate(
                format: "grams > 0 AND (yardage / grams >= %@) AND (yardage / grams <= %@)",
                NSNumber(value: ratio - allowedDeviation),
                NSNumber(value: ratio + allowedDeviation)
            )
        )
        
        // active filter
        predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "yarn.isArchived == %@", NSNumber(value: false)),
            NSPredicate(format: "yarn.isArchived == nil")
        ]))
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch matching yarns: \(error)")
            return []
        }
    }
}
