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
    var isNewProject : Bool = false
    
    init(
        project: Project,
        isNewProject : Bool = false
    ) {
        self.project = project
        self.isNewProject = isNewProject
        
        self.rowCountersRequest = FetchRequest(
            entity: RowCounter.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "project.id == %@", project.id! as any CVarArg)
        )
    }
    
    
    var rowCountersRequest : FetchRequest<RowCounter>
    var rowCounters : FetchedResults<RowCounter>{rowCountersRequest.wrappedValue}
    
    // Computed property to calculate if device is most likely in portrait mode
    var isPortraitMode: Bool {
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    // Internal state trackers
    @State private var showEditProjectForm : Bool = false
    @State private var showRowCounter : Bool = false
    @State private var showConfirmationDialog = false
    @State private var animateCheckmark = false
    @State private var rowCounter : RowCounter? = nil
    
    var body: some View {
        VStack {
            if isNewProject {
                NewItemHeader(onClose: { dismiss() })
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
                            .foregroundStyle(Color.primary)
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
                    
                    InfoCard() {
                        PatternPreview(pattern: project.pattern!)
                    }
                    
                    SimpleHorizontalScroll(count: project.projectPairingItems.count) {
                        ForEach(project.projectPairingItems, id : \.id) { projectPairingItem in
                            
                            let yarnWAndY = projectPairingItem.yarnWeightAndYardage
                            let patternWAndY = projectPairingItem.patternWeightAndYardage
                            let yarn = yarnWAndY.yarn!
                            
                            InfoCard(header : {
                                project.projectPairingItems.count > 1 
                                ? AnyView(Text("COLOR \(PatternUtils.shared.getLetter(for: Int(patternWAndY.order)))")
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                                    .font(.caption2))
                                : AnyView(EmptyView())
                            }) {
                                HStack {
                                    VStack {
                                        ImageCarousel(images: .constant(yarn.uiImages), smallMode: true)
                                            .xsImageCarousel()
                                        
                                        if yarn.isSockSet {
                                            Label("Sock Set", systemImage : "shoeprints.fill")
                                                .infoCapsule(isSmall: true)
                                            
                                            if yarn.isSockSet {
                                                ZStack {
                                                    switch yarnWAndY.order {
                                                    case 0: Text("Main Skein").font(.caption)
                                                    case 1: Text("Mini Skein").font(.caption)
                                                    case 2: Text("Mini #2").font(.caption)
                                                    default: EmptyView()
                                                    }
                                                }
                                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .center) {
                                        Text(yarn.name!)
                                            .foregroundStyle(Color.primary)
                                            .bold()
                                        
                                        Text(yarn.dyer!)
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                            .font(.caption)
                                            .bold()
                                        
                                        Spacer()
                                        
                                        ViewLengthAndYardage(weightAndYardage: yarnWAndY)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .simpleScrollItem(count: project.projectPairingItems.count)
                        }
                    }
                    
                    VStack {
                        ForEach(rowCounters, id : \.id) { rowCounterItem in
                            InfoCard() {
                                Button {
                                    rowCounter = rowCounterItem
                                } label : {
                                    HStack {
                                        HStack {
                                            Text("\(rowCounterItem.name!)")
                                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                            
                                            Spacer()
                                            
                                            Text("\(rowCounterItem.count)")
                                                .font(.headline).bold().foregroundStyle(Color.primary)
                                        }
                                    }
                                    .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                                        return 0
                                    }
                                }
                            }
                        }
                        
                    }
                    
                    if project.notes != "" {
                        InfoCard() {
                            Text(project.notes!)
                                .frame(maxWidth: .infinity)
                        }
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
                        
                        Button {
                            let newRowCounter = RowCounter(context: managedObjectContext)
                            newRowCounter.name = "Row Counter \(project.rowCounterItems.count)"
                            newRowCounter.project = project
                            
                            PersistenceController.shared.save()
                            
                            rowCounter = newRowCounter
                        } label : {
                            Label("Add Row Counter", systemImage : "number")
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
            .fullScreenCover(
                item: $rowCounter,
                onDismiss: {
                    PersistenceController.shared.save()
                }
            ) { counter in
                RowCounterForm(rowCounter: counter)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
