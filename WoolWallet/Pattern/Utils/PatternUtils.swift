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
        pattern.techniques?.forEach           { context.delete($0 as! NSManagedObject) }
        pattern.notions?.forEach              { context.delete($0 as! NSManagedObject) }
        
        pattern.recWeightAndYardages?.forEach {
            let item = $0 as! WeightAndYardage
            
            item.patternFavorites?.forEach{ context.delete($0 as! NSManagedObject) }
            
            context.delete(item)
        }
        
        context.delete(pattern)
        
        do {
            try PersistenceController.shared.save()
        } catch {
            // Handle the error appropriately.
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    func getItemDisplay(for item: Item?) -> ItemDisplay {
        
        if item == nil || item == Item.none {
            return ItemDisplay(color: Color.gray.opacity(0.5), icon: "minus")
        }
        
        switch item {
        case .shirt     : return ItemDisplay(color: Color(hex : "#FFB3BA"), icon: "tshirt")
        case .sweater   : return ItemDisplay(color: Color(hex : "#FFA500"), custom: true, icon: "sweater")
        case .shawl     : return ItemDisplay(color: Color(hex : "#A9C78A"), custom: true, icon: "shawl")
        case .beanie    : return ItemDisplay(color: Color(hex : "#A6B65C"), custom: true, icon: "beanie")
        case .socks     : return ItemDisplay(color: Color(hex : "#C76A4D"), custom: true, icon: "sock")
        case .blanket   : return ItemDisplay(color: Color(hex : "#FFD2A6"), custom: true, icon: "blanket")
        case .scarf     : return ItemDisplay(color: Color(hex : "#6587B0"), custom: true, icon: "scarf")
        case .mittens   : return ItemDisplay(color: Color(hex : "#A7C9E8"), icon: "hand.raised")
        case .cardigan  : return ItemDisplay(color: Color(hex : "#B68BCE"), custom: true, icon: "cardigan")
        case .bag       : return ItemDisplay(color: Color(hex : "#76B2B8"), icon: "handbag")
        case .tankTop   : return ItemDisplay(color: Color(hex : "#B0E0E6"), custom: true, icon: "tanktop")
        case .vest      : return ItemDisplay(color: Color(hex : "#D4C4FB"), custom: true, icon: "vest")
        case .household : return ItemDisplay(color: Color(hex : "#DAA520"), icon: "house")
        case .amigurumi : return ItemDisplay(color: Color(hex : "#B0A8B9"), icon: "teddybear")
        default         : return ItemDisplay(color: Color(hex : "#E7D46E"), icon: "questionmark")
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
        
        let allowedDeviation = 0.15
        var ratio = 0.0
        
        if weightAndYardage.yardage != nil && weightAndYardage.grams != nil {
            ratio = weightAndYardage.yardage! / Double(weightAndYardage.grams!)
        }
        
        let currentLength = weightAndYardage.existingItem?.currentLength
        
        // return empty list when length or ratio is 0
        if currentLength == nil || currentLength == 0 || ratio == 0 {
            return []
        }
        
        var predicates: [NSPredicate] = []
        
        // only yarn parents
        predicates.append(NSPredicate(format: "parent == %@", WeightAndYardageParent.yarn.rawValue))
        
        // weight filter
        predicates.append(NSPredicate(format: "weight == %@", weightAndYardage.weight.rawValue))
        
        // length filter
        predicates.append(NSPredicate(format: "currentLength > 0 AND currentLength >= %@", NSNumber(value: currentLength!)))
        
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
    
    func crochetTechniques() -> [PatternTechnique] {
        return [
            PatternTechnique.none,
            PatternTechnique.slipKnot,
            PatternTechnique.chainStitch,
            PatternTechnique.singleCrochet,
            PatternTechnique.halfDoubleCrochet,
            PatternTechnique.doubleCrochet,
            PatternTechnique.tripleCrochet,
            PatternTechnique.slipStitch,
            PatternTechnique.shellStitch,
            PatternTechnique.vStitch,
            PatternTechnique.grannySquare,
            PatternTechnique.bobbleStitch,
            PatternTechnique.clusterStitch,
            PatternTechnique.crossStitch,
            PatternTechnique.frontPostStitch,
            PatternTechnique.backPostStitch,
            PatternTechnique.colorChanges,
            PatternTechnique.joinAsYouGo,
            PatternTechnique.foundationRowTechniques,
            PatternTechnique.surfaceCrochet,
            PatternTechnique.overlayCrochet,
            PatternTechnique.other
        ]
    }
    
    func knitTechniques() -> [PatternTechnique] {
        return [
            PatternTechnique.none,
            PatternTechnique.castingOn,
            PatternTechnique.bindingOff,
            PatternTechnique.knitStitch,
            PatternTechnique.purlStitch,
            PatternTechnique.garterStitch,
            PatternTechnique.stockinetteStitch,
            PatternTechnique.ribbing,
            PatternTechnique.cableKnitting,
            PatternTechnique.laceKnitting,
            PatternTechnique.colorwork,
            PatternTechnique.shortRows,
            PatternTechnique.mosaicKnitting,
            PatternTechnique.twistedStitches,
            PatternTechnique.kitchenerStitch,
            PatternTechnique.doubleKnitting,
            PatternTechnique.entrelac,
            PatternTechnique.feltedKnitting,
            PatternTechnique.threeNeedleBindOff,
            PatternTechnique.seaming,
            PatternTechnique.blocking,
            PatternTechnique.beading,
            PatternTechnique.iCord,
            PatternTechnique.other
        ]
    }
    
    func tunisianTechniques() -> [PatternTechnique] {
        return [
            PatternTechnique.none,
            PatternTechnique.tunisianSimpleStitch,
            PatternTechnique.tunisianKnitStitch,
            PatternTechnique.tunisianPurlStitch,
            PatternTechnique.tunisianFullStitch,
            PatternTechnique.tunisianReverseStitch,
            PatternTechnique.tunisianLaceStitch,
            PatternTechnique.tunisianShellStitch,
            PatternTechnique.tunisianHoneycombStitch,
            PatternTechnique.tunisianSimpleStitchWithIncreasesAndDecreases,
            PatternTechnique.tunisianColorwork,
            PatternTechnique.tunisianRibbing,
            PatternTechnique.tunisianDoubleCrochet,
            PatternTechnique.tunisianEntrelac,
            PatternTechnique.tunisianChevronStitch,
            PatternTechnique.other
        ]
    }
}
