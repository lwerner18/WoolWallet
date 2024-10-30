//
//  ProjectList.swift
//  WoolWallet
//
//  Created by Mac on 9/3/24.
//

import Foundation
import SwiftUI

struct ProjectList: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var showAddProjectForm     : Bool = false
    @State private var newProject             : Project? = nil
    @State var         searchText             : String = ""
    @State private var projectToDelete        : Project? = nil
    @State private var projectToEdit          : Project? = nil
    @State private var showConfirmationDialog : Bool = false
    @State private var selectedTab            : ProjectTab = ProjectTab.inProgress
    
    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [] // Optional: Sort by name
    ) private var allProjects: FetchedResults<Project>
    
    private var filteredFetchRequest = FetchRequest<Project>(
        sortDescriptors: [],
        predicate: NSPredicate(value: true),
        animation: .default
    )
    
    // Computed property to get all the patterns with an optional searchText
    private var filteredProjects: FetchedResults<Project> {
        
        // Apply sorting based on the selected option
        filteredFetchRequest.wrappedValue.nsSortDescriptors = [NSSortDescriptor(keyPath: \Project.startDate, ascending: true)]
        
        var predicates: [NSPredicate] = []
        if searchText != "" {
            let searchPredicate = [NSPredicate(format: "pattern.name CONTAINS[c] %@", searchText)]
            
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicate)
            predicates.append(compoundPredicate)
        }
        
        switch(selectedTab) {
        case .inProgress:
            predicates.append(NSPredicate(format: "inProgress = %@", true as NSNumber))
        case .completed:
            predicates.append(NSPredicate(format: "complete = %@", true as NSNumber))
        case .notStarted:
            let inProgressPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "inProgress == %@", NSNumber(value: false)),
                NSPredicate(format: "inProgress == nil")
            ])
            predicates.append(inProgressPredicate)
            
            let completedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "complete == %@", NSNumber(value: false)),
                NSPredicate(format: "complete == nil")
            ])
            predicates.append(completedPredicate)
        }
        
        filteredFetchRequest.wrappedValue.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        return filteredFetchRequest.wrappedValue
    }
    
    private var tabCounts: [TabCount<ProjectTab>] {
        return [
            TabCount(tab: ProjectTab.inProgress, count: allProjects.filter {$0.inProgress}.count),
            TabCount(tab: ProjectTab.completed, count: allProjects.filter {$0.complete}.count),
            TabCount(tab: ProjectTab.notStarted, count: allProjects.filter {!$0.inProgress && !$0.complete}.count),
        ]
    }
    
    var body: some View {
        NavigationStack {
            Tabs(selectedTab: $selectedTab, tabCounts: tabCounts)
            
            VStack {
                if filteredProjects.isEmpty {
                    ScrollView {
                        ZStack {
                            // Reserve space matching the scroll view's frame
                            Spacer().containerRelativeFrame([.horizontal, .vertical])
                            
                            VStack {
                                Image("moSit") // Replace with your image's name
                                    .resizable() // If you want to adjust the size
                                    .scaledToFit() // Adjust the image's aspect ratio
                                    .frame(width: 300, height: 225) // Set desired frame size
                                
                                Text("Quit sitting around!")
                                    .font(.title)
                                    .bold()
                                    .multilineTextAlignment(.center)
                                
                                VStack {
                                    Text("No projects were found.")
                                    
                                    HStack(spacing: 0) {
                                        Text("Either ")
                                        
                                        Button(action: {
                                            showAddProjectForm = true
                                        }) {
                                            Text("start one")
                                                .foregroundColor(.blue) // Customize the color to look like a link
                                        }
                                        .buttonStyle(PlainButtonStyle()) // Remove default button styling
                                        .padding(0)
                                        
                                        Text(" or modify your search.")
                                            .font(.body)
                                    }
                                }
                                .padding(.top, 5)
                            }
                            .padding()
                        }
                    }
                } else {
                    List {
                        ForEach(filteredProjects) { project in
                            NavigationLink(
                                destination: ProjectInfo(project: project)
                            ) {
                                HStack {
                                    
                                    Text("").frame(maxWidth: 0)
                                    
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
                                        ImageCarousel(images: .constant(project.uiImages), smallMode: true)
                                            .xsImageCarousel()
                                    }
                                    
                                    Spacer()
                                    
                                    VStack {
                                        Text(project.pattern!.name ?? "No Name")
                                            .foregroundStyle(Color.primary)
                                            .bold()
                                        
                                        Spacer()
                                        
                                        if project.inProgress {
                                            Text("Started \(DateUtils.shared.formatDate(project.startDate!)!)")
                                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                                .font(.footnote)
                                            
                                            Spacer()
                                            
                                            let daysPassed = Calendar.current.dateComponents([.day], from: project.startDate!, to: Date.now).day ?? 0
                                            
                                            if daysPassed > 0 {
                                                HStack {
                                                    Image(systemName : "timer")
                                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                                        .font(.caption2)
                                                    
                                                    Text("\(daysPassed) day\(daysPassed > 1 ? "s" : "")")
                                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                                        .font(.caption2)
                                                }
                                            }
                                        } else if project.complete {
                                            Text("Completed \(DateUtils.shared.formatDate(project.endDate!)!)")
                                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                                .font(.footnote)
                                            
                                            Spacer()
                                            
                                            let daysPassed = Calendar.current.dateComponents([.day], from: project.endDate!, to: Date.now).day ?? 0
                                            
                                            if daysPassed > 0 {
                                                HStack {
                                                    Image(systemName : "timer")
                                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                                        .font(.caption2)
                                                    
                                                    Text("Took \(daysPassed) day\(daysPassed > 1 ? "s" : "")")
                                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                                        .font(.caption2)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    
                                    Spacer()
                                }
                                .swipeActions(allowsFullSwipe: false) {
                                    Button {
                                        projectToEdit = project
                                    } label: {
                                        Label("", systemImage : "pencil")
                                        
                                    }
                                    .tint(Color.accentColor)
                                    
                                    Button(role: .destructive) {
                                        projectToDelete = project
                                        showConfirmationDialog = true
                                    } label: {
                                        Label("", systemImage : "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
               
            }
            .navigationTitle("Projects")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by pattern name..."
            )
            .onChange(of: searchText) {
                if searchText.isEmpty {
                    searchText = ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddProjectForm = true
                    }) {
                        Image(systemName: "plus") // Use a system icon
                            .imageScale(.large)
                    }
                }
            }
            .fullScreenCover(isPresented: $showAddProjectForm) {
                AddOrEditProjectForm(projectToEdit: nil, preSelectedPattern: nil) { addedProject in
                    // Capture the newly added project
                    newProject = addedProject
                    showAddProjectForm = false
                }
            }
            .fullScreenCover(item: $projectToEdit, onDismiss: { projectToEdit = nil}) { project in
                AddOrEditProjectForm(projectToEdit : project, preSelectedPattern: nil)
            }
            .alert("Are you sure you want to delete this project?", isPresented: $showConfirmationDialog) {
                if let project = projectToDelete {
                    Button("Delete", role: .destructive) {
                        ProjectUtils.shared.removeProject(at: project, with: managedObjectContext)
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
    
        }
    }
}
