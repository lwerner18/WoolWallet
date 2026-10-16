//
//  PatternInfo.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

struct YarnSuggestion {
    var patternWAndY : WeightAndYardage
    var suggestedWAndY : [WeightAndYardage] = []
}

struct PatternInfo: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var pattern : Pattern
    @Binding var selectedTab: PatternTab
    var isNewPattern : Bool
    var isPopover : Bool
    @Binding var browseMode : Bool
    @Binding var browsePattern : Pattern?
    
    init(
        pattern: Pattern,
        selectedTab : Binding<PatternTab> = .constant(PatternTab.all),
        isNewPattern : Bool = false,
        isPopover : Bool = false,
        browseMode: Binding<Bool> = .constant(false),
        browsePattern : Binding<Pattern?> = .constant(nil)
    ) {
        self.pattern = pattern
        self._selectedTab = selectedTab
        self.isNewPattern = isNewPattern
        self.isPopover = isPopover
        self._browseMode = browseMode
        self._browsePattern = browsePattern
    }
    
    // Internal state trackers
    @State private var showEditPatternForm : Bool = false
    @State private var showAddProjectForm : Bool = false
    @State private var showConfirmationDialog = false
    @State private var animateCheckmark = false
    @State private var yarnSuggestions : [YarnSuggestion] = []
    @State private var newProject             : Project? = nil
    @State private var displayedProject       : Project? = nil
    @State private var showReader             : Bool = false
    @State private var showPhotoViewer        : Bool = false
    
    var patternProperties: [DetailProp] {
        var props : [DetailProp] = []
        
        if pattern.oneSize {
            props.append(DetailProp(text: "One Size", icon: "hand.point.up"))
        }
        
        if pattern.owned {
            props.append(DetailProp(text: "Owned", icon: "tag"))
        } else {
            props.append(DetailProp(text: "Not Owned", icon: "tag.slash"))
        }
        
        let projectsNum = pattern.projects?.count ?? 0
        
        props.append(DetailProp(text: "\(projectsNum == 1 ? "1 project" : "\(projectsNum) projects")", icon: "hammer"))
        
        return props
    }
    
    var body: some View {
        if isNewPattern || isPopover {
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
    
    private var showsTrailingToolbarItem: Bool {
        browseMode || browsePattern != nil || (!isNewPattern && !isPopover)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if showsTrailingToolbarItem {
            ToolbarItem(placement: .topBarTrailing) {
                trailingToolbarItem
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolbarItem: some View {
        if browseMode {
            Button("Select") {
                browsePattern = pattern
                browseMode = false
            }
        } else if browsePattern != nil {
            ProgressView()
        } else {
            moreMenu
        }
    }
    
    private var moreMenu: some View {
        Menu {
            Button {
                showEditPatternForm = true
            } label : {
                Label("Edit", systemImage : "pencil")
            }
            
            Button {
                showAddProjectForm = true
            } label : {
                Label("Start a Project", systemImage : "hammer")
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
    
    private var content: some View {
        scrollContent
            .navigationTitle(pattern.name ?? "N/A")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Are you sure you want to delete this pattern?", isPresented: $showConfirmationDialog) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    
                    // Let the page finish popping so the row is on screen when it animates away
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [pattern, managedObjectContext] in
                        guard !pattern.isDeleted else { return }
                        
                        withAnimation {
                            PatternUtils.shared.removePattern(at: pattern, with: managedObjectContext)
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditPatternForm, onDismiss : getSuggestions) {
                AddOrEditPatternForm(patternToEdit: pattern)
            }
            .sheet(isPresented: $showAddProjectForm, onDismiss: { newProject = nil }) {
                // Swap to the success screen in place so this page never flashes between the two
                if let newProject {
                    ProjectInfo(project: newProject, isNewProject : true, isPopover : true)
                        .transition(.opacity)
                } else {
                    addProjectSheet
                }
            }
            .sheet(item: $displayedProject) { project in
                ProjectInfo(project: project, isPopover: true)
            }
            .fullScreenCover(isPresented: $showReader) {
                if let document = pattern.document {
                    SavedPatternReader(document: document, title: pattern.name ?? "Pattern")
                }
            }
            .fullScreenCover(isPresented: $showPhotoViewer) {
                PhotoViewer(images: pattern.uiImages.map(\.image), startIndex: 0)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                getSuggestions()
            }
    }
    
    private var scrollContent: some View {
        ScrollView {
            successHeader
            
            LazyVStack {
                coverHeader
                
                titleSection
                
                InfoCapsules(detailProps: patternProperties, alignment: .center)
                
                VStack {
                    if pattern.document != nil {
                        ReadPatternButton { showReader = true }
                    }
                    
                    projectsSection
                    weightAndYardageSection
                    intendedSizeCard
                    toolsCard
                    listCard(
                        title: "Technique",
                        pluralTitle: "Techniques",
                        values: pattern.techniqueItems.first?.technique == PatternTechnique.none ? [] : pattern.techniqueItems.map {
                            $0.technique == PatternTechnique.other ? $0.description : $0.technique.rawValue
                        }
                    )
                    listCard(
                        title: "Notion",
                        pluralTitle: "Notions",
                        values: pattern.notionItems.first?.notion == PatternNotion.none ? [] : pattern.notionItems.map {
                            $0.notion == PatternNotion.other ? $0.description : $0.notion.rawValue
                        }
                    )
                    notesSection
                    RecordDates(added: pattern.dateAdded, updated: pattern.dateUpdated)
                }
            }
            .foregroundStyle(Color.primary)
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
    }
    
    @ViewBuilder
    private var successHeader: some View {
        if isNewPattern {
            VStack {
                Label("", systemImage: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.green)
                    .symbolEffect(.bounce, value: animateCheckmark)
                    .padding()
                    .accessibilityHidden(true)
                
                Text("Successfully created pattern")
                    .font(.title2)
                
                Text("Now get crafting!")
                    .foregroundStyle(Color.secondary)
                    .font(.subheadline)
            }
            .onAppear {
                animateCheckmark.toggle()
            }
        }
    }
    
    /// Cover card at the top — photos open the viewer; PDF-only covers open the reader
    @ViewBuilder
    private var coverHeader: some View {
        let cover = PatternCover(pattern: pattern, cornerRadius: 14)
            .aspectRatio(3 / 4, contentMode: .fit)
            .frame(width: 210)
            .patternCoverBadges(for: pattern, status: PatternStatus(pattern: pattern), padding: 8)
            .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
            .padding(.vertical, 8)
        
        if pattern.hasImages {
            Button {
                showPhotoViewer = true
            } label: {
                cover
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pattern Photos")
            .accessibilityHint("Opens the photos full screen")
        } else if pattern.document != nil {
            Button {
                showReader = true
            } label: {
                cover
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Read Pattern")
        } else {
            cover
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 4) {
            Text(pattern.name ?? "N/A")
                .font(.title.bold())
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            if let designer = pattern.designer, !designer.isEmpty {
                Text(designer)
                    .font(.headline)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
            }
            
            Text(pattern.typeAndItems)
                .font(.subheadline)
                .foregroundStyle(Color(UIColor.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private var projectsSection: some View {
        let projects = pattern.sortedProjects
        
        if !projects.isEmpty {
            Text(projects.count == 1 ? "Project" : "Projects")
                .infoCardHeader()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(projects, id: \.objectID) { project in
                        let compact = projects.count == 1 && !project.hasImages
                        
                        ProjectCard(
                            project: project,
                            compact: compact,
                            isOpening: displayedProject?.objectID == project.objectID
                        ) {
                            guard !isPopover else { return }
                            displayedProject = project
                        }
                        .containerRelativeFrame(.horizontal) { length, _ in
                            compact || projects.count == 1 ? length : length * 0.62
                        }
                    }
                }
            }
            .scrollClipDisabled(false)
            .scrollDisabled(projects.count <= 1)
        }
    }
    
    @ViewBuilder
    private var weightAndYardageSection: some View {
        if pattern.weightAndYardageArray.count > 3 {
            ForEach(pattern.weightAndYardageItems.indices, id: \.self) { index in
                collapsibleWeightAndYardage(at: index)
            }
        } else {
            ForEach(pattern.weightAndYardageArray.indices, id: \.self) { index in
                let item : WeightAndYardage = pattern.weightAndYardageArray[index]
                
                ViewWeightAndYardage(
                    weightAndYardage: item,
                    isSockSet: false,
                    totalCount: pattern.weightAndYardageArray.count
                )
                
                yarnSuggestions(for: item.id)
            }
        }
    }
    
    @ViewBuilder
    private func collapsibleWeightAndYardage(at index: Int) -> some View {
        let item : WeightAndYardageData = pattern.weightAndYardageItems[index]
        
        if let existingItem = item.existingItem {
            InfoCard() {
                CollapsibleView(
                    label : {
                        RecYarnHeader(count: pattern.weightAndYardageArray.count, index: index, weightAndYardage: item)
                    },
                    showArrows : true
                ) {
                    ViewWeightAndYardage(
                        weightAndYardage: existingItem,
                        isSockSet: false,
                        totalCount: pattern.weightAndYardageArray.count,
                        hideName : true
                    )
                }
            }
        }
        
        yarnSuggestions(for: item.id)
    }
    
    @ViewBuilder
    private func yarnSuggestions(for id: UUID?) -> some View {
        if let suggestion : YarnSuggestion = yarnSuggestions.first(where: {$0.patternWAndY.id == id}) {
            YarnSuggestions(yarnSuggestion: suggestion)
        }
    }
    
    @ViewBuilder
    private var intendedSizeCard: some View {
        if let intendedSize = pattern.intendedSize, intendedSize != "" {
            InfoCard() {
                HStack {
                    Text("Intended Size").foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text(intendedSize).font(.headline).bold().foregroundStyle(Color.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var toolsCard: some View {
        if pattern.type == PatternType.knit.rawValue {
            listCard(
                title: "Needle",
                pluralTitle: "Needles",
                values: pattern.knittingNeedles.first?.needle == KnitNeedleSize.none ? [] : pattern.knittingNeedles.map { $0.needle.rawValue }
            )
        } else {
            listCard(
                title: "Hook",
                pluralTitle: "Hooks",
                values: pattern.crochetHooks.first?.hook == CrochetHookSize.none ? [] : pattern.crochetHooks.map { $0.hook.rawValue }
            )
        }
    }
    
    @ViewBuilder
    private func listCard(title: String, pluralTitle: String, values: [String]) -> some View {
        if values.count == 1 {
            InfoCard() {
                HStack {
                    Text(title).foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text(values[0]).font(.headline).bold().foregroundStyle(Color.primary)
                }
            }
        } else if values.count > 1 {
            InfoCard(header: { Text(pluralTitle) }) {
                HStack {
                    Spacer()
                    
                    Text(values.joined(separator: ", "))
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(Color.primary)
                        .yarnDataRow()
                    
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        if let notes = pattern.notes, notes != "" {
            InfoCard() {
                Text(notes)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var addProjectSheet: some View {
        AddOrEditProjectForm(
            projectToEdit: nil,
            preSelectedPattern: pattern,
            preSelectedPairings: preSelectedPairings,
            yarnSuggestions: yarnSuggestions
        ) { addedProject in
            selectedTab = PatternTab.used
            
            withAnimation {
                newProject = addedProject
            }
        }
    }
    
    // Pre-pair any recommended yarn that has exactly one favorited match
    private var preSelectedPairings: [ProjectPairingItem] {
        pattern.weightAndYardageItems.compactMap { patternWandY -> ProjectPairingItem? in
            guard let existingItem = patternWandY.existingItem,
                  let suggestions = yarnSuggestions.first(where: { $0.patternWAndY.id == patternWandY.id })?.suggestedWAndY,
                  let firstSuggestion = suggestions.first else {
                return nil
            }
            
            let favedSuggestions = suggestions.filter { $0.yarnFavorites?.count == 1 }
            
            guard favedSuggestions.count == 1 else { return nil }
            
            return ProjectPairingItem(
                patternWeightAndYardage: existingItem,
                yarnWeightAndYardage: firstSuggestion
            )
        }
    }
    
    func getSuggestions() {
        // viewContext is main-queue bound; perform keeps the fetches on its queue without blocking appear
        managedObjectContext.perform {
            var temp : [YarnSuggestion] = []
            
            for wAndY in pattern.weightAndYardageItems {
                temp.append(
                    YarnSuggestion(
                        patternWAndY: wAndY.existingItem!,
                        suggestedWAndY: PatternUtils.shared.getMatchingYarns(for: wAndY, in: managedObjectContext)
                    )
                )
            }
            
            self.yarnSuggestions = temp
        }
    }
}
