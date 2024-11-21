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
    @Environment(\.projectToShowAutomatically) var projectToShowAutomatically : Binding<Project?>
    
    @State private var showAddProjectForm     : Bool = false
    @State private var newProject             : Project? = nil
    @State var         searchText             : String = ""
    @State private var projectToDelete        : Project? = nil
    @State private var projectToEdit          : Project? = nil
    @State private var showConfirmationDialog : Bool = false
    @State private var selectedTab            : ProjectTab = ProjectTab.inProgress
    
    @FetchRequest(
        fetchRequest: Project.fetchPartialRequest()
    ) private var allProjects: FetchedResults<Project>
    
    private var filteredFetchRequest = FetchRequest<Project>(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.startDate, ascending: true)],
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
                            
                            if selectedTab == ProjectTab.completed {
                                VStack {
                                    Image("judgementalMo") // Replace with your image's name
                                        .resizable() // If you want to adjust the size
                                        .scaledToFit() // Adjust the image's aspect ratio
                                        .frame(width: 300, height: 225) // Set desired frame size
                                    
                                    Text("You've completed nothing.")
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
                            } else if selectedTab == ProjectTab.notStarted {
                                VStack {
                                    Image("happyMo") // Replace with your image's name
                                        .resizable() // If you want to adjust the size
                                        .scaledToFit() // Adjust the image's aspect ratio
                                        .frame(width: 300, height: 225) // Set desired frame size
                                    
                                    Text("Looks like you're busy!")
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
                            } else {
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
                    }
                } else {
                    List {
                        ForEach(filteredProjects, id : \.id) { project in
                            NavigationLink(
                                destination: ProjectInfo(project: project, selectedTab : $selectedTab)
//                                isActive :  Binding(
//                                    get: { projectToShowAutomatically.wrappedValue == project },
//                                    set: { isActive in
//                                        if isActive {
//                                            projectToShowAutomatically.wrappedValue = project
//                                        } else if projectToShowAutomatically.wrappedValue == project {
//                                            projectToShowAutomatically.wrappedValue = nil
//                                        }
//                                    }
//                                )
                            ) {
                                HStack {
                                    
                                    Text("").frame(maxWidth: 0)
                                    
                                    if project.uiImages.isEmpty {
                                        PatternItemDisplay(pattern: project.pattern!, size: Size.medium)
                                    } else {
                                        ImageCarousel(images: .constant(project.uiImages), size: Size.extraSmall)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack {
                                        Text(project.pattern!.name ?? "No Name")
                                            .foregroundStyle(Color.primary)
                                            .bold()
                                            .multilineTextAlignment(.center)
                                        
                                        Spacer()
                                        
                                        ProjectDateDisplay(project: project)
                                    }
                                    
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .swipeActions(allowsFullSwipe: false) {
                                    if !showConfirmationDialog {
                                        Button {
                                            projectToEdit = project
                                        } label: {
                                            Label("", systemImage : "pencil")
                                            
                                        }
                                        .tint(Color.accentColor)
                                    }
                                    
                                    Button(role: .destructive) {
                                        projectToDelete = project
                                        showConfirmationDialog = true
                                    } label: {
                                        Label("", systemImage : "trash")
                                    }
                                }
                            }
                            .overlay(
                                !project.inProgress && !project.complete
                                ? AnyView(
                                    HStack {
                                        Image("butterball") // Replace with your image's name
                                            .resizable() // If you want to adjust the size
                                            .scaledToFit() // Adjust the image's aspect ratio
                                            .frame(width: 50, height: 40) // Set desired frame size
                                            .shadow(radius: 2)
                                        
                                        Text("What are you waiting for?")
                                            .font(.caption2)
                                    }
                                    .offset(x: 20, y: 3)
                                )
                                : AnyView(EmptyView()),
                                alignment: .bottom
                            )
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
            .sheet(item: $newProject) { project in
                ProjectInfo(project: project, isNewProject : true, isPopover : true)
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
            .onAppear {
                managedObjectContext.refreshAllObjects()
            }
    
        }
    }
}
