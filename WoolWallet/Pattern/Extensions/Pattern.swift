//
//  Pattern.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

extension Pattern {
    var patternItems: [PatternItemField] {
        let patternItems = items?.allObjects as? [PatternItem] ?? []
        
        let sortedItems = patternItems.sorted { $0.order < $1.order}
        
        return sortedItems.map { patternItem in
            return PatternItemField(
                id : patternItem.id!,
                item: Item(rawValue: patternItem.item!)!,
                description: patternItem.itemDescription!,
                existingItem: patternItem
            )
        }
    }
    
    var crochetHooks: [Hook] {
        let crochetHooks = hooks?.allObjects as? [CrochetHook] ?? []
        
        let sortedHooks = crochetHooks.sorted { $0.order < $1.order}
        
        return sortedHooks.map { hook in
            return Hook(
                id: hook.id!,
                hook: CrochetHookSize(rawValue: hook.size!)!,
                existingItem: hook
            )
        }
    }
    
    var knittingNeedles: [Needle] {
        let knittingNeedles = needles?.allObjects as? [KnittingNeedle] ?? []
        
        let sortedNeedles = knittingNeedles.sorted { $0.order < $1.order}
        
        return sortedNeedles.map { needle in
            return Needle(
                id: needle.id!,
                needle: KnitNeedleSize(rawValue: needle.size!)!,
                existingItem: needle
            )
        }
    }
    
    var notionItems: [NotionItem] {
        let notionItems = notions?.allObjects as? [Notion] ?? []
        
        let sortedNotions = notionItems.sorted { $0.order < $1.order}
        
        return sortedNotions.map { notion in
            return NotionItem(
                id: notion.id!,
                notion: PatternNotion(rawValue: notion.notion!)!,
                description: notion.notionDescription ?? "",
                existingItem: notion
            )
        }
    }
    
    var techniqueItems: [TechniqueItem] {
        let techniqueItems = techniques?.allObjects as? [Technique] ?? []
        
        let sortedTechniques = techniqueItems.sorted { $0.order < $1.order}
        
        return sortedTechniques.map { technique in
            return TechniqueItem(
                id: technique.id!,
                technique: PatternTechnique(rawValue: technique.technique!)!,
                description: technique.techniqueDescription ?? "",
                existingItem: technique
            )
        }
    }
    
    var weightAndYardageItems: [WeightAndYardageData] {
        return weightAndYardageArray.map { item in
            return WeightAndYardageData(
                id                : item.id!,
                weight            : item.weight != nil ? Weight(rawValue: item.weight!)! : Weight.none,
                unitOfMeasure     : item.unitOfMeasure != nil ? UnitOfMeasure(rawValue: item.unitOfMeasure!)! : UnitOfMeasure.yards,
                yardage           : item.yardage != 0 ? item.yardage : nil,
                grams             : item.grams != 0 ? Int(item.grams) : nil,
                hasBeenWeighed    : Int(item.hasBeenWeighed),
                totalGrams        : item.totalGrams != 0 ? item.totalGrams : nil,
                skeins            : item.currentSkeins,
                hasPartialSkein   : item.hasPartialSkein,
                length            : item.currentLength,
                parent            : WeightAndYardageParent(rawValue: item.parent!)!,
                hasExactLength    : Int(item.hasExactLength),
                existingItem      : item
            )
        }
    }
    
    var weightAndYardageArray : [WeightAndYardage] {
        let weightsAndYardages = recWeightAndYardages?.allObjects as? [WeightAndYardage] ?? []
        
        return weightsAndYardages.sorted { $0.order < $1.order}
    }
    
    var uiImages: [ImageData] {
        let storedImages = images?.allObjects as? [StoredImage] ?? []
        
        let sortedImages = storedImages.sorted { $0.order < $1.order}
        
        return sortedImages.map { storedImage in
            return ImageData(
                id : storedImage.id!,
                image: UIImage(data: storedImage.image ?? Data())!,
                existingItem: storedImage
            )
        }
    }
    
    var projectsArray: [Project] {
        return projects?.allObjects as? [Project] ?? []
    }
    
    var hasProjects: Bool {
        return !projectsArray.isEmpty
    }
    
    // Static function to create the fetch request with propertiesToFetch
    static func fetchPartialRequest() -> NSFetchRequest<Pattern> {
        let request = NSFetchRequest<Pattern>(entityName: "Pattern")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Pattern.designer, ascending: true)]
        
        // Specify the properties you want to fetch
        request.propertiesToFetch = ["designer"] // List properties to fetch
        request.relationshipKeyPathsForPrefetching = ["projects"]
        request.resultType = .managedObjectResultType
        
        return request
    }
    
    // Static function to create the fetch request with propertiesToFetch
    static func fetchItems() -> NSFetchRequest<Pattern> {
        let request = NSFetchRequest<Pattern>(entityName: "Pattern")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Pattern.name, ascending: true)]
        
        // Specify the properties you want to fetch
        request.relationshipKeyPathsForPrefetching = ["items"]
        request.resultType = .managedObjectResultType
        
        return request
    }
}
