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
    @Environment(\.projectTabToShowAutomatically) var projectTabToShowAutomatically : Binding<ProjectTab?>
    
    @State private var showAddProjectForm     : Bool = false
    @State private var newProject             : Project? = nil
    @State var         searchText             : String = ""
    @State private var projectToDelete        : Project? = nil
    @State private var projectToEdit          : Project? = nil
    @State private var showConfirmationDialog : Bool = false
    @State private var selectedTab            : ProjectTab = ProjectTab.inProgress
    @State private var selectedProject        : Project? = nil
    @State private var projectToRead          : Project? = nil
    
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
        switch selectedTab {
        case .inProgress:
            filteredFetchRequest.wrappedValue.nsSortDescriptors = [NSSortDescriptor(keyPath: \Project.startDate, ascending: true)]
        case .completed:
            filteredFetchRequest.wrappedValue.nsSortDescriptors = [NSSortDescriptor(keyPath: \Project.endDate, ascending: false)]
        case .notStarted:
            // Oldest first, like a queue
            filteredFetchRequest.wrappedValue.nsSortDescriptors = [NSSortDescriptor(keyPath: \Project.dateAdded, ascending: true)]
        }
        
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
                                                    .foregroundStyle(Color.accentColor)
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
                                                    .foregroundStyle(Color.accentColor)
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
                                                    .foregroundStyle(Color.accentColor)
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
                    switch selectedTab {
                    case .inProgress:
                        workbench
                    case .notStarted:
                        queue
                    case .completed:
                        gallery
                    }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAddProjectForm = true
                    }) {
                        Label("Add Project", systemImage: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showAddProjectForm, onDismiss: { newProject = nil }) {
                // Swap to the success screen in place so the list never flashes between the two
                if let newProject {
                    ProjectInfo(project: newProject, isNewProject : true, isPopover : true)
                        .transition(.opacity)
                } else {
                    AddOrEditProjectForm(projectToEdit: nil, preSelectedPattern: nil) { addedProject in
                        withAnimation {
                            newProject = addedProject
                        }
                    }
                }
            }
            .fullScreenCover(item: $projectToEdit, onDismiss: { projectToEdit = nil}) { project in
                AddOrEditProjectForm(projectToEdit : project, preSelectedPattern: nil)
            }
            .alert("Are you sure you want to delete this project?", isPresented: $showConfirmationDialog) {
                if let project = projectToDelete {
                    Button("Delete", role: .destructive) {
                        // Give the alert a moment to fade so the row is visible as it goes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            deleteProject(project)
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                managedObjectContext.refreshAllObjects()
                consumeDashboardNavigation()
            }
            .onChange(of: projectToShowAutomatically.wrappedValue?.objectID) {
                consumeDashboardNavigation()
            }
            .onChange(of: projectTabToShowAutomatically.wrappedValue) {
                consumeDashboardNavigation()
            }
            .navigationDestination(item: $selectedProject) { project in
                ProjectInfo(project: project, selectedTab : $selectedTab)
            }
            .fullScreenCover(item: $projectToRead) { project in
                if let pattern = project.pattern, let document = pattern.document {
                    SavedPatternReader(document: document, title: pattern.name ?? "Pattern", project: project)
                }
            }
        }
    }
    
    /// Opens a project (or just the right sub-tab) when arriving from the dashboard.
    private func consumeDashboardNavigation() {
        if let project = projectToShowAutomatically.wrappedValue {
            switch ProjectStatus(project: project) {
            case .completed:  selectedTab = .completed
            case .inProgress: selectedTab = .inProgress
            case .notStarted: selectedTab = .notStarted
            }
            
            projectTabToShowAutomatically.wrappedValue = nil
            projectToShowAutomatically.wrappedValue = nil
            
            // Let the tab filter settle before pushing, and re-push if we were already on a project
            selectedProject = nil
            DispatchQueue.main.async {
                selectedProject = project
            }
            return
        }
        
        if let tab = projectTabToShowAutomatically.wrappedValue {
            selectedTab = tab
            projectTabToShowAutomatically.wrappedValue = nil
        }
    }
    
    // MARK: - In progress
    
    /// Cards with each project's colorway, first counter, and pattern, so work can continue without opening it
    private var workbench: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredProjects, id : \.id) { project in
                    ProjectWorkCard(project: project) {
                        projectToRead = project
                    }
                    .onTapGesture {
                        selectedProject = project
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityAction(named: "Open Project") {
                        selectedProject = project
                    }
                    .contextMenu {
                        projectActions(for: project)
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Not started
    
    private var queue: some View {
        List {
            Section {
                ForEach(filteredProjects, id : \.id) { project in
                    NavigationLink(destination: ProjectInfo(project: project, selectedTab : $selectedTab)) {
                        ProjectQueueRow(project: project) {
                            startProject(project)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            startProject(project)
                        } label: {
                            Label("Start", systemImage: "play.fill")
                        }
                        .tint(ProjectStatus.inProgress.color)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            projectToEdit = project
                        } label: {
                            Label("Edit", systemImage : "pencil")
                        }
                        .tint(Color.accentColor)
                        
                        // A destructive role slides the row out before the user confirms
                        Button {
                            projectToDelete = project
                            showConfirmationDialog = true
                        } label: {
                            Label("Delete", systemImage : "trash")
                        }
                        .tint(Color.red)
                    }
                    .contextMenu {
                        projectActions(for: project)
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image("butterball")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 34)
                        .shadow(radius: 2)
                        .accessibilityHidden(true)
                    
                    Text("What are you waiting for?")
                        .font(.subheadline)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func startProject(_ project: Project) {
        withAnimation {
            project.inProgress = true
            project.startDate = Date.now
            
            PersistenceController.shared.save()
        }
    }
    
    // MARK: - Completed
    
    private struct MonthGroup: Identifiable {
        let month : Date?
        let projects : [Project]
        var id : Date { month ?? Date.distantPast }
    }
    
    private var completedByMonth: [MonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredProjects) { project in
            project.endDate.flatMap { calendar.dateInterval(of: .month, for: $0)?.start }
        }
        
        return grouped
            .map { MonthGroup(month: $0.key, projects: $0.value) }
            .sorted { ($0.month ?? Date.distantPast) > ($1.month ?? Date.distantPast) }
    }
    
    /// Finished pieces by the month they were completed
    private var gallery: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(completedByMonth) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(group.month?.formatted(.dateTime.month(.wide).year()) ?? "No Finish Date")
                                .font(.title3.bold())
                                .foregroundStyle(Color.primary)
                            
                            Text("\(group.projects.count) finished")
                                .font(.subheadline)
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 18) {
                            ForEach(group.projects, id : \.id) { project in
                                ProjectGalleryTile(project: project)
                                    .onTapGesture {
                                        selectedProject = project
                                    }
                                    .accessibilityAction {
                                        selectedProject = project
                                    }
                                    .contextMenu {
                                        projectActions(for: project)
                                    }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    @ViewBuilder
    private func projectActions(for project: Project) -> some View {
        if project.pattern?.document != nil {
            Button {
                projectToRead = project
            } label: {
                Label("Read Pattern", systemImage: "book.pages")
            }
        }
        
        if !project.inProgress && !project.complete {
            Button {
                startProject(project)
            } label: {
                Label("Start", systemImage: "play.circle")
            }
        }
        
        Button {
            projectToEdit = project
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Divider()
        
        Button(role: .destructive) {
            projectToDelete = project
            showConfirmationDialog = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func deleteProject(_ project: Project) {
        guard !project.isDeleted else { return }
        
        withAnimation {
            ProjectUtils.shared.removeProject(at: project, with: managedObjectContext)
        }
    }
}
