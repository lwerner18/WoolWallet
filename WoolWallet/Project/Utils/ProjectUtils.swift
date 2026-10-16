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
        tearDown(project, in: context)
        context.delete(project)
        
        PersistenceController.shared.save()
    }
    
    /// Clears photos, yarn pairings, and counters. Pairings must go before the project does —
    /// their project link is required, so a bare delete leaves an unsavable object graph.
    func tearDown(_ project: Project, in context: NSManagedObjectContext) {
        project.images?.forEach { context.delete($0 as! NSManagedObject) }
        project.pairings?.forEach { context.delete($0 as! NSManagedObject) }
        project.rowCounters?.forEach { context.delete($0 as! NSManagedObject) }
    }
}
