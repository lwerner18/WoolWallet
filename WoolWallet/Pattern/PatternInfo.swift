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
        
        if pattern.oneSize == 1 {
            props.append(DetailProp(text: "One Size", icon: "hand.point.up"))
        }
        
        let projectsNum = pattern.projects?.count ?? 0
        
        props.append(DetailProp(text: "\(projectsNum == 1 ? "1 project" : "\(projectsNum) projects")", icon: "hammer"))
        
        return props
    }
    
    var body: some View {
        VStack {
            if isNewPattern || isPopover {
                NewItemHeader(onClose: { dismiss() })
            }
            
            ScrollView {
                if isNewPattern {
                    VStack {
                        Label("", systemImage: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#008000")) // Set text color
                            .symbolEffect(.bounce, value: animateCheckmark)
                            .padding()
                        
                        Text("Successfully created pattern")
                            .font(.title2)
                        
                        Text("Now get crafting!")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .onAppear {
                        animateCheckmark.toggle()
                    }
                }
                
                LazyVStack {
                    PatternItemDisplay(pattern: pattern, size: Size.large)
                    
                    VStack {
                        Text(pattern.name ?? "N/A").font(.largeTitle).foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        
                        Text(pattern.designer ?? "N/A").foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                    .bold()
                    
                    InfoCapsules(detailProps: patternProperties)
                    
                    VStack {
                        if !pattern.patternItems.isEmpty && pattern.patternItems.first!.item != Item.none {
                            InfoCard() {
                                Text(
                                    PatternUtils.shared.joinedItems(patternItems: pattern.patternItems)
                                )
                                .font(.headline)
                                .bold()
                                .foregroundStyle(Color.primary)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        if pattern.hasProjects {
                            Text("Project\(pattern.projectsArray.count > 1 ? "s" : "")")
                                .infoCardHeader()
                            
                            SimpleHorizontalScroll(count: pattern.projectsArray.count) {
                                ForEach(pattern.projectsArray, id : \.id) { project in
                                    ProjectPreview(project: project, displayedProject: $displayedProject, disableOnTap : isPopover)
                                }
                            }
                        }
                        
                        if pattern.weightAndYardageItems.count > 3 {
                            ForEach(pattern.weightAndYardageItems.indices, id: \.self) { index in
                                let item : WeightAndYardageData = pattern.weightAndYardageItems[index]
                                
                                InfoCard() {
                                    CollapsibleView(
                                        label : {
                                            RecYarnHeader(count: pattern.weightAndYardageItems.count, index: index, weightAndYardage: item)
                                        },
                                        showArrows : true
                                    ) {
                                        ViewWeightAndYardage(
                                            weightAndYardage: item.existingItem!,
                                            isSockSet: false,
                                            totalCount: pattern.weightAndYardageItems.count,
                                            hideName : true
                                        )
                                    }
                                }
                                
                                if let suggestion : YarnSuggestion = yarnSuggestions.first(where: {$0.patternWAndY.id == item.id}) {
                                    YarnSuggestions(yarnSuggestion: suggestion)
                                }
                            }
                        } else {
                            ForEach(pattern.weightAndYardageItems.indices, id: \.self) { index in
                                let item : WeightAndYardageData = pattern.weightAndYardageItems[index]
                                
                                ViewWeightAndYardage(
                                    weightAndYardage: item.existingItem!,
                                    isSockSet: false,
                                    totalCount: pattern.weightAndYardageItems.count
                                )
                                
                                if let suggestion : YarnSuggestion = yarnSuggestions.first(where: {$0.patternWAndY.id == item.id}) {
                                    YarnSuggestions(yarnSuggestion: suggestion)
                                }
                            }
                        }
                        
                        if pattern.intendedSize != nil && pattern.intendedSize != "" {
                            InfoCard() {
                                HStack {
                                    Text("Intended Size").foregroundStyle(Color(UIColor.secondaryLabel))
                                    Spacer()
                                    Text(pattern.intendedSize!).font(.headline).bold().foregroundStyle(Color.primary)
                                }
                            }
                        }
                        
                        if pattern.type != PatternType.knit.rawValue && pattern.crochetHooks.first?.hook != CrochetHookSize.none {
                            InfoCard(
                                header : {
                                    if pattern.crochetHooks.count > 1 {
                                        Text("Hooks")
                                    }
                                }
                            ) {
                                if pattern.crochetHooks.count == 1 {
                                    HStack {
                                        Text("Hook").foregroundStyle(Color(UIColor.secondaryLabel))
                                        Spacer()
                                        Text(pattern.crochetHooks.first!.hook.rawValue).font(.headline).bold().foregroundStyle(Color.primary)
                                    }
                                } else {
                                    HStack{
                                        Spacer()
                                        
                                        Text(
                                            "\(pattern.crochetHooks.map{$0.hook.rawValue}.joined(separator: ", "))"
                                        ).font(.headline).bold().foregroundStyle(Color.primary).yarnDataRow()
                                        
                                        Spacer()
                                    }
                                }
                               
                            }
                        }
                        
                        if pattern.type == PatternType.knit.rawValue && pattern.knittingNeedles.first?.needle != KnitNeedleSize.none {
                            InfoCard(
                                header : {
                                    if pattern.knittingNeedles.count > 1 {
                                        Text("Needles")
                                    }
                                }
                            ) {
                                if pattern.knittingNeedles.count == 1 {
                                    HStack {
                                        Text("Needle").foregroundStyle(Color(UIColor.secondaryLabel))
                                        Spacer()
                                        Text(pattern.knittingNeedles.first!.needle.rawValue).font(.headline).bold().foregroundStyle(Color.primary)
                                    }
                                } else {
                                    HStack{
                                        
                                        Spacer()
                                        
                                        Text(
                                            "\(pattern.knittingNeedles.map{$0.needle.rawValue}.joined(separator: ", "))"
                                        ).font(.headline).bold().foregroundStyle(Color.primary).yarnDataRow()
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        if pattern.techniqueItems.first?.technique != PatternTechnique.none {
                            InfoCard(
                                header : {
                                    if pattern.techniqueItems.count > 1 {
                                        Text("Techniques")
                                    }
                                }
                            ) {
                                if pattern.techniqueItems.count == 1 {
                                    HStack {
                                        Text("Technique").foregroundStyle(Color(UIColor.secondaryLabel))
                                        Spacer()
                                        Text(pattern.techniqueItems.first!.technique.rawValue).font(.headline).bold().foregroundStyle(Color.primary)
                                    }
                                } else {
                                    HStack{
                                        Spacer()
                                        
                                        Text(
                                            "\(pattern.techniqueItems.map{$0.technique == PatternTechnique.other ? $0.description : $0.technique.rawValue}.joined(separator: ", "))"
                                        ).multilineTextAlignment(.center).font(.headline).bold().foregroundStyle(Color.primary).yarnDataRow()
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        if pattern.notionItems.first?.notion != PatternNotion.none {
                            InfoCard(
                                header : {
                                    if pattern.notionItems.count > 1 {
                                        Text("Notions")
                                    }
                                }
                            ) {
                                if pattern.notionItems.count == 1 {
                                    HStack {
                                        Text("Notion").foregroundStyle(Color(UIColor.secondaryLabel))
                                        Spacer()
                                        Text(pattern.notionItems.first!.notion.rawValue).font(.headline).bold().foregroundStyle(Color.primary)
                                    }
                                } else {
                                    HStack{
                                        Spacer()
                                        
                                        Text(
                                            "\(pattern.notionItems.map{$0.notion == PatternNotion.other ? $0.description : $0.notion.rawValue}.joined(separator: ", "))"
                                        ).multilineTextAlignment(.center).font(.headline).bold().foregroundStyle(Color.primary).yarnDataRow()
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        if pattern.notes != "" {
                            InfoCard() {
                                Text(pattern.notes!)
                                    .foregroundStyle(Color.primary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .foregroundStyle(Color.black)
                .padding()
            }
            .navigationTitle(pattern.name ?? "N/A")
            .navigationBarTitleDisplayMode(.inline)
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
                if browseMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button() {
                            browsePattern = pattern
                            browseMode = false
                        } label: {
                            Text("Select")
                        }
                    }
                } else if browsePattern != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView("")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
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
            }
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
                AddOrEditProjectForm(
                    projectToEdit: nil,
                    preSelectedPattern: pattern,
                    preSelectedPairings :    pattern.weightAndYardageItems.filter { patternWandY in
                        let suggestions = yarnSuggestions.filter {$0.patternWAndY.id == patternWandY.id}.first?.suggestedWAndY
                        
                        if suggestions != nil && !suggestions!.isEmpty {
                            let favedSuggestions = suggestions!.filter {$0.yarnFavorites != nil && $0.yarnFavorites!.count == 1}
                            
                            return favedSuggestions.count == 1
                        }
                        
                        return false
                    }.map { patternWandY in
                        let suggestions = yarnSuggestions.filter {$0.patternWAndY.id == patternWandY.id}.first?.suggestedWAndY
                        
                        return ProjectPairingItem(
                            patternWeightAndYardage: patternWandY.existingItem!,
                            yarnWeightAndYardage: suggestions!.first!
                        )
                    },
                    yarnSuggestions: yarnSuggestions
                ) { addedProject in
                    
                    selectedTab = PatternTab.used
                    // Capture the newly added project
                    newProject = addedProject
                    showAddProjectForm = false
                }
            }
            .sheet(item: $newProject) { project in
                ProjectInfo(project: project, isNewProject : true, isPopover : true)
            }
            .sheet(item: $displayedProject) { project in
                ProjectInfo(project: project, isPopover: true)
            }
            
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            getSuggestions()
        }
    }
    
    func getSuggestions() {
        DispatchQueue.global(qos: .background).async {
            var temp : [YarnSuggestion] = []
            
            for wAndY in pattern.weightAndYardageItems {
                temp.append(
                    YarnSuggestion(
                        patternWAndY: wAndY.existingItem!,
                        suggestedWAndY: PatternUtils.shared.getMatchingYarns(for: wAndY, in: managedObjectContext)
                    )
                )
            }
            
            DispatchQueue.main.async { // Ensure UI updates are performed on the main thread
                self.yarnSuggestions = temp
            }
        }
    }
}
