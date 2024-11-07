//
//  ProjectPreview.swift
//  WoolWallet
//
//  Created by Mac on 11/6/24.
//

import Foundation
import SwiftUI

struct ProjectPreview:  View {
    @ObservedObject var project : Project
    @Binding var displayedProject : Project?
    
    var body: some View {
        InfoCard(backgroundColor: Color.accentColor.opacity(0.2)) {
            HStack {
                if project.uiImages.isEmpty {
                    PatternItemDisplay(pattern: project.pattern!, size: Size.medium)
                } else {
                    ImageCarousel(images: .constant(project.uiImages), smallMode: true)
                        .xsImageCarousel()
                }
                
                Spacer()
                
                VStack {
                    if project.complete {
                        Label("Complete", systemImage : "checkmark.circle")
                    }
                    
                    if project.inProgress {
                        Label("In Progress", systemImage : "play.circle")
                    }
                    
                    if !project.complete && !project.inProgress {
                        Label("Not Started", systemImage : "pause.circle")
                    }
                    
                    Spacer()
                    
                    ProjectDateDisplay(project: project)
                }
                .foregroundStyle(Color.primary)
                .font(.footnote)
                
                Spacer()
                
                VStack {
                    Spacer()
                }
            }
        }
        .onTapGesture {
            displayedProject = project
        }
    }
}
