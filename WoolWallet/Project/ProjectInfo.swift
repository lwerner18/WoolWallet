//
//  ProjectInfo.swift
//  WoolWallet
//
//  Created by Mac on 10/29/24.
//

import Foundation
import SwiftUI


enum ProjectInfoTab: String, CaseIterable, Identifiable {
    case details = "Details"
    case history = "History"
    
    var id: String { rawValue }
}

struct ProjectInfo: View {

    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var project : Project
    @Binding var selectedTab: ProjectTab
    var isNewProject : Bool
    var isPopover : Bool
    
    init(
        project: Project,
        selectedTab : Binding<ProjectTab> = .constant(ProjectTab.inProgress),
        isNewProject : Bool = false,
        isPopover : Bool = false
    ) {
        self.project = project
        self._selectedTab = selectedTab
        self.isNewProject = isNewProject
        self.isPopover = isPopover
        
        self.rowCountersRequest = FetchRequest(
            entity: RowCounter.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \RowCounter.order, ascending: true)],
            // The page is rebuilt once more after the project is deleted, when its id is already gone
            predicate: NSPredicate(format: "project == %@", project)
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
    
    // Internal state trackers
    @State private var showEditProjectForm : Bool = false
    @State private var showRowCounter : Bool = false
    @State private var showPostCompleteForm : Bool = false
    @State private var showConfirmationDialog = false
    @State private var animateCheckmark = false
    @State private var rowCounter : RowCounter? = nil
    @State private var counterToDelete : RowCounter? = nil
    @State private var startDateInput : Date = Date()
    @State private var endDateInput : Date = Date()
    @State private var displayedPattern : Pattern? = nil
    @State private var displayedYarn : Yarn? = nil
    @State private var showReader : Bool = false
    @State private var showPhotoViewer : Bool = false
    @State private var infoTab : ProjectInfoTab = .details
    @State private var showSummaryExport : Bool = false
    
    
    var body: some View {
        if isPopover {
            NavigationStack {
                content
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { dismiss() }
                        }
                    }
            }
        } else {
            content
        }
    }
    
    private var content: some View {
        VStack {
            if !project.isDeleted, project.managedObjectContext != nil, let pattern = project.pattern {
                ScrollView {
                    if isNewProject {
                        VStack {
                            Label("", systemImage: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.green)
                                .symbolEffect(.bounce, value: animateCheckmark)
                                .padding()
                                .accessibilityHidden(true)
                            
                            Text("Successfully created project")
                                .font(.title2)
                                .foregroundStyle(Color.primary)
                            
                            Text("Now get crafting!")
                                .foregroundStyle(Color.secondary)
                                .font(.subheadline)
                        }
                        .onAppear {
                            animateCheckmark.toggle()
                        }
                    }
                    
                    hero(for: pattern)
                    
                    if !isNewProject {
                        Picker("Section", selection: $infoTab) {
                            ForEach(ProjectInfoTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    
                    if infoTab == .history && !isNewProject {
                        ProjectRowHistory(project: project)
                            .padding(.bottom)
                    } else {
                        detailsSection(for: pattern)
                    }
                }
                .navigationTitle("\(pattern.name ?? "Project") (Project)")
                .navigationBarTitleDisplayMode(.inline)
                .scrollBounceBehavior(.basedOnSize)
                .toolbar {
                    if !isPopover {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    showEditProjectForm = true
                                } label : {
                                    Label("Edit", systemImage : "pencil")
                                }
                                
                                Button {
                                    withAnimation {
                                        _ = project.addRowCounter(in: managedObjectContext)
                                    }
                                } label : {
                                    Label("Add Row Counter", systemImage : "number")
                                }
                                
                                Button {
                                    showSummaryExport = true
                                } label: {
                                    Label("Export Summary", systemImage: "square.and.arrow.up")
                                }
                                
                                Divider()
                                
                                if project.inProgress {
                                    Button {
                                        project.inProgress = false
                                        project.startDate = nil
                                        
                                        selectedTab = ProjectTab.notStarted
                                        
                                        PersistenceController.shared.save()
                                    } label : {
                                        Label("Mark as Not Started", systemImage : "pause.circle")
                                    }
                                }
                                
                                if !project.complete && project.inProgress {
                                    Button {
                                        project.inProgress = false
                                        project.complete = true
                                        project.endDate = Date.now
                                        
                                        selectedTab = ProjectTab.completed
                                        
                                        PersistenceController.shared.save()
                                        
                                        showPostCompleteForm = true
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
                                        
                                        selectedTab = ProjectTab.inProgress
                                        
                                        PersistenceController.shared.save()
                                    } label : {
                                        Label("Mark as In Progress", systemImage : "play.circle")
                                    }
                                }
                                
                                if !project.complete && !project.inProgress  {
                                    Button {
                                        project.inProgress = true
                                        project.startDate = Date.now
                                        
                                        selectedTab = ProjectTab.inProgress
                                        
                                        PersistenceController.shared.save()
                                    } label : {
                                        Label("Start", systemImage : "play.circle")
                                    }
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    showConfirmationDialog = true
                                } label: {
                                    Label("Delete", systemImage : "trash")
                                }
                            } label: {
                                Label("More", systemImage : "ellipsis.circle")
                            }
                        }
                    }
                }
                .alert("Are you sure you want to delete this project?", isPresented: $showConfirmationDialog) {
                    Button("Delete", role: .destructive) {
                        dismiss()
                        
                        // Let the page finish popping so the row is on screen when it animates away
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [project, managedObjectContext] in
                            guard !project.isDeleted else { return }
                            
                            withAnimation {
                                ProjectUtils.shared.removeProject(at: project, with: managedObjectContext)
                            }
                        }
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }
                .fullScreenCover(isPresented: $showEditProjectForm) {
                    AddOrEditProjectForm(projectToEdit: project, preSelectedPattern : nil)
                }
                .sheet(
                    item: $rowCounter
                ) { counter in
                    RowCounterForm(rowCounter: counter)
                }
                .sheet(item: $displayedPattern) { pattern in
                    PatternInfo(pattern: pattern, isPopover: true)
                }
                .sheet(isPresented: $showPostCompleteForm) {
                    PostCompleteForm(project: project)
                }
                .sheet(item: $displayedYarn) { yarn in
                    YarnInfo(yarn: yarn, isPopover: true)
                }
                .fullScreenCover(isPresented: $showReader) {
                    if let document = pattern.document {
                        SavedPatternReader(document: document, title: pattern.name ?? "Pattern", project: project)
                    }
                }
                .fullScreenCover(isPresented: $showPhotoViewer) {
                    PhotoViewer(images: project.uiImages.map(\.image), startIndex: 0)
                }
                .sheet(isPresented: $showSummaryExport) {
                    SummaryExportPreview(subject: .project(project))
                }
                .onChange(of: rowCounter) {
                    PersistenceController.shared.save()
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Details
    
    @ViewBuilder
    private func detailsSection(for pattern: Pattern) -> some View {
        LazyVStack {
            if pattern.document != nil {
                ReadPatternButton { showReader = true }
            }
            
            datesCard
            
            if !rowCounters.isEmpty || project.inProgress {
                Text("Row Counters")
                    .infoCardHeader()
                
                rowCounterGrid
            }
            
            Text("Pattern")
                .infoCardHeader()
            
            InfoCard() {
                if displayedPattern != nil {
                    CenteredLoader()
                } else {
                    PatternPreview(pattern: pattern)
                }
            }
            .onTapGesture {
                if !isPopover {
                    displayedPattern = pattern
                }
            }
            
            yarnPairingsSection
            
            if let notes = project.notes, !notes.isEmpty {
                InfoCard() {
                    Text(notes)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            RecordDates(added: project.dateAdded, updated: project.dateUpdated)
        }
        .foregroundStyle(Color.primary)
        .padding()
    }
    
    @ViewBuilder
    private var datesCard: some View {
        if project.startDate != nil || project.endDate != nil {
            InfoCard() {
                VStack {
                    if project.startDate != nil {
                        HStack(alignment: .center) {
                            Text("Start Date")
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                            
                            Spacer(minLength: 8)
                            
                            StableCompactDatePicker(
                                date: $startDateInput,
                                maximumDate: Date()
                            )
                            .fixedSize()
                            .onChange(of: startDateInput) {
                                project.startDate = startDateInput
                                PersistenceController.shared.save()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if project.endDate != nil {
                        Divider()
                        
                        HStack(alignment: .center) {
                            Text("End Date")
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                            
                            Spacer(minLength: 8)
                            
                            StableCompactDatePicker(
                                date: $endDateInput,
                                minimumDate: startDateInput
                            )
                            .fixedSize()
                            .onChange(of: endDateInput) {
                                project.endDate = endDateInput
                                PersistenceController.shared.save()
                            }
                        }
                        .padding(.vertical, 8)
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
    }
    
    @ViewBuilder
    private var yarnPairingsSection: some View {
        let pairings = project.projectPairingItems
        
        if pairings.count == 1 {
            Text("Yarn")
                .infoCardHeader()
        }
        
        SimpleHorizontalScroll(count: pairings.count) {
            ForEach(pairings, id: \.id) { projectPairingItem in
                let patternWAndY = projectPairingItem.patternWeightAndYardage
                let yarn = projectPairingItem.yarnWeightAndYardage.yarn
                
                InfoCard(header: {
                    pairings.count > 1
                    ? AnyView(Text("COLOR \(PatternUtils.shared.getLetter(for: Int(patternWAndY.order)))"))
                    : AnyView(EmptyView())
                }) {
                    if let yarn, displayedYarn == yarn {
                        CenteredLoader()
                    } else if let existingItem = projectPairingItem.existingItem {
                        YarnPreviewForProject(
                            yarnWandY: projectPairingItem.yarnWeightAndYardage,
                            projectPairing: existingItem,
                            project: project
                        )
                    }
                }
                .onTapGesture {
                    if !isPopover, let yarn {
                        displayedYarn = yarn
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private let coverSize = CGSize(width: 96, height: 128)
    private var coverOverlap : CGFloat { coverSize.height / 2 }
    
    /// The yarn's colors, or the item's color when no yarn is paired
    private func headerColors(for pattern: Pattern) -> [Color] {
        let colors = Array(project.yarnColors.prefix(5))
        
        switch colors.count {
        case 0:
            let color = PatternUtils.shared.getItemDisplay(for: pattern.patternItems.first?.item).color
            return [color.opacity(0.45), color.opacity(0.15)]
        case 1:
            // A gradient needs two stops
            return [colors[0], colors[0].opacity(0.55)]
        default:
            return colors
        }
    }
    
    /// A wide photo of the piece with the pattern cover tucked over its bottom edge, washed in the yarn's colors
    private func hero(for pattern: Pattern) -> some View {
        let colors = headerColors(for: pattern)
        
        return VStack(alignment: .leading, spacing: 0) {
            banner(for: pattern)
            
            HStack(alignment: .top, spacing: 14) {
                Button {
                    displayedPattern = pattern
                } label: {
                    PatternCover(pattern: pattern, cornerRadius: 8, iconSize: Size.medium)
                        .frame(width: coverSize.width, height: coverSize.height)
                        // Placeholder covers are translucent and would pick up the header colors
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.secondarySystemGroupedBackground), lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!isPopover)
                .accessibilityLabel("Pattern: \(pattern.name ?? "No Name")")
                .accessibilityHidden(isPopover)
                .padding(.top, -coverOverlap)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.name ?? "No Name")
                        .font(.title2.bold())
                        .foregroundStyle(Color.primary)
                        .lineLimit(3)
                        .accessibilityAddTraits(.isHeader)
                    
                    ProjectStatusLine(project: project)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.primary)
                    
                    if let designer = pattern.designer, !designer.isEmpty {
                        Text("by \(designer)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .lineLimit(1)
                    }
                }
                .padding(.top, 10)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .background(alignment: .top) {
                // A photo covers the top of the header, so the colors start under it instead
                if project.hasImages {
                    colorWash(colors, opacity: 0.5)
                }
            }
        }
        .background(alignment: .top) {
            if !project.hasImages {
                colorWash(colors, opacity: 0.9)
            }
        }
    }
    
    private func colorWash(_ colors: [Color], opacity: Double) -> some View {
        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            .opacity(opacity)
            .mask(
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.55), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // Lets the wash fade out below the title instead of stopping at its edge
            .padding(.bottom, -40)
            .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private func banner(for pattern: Pattern) -> some View {
        if project.hasImages {
            let count = project.images?.count ?? 0
            
            Button {
                showPhotoViewer = true
            } label: {
                FirstStoredPhoto(images: project.images, maxPixelSize: 1200) {
                    Color(UIColor.tertiarySystemFill)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .overlay(alignment: .bottomTrailing) {
                    if count > 1 {
                        PatternCoverBadge(text: "\(count)", systemImage: "photo.on.rectangle")
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(count > 1 ? "View \(count) Photos" : "View Photo")
        } else {
            // The header's color wash shows through here
            Color.clear
                .frame(height: 130)
        }
    }
    
    // MARK: - Row counters
    
    /// Counters two to a row, followed by a tile that adds another
    private var rowCounterGrid: some View {
        let counters = Array(rowCounters)
        let cellCount = counters.count + 1
        
        return Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            ForEach(Array(stride(from: 0, to: cellCount, by: 2)), id: \.self) { start in
                GridRow {
                    ForEach(start..<min(start + 2, cellCount), id: \.self) { index in
                        if index < counters.count {
                            InlineRowCounter(counter: counters[index]) {
                                rowCounter = counters[index]
                            } onDelete: {
                                counterToDelete = counters[index]
                            }
                        } else {
                            addCounterTile(fillsRow: index % 2 == 0)
                        }
                    }
                }
            }
        }
        .alert(
            "Delete \u{201C}\(counterToDelete?.name ?? "Counter")\u{201D}?",
            isPresented: Binding(
                get: { counterToDelete != nil },
                set: { if !$0 { counterToDelete = nil } }
            ),
            presenting: counterToDelete
        ) { counter in
            Button("Delete", role: .destructive) {
                deleteCounter(counter)
            }
            
            Button("Cancel", role: .cancel) {}
        } message: { counter in
            Text("Its count of \(counter.count) will be lost.")
        }
    }
    
    private func deleteCounter(_ counter: RowCounter) {
        withAnimation {
            managedObjectContext.delete(counter)
            
            for (index, remaining) in rowCounters.filter({ $0 != counter }).enumerated() {
                remaining.order = Int16(index)
            }
            
            PersistenceController.shared.save()
        }
    }
    
    private func addCounterTile(fillsRow: Bool) -> some View {
        Button {
            withAnimation {
                _ = project.addRowCounter(in: managedObjectContext)
            }
        } label: {
            Group {
                if fillsRow {
                    Label(rowCounters.isEmpty ? "Add Row Counter" : "Add Counter", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 50)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                        
                        Text("Add Counter")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .font(.subheadline.bold())
            .foregroundStyle(Color.accentColor)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .gridCellColumns(fillsRow ? 2 : 1)
    }
}
