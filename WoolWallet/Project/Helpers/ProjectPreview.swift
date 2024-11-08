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
    var forYarn : Bool = false
    var disableOnTap : Bool = false
    
    var body: some View {
        InfoCard(backgroundColor: Color.accentColor.opacity(0.2)) {
            if displayedProject != nil {
                CenteredLoader()
            } else {
                HStack {
                    if project.uiImages.isEmpty {
                        PatternItemDisplay(pattern: project.pattern!, size: Size.medium)
                    } else {
                        ImageCarousel(images: .constant(project.uiImages), smallMode: true)
                            .xsImageCarousel()
                    }
                    
                    Spacer()
                    
                    VStack {
                        if forYarn {
                            Text(project.pattern!.name!)
                                .multilineTextAlignment(.center)
                                .font(.title3)
                                .bold()
                            
                            Text(
                                PatternUtils.shared.joinedItems(patternItems: project.pattern!.patternItems)
                            )
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            
                            Spacer()
                        }
                        
                        if project.complete {
                            Label("Complete", systemImage : "checkmark.circle")
                        }
                        
                        if project.inProgress {
                            Label("In Progress", systemImage : "play.circle")
                        }
                        
                        if !project.complete && !project.inProgress {
                            Label("Not Started", systemImage : "pause.circle")
                            Spacer()
                            Text("What are you waiting for?")
                                .font(.caption2)
                        }
                        
                        Spacer()
                        
                        ProjectDateDisplay(project: project)
                    }
                    .foregroundStyle(Color.primary)
                    .font(.footnote)
                    
                    Spacer()
                    
                    VStack {
                        Text("")
                    }
                }
            }
        }
        .onTapGesture {
            if !disableOnTap {
                displayedProject = project
            }
        }
        .overlay(
            !project.inProgress && !project.complete && displayedProject == nil
            ? AnyView(
                Image("sideEye") // Replace with your image's name
                    .resizable() // If you want to adjust the size
                    .scaledToFit() // Adjust the image's aspect ratio
                    .frame(width: 100, height: 75) // Set desired frame size
                    .offset(x: 32, y: 0)
                    .cornerRadius(8)
                    .shadow(radius: 3)
            )
            : AnyView(EmptyView()),
            alignment: .bottomTrailing
        )
    }
}
