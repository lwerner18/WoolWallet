//
//  Notion.swift
//  WoolWallet
//
//  Created by Mac on 11/13/24.
//

import Foundation
import SwiftUI
import CoreData

extension Notion {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Notion.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    static func from(notionItem: NotionItem, order: Int, context: NSManagedObjectContext) -> Notion {
        var notion : Notion
        
        if notionItem.existingItem != nil {
            notion = notionItem.existingItem!
        } else {
            notion = Notion(context: context)
        }
        
        notion.notion = notionItem.notion.rawValue
        notion.notionDescription = notionItem.description
        notion.order = Int16(order)
        
        return notion
    }
}
