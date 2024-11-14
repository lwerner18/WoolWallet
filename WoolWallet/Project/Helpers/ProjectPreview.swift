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
    var yarnId : UUID? = nil
    var disableOnTap : Bool = false
    
    var usedYarnWAndY : [ProjectPairingItem] {
        if yarnId == nil {
            return []
        }
        
        return project.projectPairingItems.filter { element in
            return element.yarnWeightAndYardage.yarn?.id == yarnId!
        }
    }
    
    var lengthUsed : Double? {
        if yarnId == nil {
            return nil
        }
        
        var sum = 0.0
        
        usedYarnWAndY.forEach { pairing in
            sum += pairing.lengthUsed ?? 0
        }
      
        return sum
    }
    
    var body: some View {
        InfoCard(backgroundColor: Color.accentColor.opacity(0.2)) {
            if displayedProject != nil {
                CenteredLoader()
            } else {
                HStack {
                    if let pattern = project.pattern {
                        if project.uiImages.isEmpty {
                            PatternItemDisplay(pattern: pattern, size: Size.medium)
                        } else {
                            ImageCarousel(images: .constant(project.uiImages), size: Size.extraSmall)
                        }
                        
                        Spacer()
                        
                        VStack {
                            if yarnId != nil {
                                Text(pattern.name!)
                                    .multilineTextAlignment(.center)
                                    .font(.title3)
                                    .bold()
                                
                                Text(
                                    PatternUtils.shared.joinedItems(patternItems: pattern.patternItems)
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
                            
                            if yarnId != nil && lengthUsed != nil && project.complete {
                                Spacer()
                                
                                let unit : String = usedYarnWAndY.first?.yarnWeightAndYardage.unitOfMeasure ?? ""
                                
                                Text("Used \(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: lengthUsed!)) ?? "1") \(unit)")
                                    .font(.title3)
                                    .foregroundStyle(Color.primary)
                            }
                            
                            Spacer()
                            
                            ProjectDateDisplay(project: project)
                            
                            
                        }
                        .foregroundStyle(Color.primary)
                        .font(.footnote)
                        
                        Spacer()
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
