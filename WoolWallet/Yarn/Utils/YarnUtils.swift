//
//  YarnUtils.swift
//  WoolWallet
//
//  Created by Mac on 3/22/24.
//

import Foundation
import CoreData

class YarnUtils {
    static let shared = YarnUtils()
    
    private init() {}
    
    func getSkeinsText(skeins : Double) -> String {
        let formattedSkeins = GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: skeins)) ?? "1"
        
        return "\(formattedSkeins) skein\(skeins > 1 ? "s" : "")"
    }
    
    func toggleYarnArchived(at yarn: Yarn) {
        yarn.isArchived = !yarn.isArchived
        
        PersistenceController.shared.save()
    }
    
    func removeYarn(at yarn: Yarn, with context: NSManagedObjectContext) {
        context.delete(yarn)
        
        PersistenceController.shared.save()
    }
}
