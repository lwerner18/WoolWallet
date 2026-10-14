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
    
    var patternProperties: [DetailProp] {
        var props : [DetailProp] = []
        
        props.append(DetailProp(text: pattern.type!, icon: pattern.type == PatternType.knit.rawValue ? "knit" : "crochet2", useImage: true))
        
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
                    PatternUtils.shared.removePattern(at: pattern, with: managedObjectContext)
                    
                    selectedTab = PatternTab.all
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditPatternForm, onDismiss : getSuggestions) {
                AddOrEditPatternForm(patternToEdit: pattern)
            }
            .sheet(isPresented: $showAddProjectForm) {
                addProjectSheet
            }
            .sheet(item: $newProject) { project in
                ProjectInfo(project: project, isNewProject : true, isPopover : true)
            }
            .sheet(item: $displayedProject) { project in
                ProjectInfo(project: project, isPopover: true)
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
                PatternItemDisplay(pattern: pattern, size: Size.large)
                
                titleSection
                
                InfoCapsules(detailProps: patternProperties)
                
                VStack {
                    itemsCard
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
                    imagesSection
                    notesSection
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
    
    private var titleSection: some View {
        VStack {
            Text(pattern.name ?? "N/A").font(.largeTitle).foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            Text(pattern.designer ?? "N/A").foregroundStyle(Color(UIColor.secondaryLabel))
        }
        .bold()
    }
    
    @ViewBuilder
    private var itemsCard: some View {
        if let firstItem = pattern.patternItems.first, firstItem.item != Item.none {
            InfoCard() {
                Text(
                    PatternUtils.shared.joinedItems(patternItems: pattern.patternItems)
                )
                .multilineTextAlignment(.center)
                .font(.headline)
                .bold()
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private var projectsSection: some View {
        if pattern.hasProjects {
            Text("Project\(pattern.projectsArray.count > 1 ? "s" : "")")
                .infoCardHeader()
            
            SimpleHorizontalScroll(count: pattern.projectsArray.count) {
                ForEach(pattern.projectsArray, id : \.id) { project in
                    ProjectPreview(project: project, displayedProject: $displayedProject, disableOnTap : isPopover)
                }
            }
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
    private var imagesSection: some View {
        if pattern.hasImages {
            Text("Images")
                .infoCardHeader()
            
            ImageCarousel(images: .constant(pattern.uiImages))
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
            // Capture the newly added project
            newProject = addedProject
            showAddProjectForm = false
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
