//
//  ProjectInfo.swift
//  WoolWallet
//
//  Created by Mac on 10/29/24.
//

import Foundation
import SwiftUI


struct ProjectInfo: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ObservedObject var project : Project
    var isNewProject : Bool
    
    init(
        project: Project,
        isNewProject : Bool = false
    ) {
        self.project = project
        self.isNewProject = isNewProject
    }
    
    // Computed property to calculate if device is most likely in portrait mode
    var isPortraitMode: Bool {
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    // Internal state trackers
    @State private var showEditProjectForm : Bool = false
    @State private var showConfirmationDialog = false
    @State private var animateCheckmark = false
    
    var body: some View {
        VStack {
            if isNewProject {
                // Toolbar-like header
                HStack {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
                .padding(.bottom, 10) // Padding around the button
                .padding(.top, 20) // Padding around the button
                .padding(.horizontal, 20) // Padding around the button
            }
            
            ScrollView {
                if isNewProject {
                    VStack {
                        Label("", systemImage: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#008000")) // Set text color
                            .symbolEffect(.bounce, value: animateCheckmark)
                            .padding()
                        
                        Text("Successfully created project")
                            .font(.title2)
                    }
                    .onAppear {
                        animateCheckmark.toggle()
                    }
                }
                
                ConditionalStack(useVerticalLayout: isPortraitMode) {
                    if project.uiImages.isEmpty {
                        let itemDisplay =
                        PatternUtils.shared.getItemDisplay(
                            for: project.pattern!.patternItems.isEmpty ? nil : project.pattern!.patternItems.first?.item
                        )
                        
                        if itemDisplay.custom {
                            Image(itemDisplay.icon)
                                .iconCircle(background: itemDisplay.color, xl: true)
                        } else {
                            Image(systemName: itemDisplay.icon)
                                .iconCircle(background: itemDisplay.color, xl: true)
                        }
                    } else {
                        ImageCarousel(images: .constant(project.uiImages))
                    }
                    
                    
                    VStack {
                        Text(project.pattern?.name! ?? "N/A").bold().font(.largeTitle).foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity)
                    }
                    
                    HStack {
                        if project.complete {
                            Label("Complete", systemImage : "checkmark.circle")
                                .infoCapsule()
                        }
                        
                        if project.inProgress {
                            Label("In Progress", systemImage : "play.circle")
                                .infoCapsule()
                        }
                        
                        if !project.complete && !project.inProgress {
                            Label("Not Started", systemImage : "pause.circle")
                                .infoCapsule()
                        }
                        
                        Spacer()
                    }
                }
                .foregroundStyle(Color.black)
                .padding()
            }
            .navigationTitle(project.pattern?.name! ?? "N/A")
            .navigationBarTitleDisplayMode(.inline)
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditProjectForm = true
                        } label : {
                            Label("Edit", systemImage : "pencil")
                        }
                        
                        if project.inProgress {
                            Button {
                                project.inProgress = false
                                project.startDate = nil
                                
                                PersistenceController.shared.save()
                            } label : {
                                Label("Mark as not started", systemImage : "pause.circle")
                            }
                        }
                        
                        if !project.complete && project.inProgress {
                            Button {
                                project.inProgress = false
                                project.complete = true
                                project.endDate = Date.now
                                
                                PersistenceController.shared.save()
                            } label : {
                                Label("Complete", systemImage : "checkmark.circle")
                            }
                        }
                        
                        if project.complete  {
                            Button {
                                project.inProgress = true
                                project.startDate = Date.now
                                project.complete = false
                                project.endDate = nil
                                
                                PersistenceController.shared.save()
                            } label : {
                                Label("Mark as in progress", systemImage : "play.circle")
                            }
                        }
                        
                        if !project.complete && !project.inProgress  {
                            Button {
                                project.inProgress = true
                                project.startDate = Date.now
                                
                                PersistenceController.shared.save()
                            } label : {
                                Label("Start", systemImage : "play.circle")
                            }
                        }
                        
                        Button(role: .destructive) {
                            showConfirmationDialog = true
                        } label: {
                            Label("Delete", systemImage : "trash")
                        }
                        
                    } label: {
                        Label("more", systemImage : "ellipsis")
                    }
                }
            }
            .alert("Are you sure you want to delete this project?", isPresented: $showConfirmationDialog) {
                Button("Delete", role: .destructive) {
                    ProjectUtils.shared.removeProject(at: project, with: managedObjectContext)
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditProjectForm) {
                AddOrEditProjectForm(projectToEdit: project, preSelectedPattern : nil)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
