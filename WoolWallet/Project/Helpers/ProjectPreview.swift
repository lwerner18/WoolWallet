//
//  ProjectPreview.swift
//  WoolWallet
//
//  Created by Mac on 11/6/24.
//

import Foundation
import SwiftUI

/// Yarn-details project card — same chrome as pattern-details projects
struct ProjectPreview: View {
    @ObservedObject var project : Project
    @Binding var displayedProject : Project?
    var yarnId : UUID? = nil
    var disableOnTap : Bool = false
    var compact : Bool = false
    
    var body: some View {
        ProjectCard(
            project: project,
            yarnId: yarnId,
            compact: compact,
            isOpening: displayedProject?.objectID == project.objectID,
            onOpen: {
                guard !disableOnTap else { return }
                displayedProject = project
            }
        )
    }
}
