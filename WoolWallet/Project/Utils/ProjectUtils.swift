//
//  ProjectUtils.swift
//  WoolWallet
//
//  Created by Mac on 10/29/24.
//

import Foundation
import SwiftUI
import CoreData

class ProjectUtils {
    static let shared = ProjectUtils()
    
    private init() {}
    
    func removeProject(at project: Project, with context: NSManagedObjectContext) {
        project.images?.forEach   { context.delete($0 as! NSManagedObject) }
        project.pairings?.forEach { context.delete($0 as! NSManagedObject) }
        
        context.delete(project)
        
        PersistenceController.shared.save()
    }
}
