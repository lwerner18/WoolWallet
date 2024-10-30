//
//  ProjectEnums.swift
//  WoolWallet
//
//  Created by Mac on 10/29/24.
//

import Foundation

enum ProjectTab : String, CaseIterable, Identifiable, Equatable, CustomStringConvertible {
    var id: String { self.rawValue }
    
    case inProgress = "In Progress"
    case completed = "Completed"
    case notStarted = "Not Started"
    
    // CustomStringConvertible
    var description: String {
        self.rawValue
    }
}
