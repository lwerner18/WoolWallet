//
//  ProjectDateDisplay.swift
//  WoolWallet
//
//  Created by Mac on 11/6/24.
//

import Foundation
import SwiftUI

struct ProjectDateDisplay : View {
    @ObservedObject var project : Project
    
    var body : some View {
        VStack(spacing: 3) {
            if project.inProgress {
                Text("Started \(DateUtils.shared.formatDate(project.startDate!)!)")
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.footnote)
                
                Spacer()
                
                let daysPassed = Calendar.current.dateComponents([.day], from: project.startDate!, to: Date.now).day ?? 0
                
                if daysPassed > 0 {
                    HStack {
                        Image(systemName : "timer")
                        
                        Text("\(daysPassed) day\(daysPassed > 1 ? "s" : "") passed")
                    }
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.caption2)
                }
            } else if project.complete {
                Text("Started \(DateUtils.shared.formatDate(project.startDate!)!)")
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.footnote)
                
                Text("Completed \(DateUtils.shared.formatDate(project.endDate!)!)")
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.footnote)
                
                Spacer()
                
                let daysPassed = Calendar.current.dateComponents([.day], from: project.startDate!, to: project.endDate!).day ?? 0
                
                if daysPassed > 0 {
                    HStack {
                        Image(systemName : "calendar")
                        
                        Text("Took \(daysPassed) day\(daysPassed > 1 ? "s" : "")")
                    }
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.caption2)
                }
            }
        }
    }
}
