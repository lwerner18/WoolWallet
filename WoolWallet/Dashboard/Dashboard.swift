//
//  Dashboard.swift
//  WoolWallet
//
//  Created by Mac on 11/10/24.
//

import Foundation
import SwiftUI

struct Dashboard : View {
    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.startDate, ascending: false)],
        predicate: NSPredicate(format: "inProgress = %@", true as NSNumber)
    ) private var currentProjects: FetchedResults<Project>
    
    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.endDate, ascending: false)],
        predicate: NSPredicate(format: "complete = %@", true as NSNumber)
    ) private var completedProjects: FetchedResults<Project>
    
    var averageTimeToComplete: Double {
        var totalDays = 0
        
        if completedProjects.isEmpty {
            return Double(totalDays)
        }
        
        completedProjects.forEach { project in
            totalDays += Calendar.current.dateComponents([.day], from: project.startDate!, to: project.endDate!).day ?? 0
        }
        
        return Double(totalDays) / Double(completedProjects.count)
    }
    
    var unusedSkeins: Double {
        return 0
    }
    
    var body : some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if currentProjects.count > 0 {
                        Text("Current Project\(currentProjects.count > 1 ? "s" : "")")
                            .infoCardHeader()
                        
                        SimpleHorizontalScroll(count: currentProjects.count) {
                            ForEach(currentProjects, id : \.id) { project in
                                ProjectPreview(
                                    project: project,
                                    displayedProject: .constant(nil)
                                )
                            }
                        }
                    }
                    
                    Text("Stats")
                        .infoCardHeader()
                    
                    InfoCard() {
                        VStack(spacing: 25) {
                            HStack {
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text("\(currentProjects.count)")
                                        .foregroundStyle(Color.primary)
                                        .font(.title2)
                                    
                                    Text("Current Projects")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .font(.caption2)
                                    
                                }
                                .bold()
                                
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text("\(completedProjects.count)")
                                        .foregroundStyle(Color.primary)
                                        .font(.title2)
                                    
                                    Text("Finished Projects")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .font(.caption2)
                                    
                                }
                                .bold()
                                
                                Spacer()
                            }
                            
                            HStack {
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: averageTimeToComplete)) ?? "0") days")
                                        .foregroundStyle(Color.primary)
                                        .font(.title3)
                                    
                                    Text("Average Project\nDuration")
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .font(.caption2)
                                    
                                }
                                .bold()
                                
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: unusedSkeins)) ?? "0")")
                                        .foregroundStyle(Color.primary)
                                        .font(.title2)
                                    
                                    Text("Unused Skeins")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .font(.caption2)
                                    
                                }
                                .bold()
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}
