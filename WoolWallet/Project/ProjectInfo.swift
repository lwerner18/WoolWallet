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
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    
    @ObservedObject var project : Project
    var isNewProject : Bool
    var isPopover : Bool
    
    init(
        project: Project,
        isNewProject : Bool = false,
        isPopover : Bool = false
    ) {
        self.project = project
        self.isNewProject = isNewProject
        self.isPopover = isPopover
        
        self.rowCountersRequest = FetchRequest(
            entity: RowCounter.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \RowCounter.order, ascending: true)],
            predicate: NSPredicate(format: "project.id == %@", project.id! as any CVarArg)
        )
        
        if project.startDate != nil {
            _startDateInput = State(initialValue: project.startDate!)
        }
        
        if project.endDate != nil {
            _endDateInput = State(initialValue: project.endDate!)
        }
    }
    
    
    var rowCountersRequest : FetchRequest<RowCounter>
    var rowCounters : FetchedResults<RowCounter>{rowCountersRequest.wrappedValue}
    
    // Computed property to calculate if device is most likely in portrait mode
    var isPortraitMode: Bool {
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    var projectProperties: [DetailProp] {
        var props : [DetailProp] = []
        
        if project.complete {
            props.append(DetailProp(text: "Complete", icon: "checkmark.circle"))
        }
        
        if project.inProgress {
            props.append(DetailProp(text: "In Progress", icon: "play.circle"))
        }
        
        if !project.complete && !project.inProgress {
            props.append(DetailProp(text: "Not Started", icon: "pause.circle"))
        }
        
        return props
    }
    
    // Internal state trackers
    @State private var showEditProjectForm : Bool = false
    @State private var showRowCounter : Bool = false
    @State private var showConfirmationDialog = false
    @State private var animateCheckmark = false
    @State private var rowCounter : RowCounter? = nil
    @State private var startDateInput : Date = Date()
    @State private var endDateInput : Date = Date()
    @State private var displayedPattern : Pattern? = nil
    @State private var displayedYarn : Yarn? = nil
    
    
    var body: some View {
        VStack {
            if isPopover {
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
                        PatternItemDisplay(pattern: project.pattern!, size: Size.large)
                    } else {
                        ImageCarousel(images: .constant(project.uiImages))
                    }
                    
                    
                    HStack {
                        Image(systemName: "hammer")
                            .font(.title3)
                        
                        Text(project.pattern!.name!)
                            .font(.largeTitle)
                            .foregroundStyle(Color.primary)
                    }
                    .bold()
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    
                    InfoCapsules(detailProps: projectProperties)
                    
                    if project.startDate != nil || project.endDate != nil {
                        InfoCard() {
                            VStack {
                                if project.startDate != nil {
                                    HStack {
                                        Text("Start Date")
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                        
                                        Spacer()
                                        
                                        DatePicker("", selection: $startDateInput,  in: ...Date(), displayedComponents: [.date])
                                            .onChange(of: startDateInput) {
                                                project.startDate = startDateInput
                                                
                                                PersistenceController.shared.save()
                                            }
                                    }
                                    .yarnDataRow()
                                }
                                
                                if project.endDate != nil {
                                    Divider()
                                    
                                    HStack {
                                        Text("End Date")
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                        
                                        Spacer()
                                        
                                        DatePicker("", selection: $endDateInput, in: startDateInput..., displayedComponents: [.date])
                                            .onChange(of: endDateInput) {
                                                project.endDate = endDateInput
                                                
                                                PersistenceController.shared.save()
                                            }
                                    }
                                    .yarnDataRow()
                                }
                                
                                if project.inProgress {
                                    let daysPassed = Calendar.current.dateComponents([.day], from: startDateInput, to: Date.now).day ?? 0
            
                                    if daysPassed > 0 {
                                        Divider()
                                        
                                        HStack {
                                            Spacer()
                                            
                                            Image(systemName : "timer")
            
                                            Text("\(daysPassed) day\(daysPassed != 1 ? "s" : "") passed")
                                            
                                            Spacer()
                                        }
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .yarnDataRow()
                                    }
                                }
                                
                                if project.complete {
                                    let daysPassed = Calendar.current.dateComponents([.day], from: startDateInput, to: endDateInput).day ?? 0
                                    
                                    Divider()
                                    
                                    HStack {
                                        Spacer()
                                        
                                        Image(systemName : "calendar")
                                        
                                        Text("Took \(daysPassed) day\(daysPassed != 1 ? "s" : "")")
                                        
                                        Spacer()
                                    }
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                                    .yarnDataRow()
                                }
                            }
                        }
                    }
                    
                    Text("Pattern")
                        .infoCardHeader()
                    
                    InfoCard() {
                        if displayedPattern != nil {
                            CenteredLoader()
                        } else {
                            PatternPreview(pattern: project.pattern!)
                        }
                    }
                    .onTapGesture {
                        if !isPopover {
                            displayedPattern = project.pattern!
                        }
                    }
                    
                    if project.projectPairingItems.count == 1 {
                        Text("Yarn")
                            .infoCardHeader()
                    }
                    
                    SimpleHorizontalScroll(count: project.projectPairingItems.count) {
                        ForEach(project.projectPairingItems, id : \.id) { projectPairingItem in
                            let patternWAndY = projectPairingItem.patternWeightAndYardage
                            
                            InfoCard(header : {
                                project.projectPairingItems.count > 1
                                ? AnyView(Text("COLOR \(PatternUtils.shared.getLetter(for: Int(patternWAndY.order)))"))
                                : AnyView(EmptyView())
                            }) {
                                if displayedYarn == projectPairingItem.yarnWeightAndYardage.yarn! {
                                    CenteredLoader()
                                } else {
                                    YarnPreview(yarnWandY : projectPairingItem.yarnWeightAndYardage)
                                }
                            }
                            .simpleScrollItem(count: project.projectPairingItems.count)
                            .onTapGesture {
                                if !isPopover {
                                    displayedYarn = projectPairingItem.yarnWeightAndYardage.yarn!
                                }
                            }
                        }
                    }
                    
                    if !rowCounters.isEmpty {
                        InfoCard(
                            header : {
                                Text("Row Counters")
                            },
                            footer : {
                                HStack {
                                    Spacer()
                                    
                                    Button {
                                        let newRowCounter = RowCounter(context: managedObjectContext)
                                        newRowCounter.name = "Row Counter \(rowCounters.count)"
                                        newRowCounter.project = project
                                        newRowCounter.order = Int16(rowCounters.count)
                                        
                                        PersistenceController.shared.save()
                                        
                                        rowCounter = newRowCounter
                                    } label : {
                                        Text("Need another counter?")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        ) {
                            ForEach(rowCounters, id : \.id) { rowCounterItem in
                                
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
                                .foregroundStyle(Color.primary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .foregroundStyle(Color.black)
                .padding()
             
            }
            .navigationTitle("\(project.pattern!.name!) (Project)")
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
            .popover(
                item: $rowCounter
            ) { counter in
                RowCounterForm(rowCounter: counter)
            }
            .popover(item: $displayedPattern) { pattern in
                PatternInfo(pattern: pattern, isPopover: true)
            }
            .popover(item: $displayedYarn) { yarn in
                YarnInfo(yarn: yarn, isPopover: true)
            }
            .onChange(of: rowCounter) {
                PersistenceController.shared.save()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
