//
//  YarnInfo.swift
//  WoolWallet
//
//  Created by Mac on 3/15/24.
//

import Foundation
import SwiftUI
import CoreData

struct PatternSuggestion {
    var yarnWAndY : WeightAndYardage
    var suggestedWAndY : [WeightAndYardage] = []
}

struct DetailProp : Hashable {
    var id : String { UUID().uuidString }
    
    var text : String
    var icon : String
    var useImage : Bool = false
}

struct YarnInfo: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext

    
    @ObservedObject var yarn : Yarn
    @Binding var selectedTab: YarnTab
    @Binding var browseMode : Bool
    @Binding var projectPairing : [ProjectPairingItem]
    var patternWAndYBrowsingFor : WeightAndYardage?
    var isNewYarn : Bool
    var isPopover : Bool
    
    init(
        yarn: Yarn,
        selectedTab : Binding<YarnTab> = .constant(YarnTab.active),
        browseMode: Binding<Bool> = .constant(false),
        projectPairing : Binding<[ProjectPairingItem]> = .constant([]),
        patternWAndYBrowsingFor : WeightAndYardage? = nil,
        isNewYarn : Bool = false,
        isPopover : Bool = false
    ) {
        self.yarn = yarn
        self._selectedTab = selectedTab
        self._browseMode = browseMode
        self._projectPairing = projectPairing
        self.patternWAndYBrowsingFor = patternWAndYBrowsingFor
        self.isNewYarn = isNewYarn
        self.isPopover = isPopover
        self._projects = FetchRequest(
            entity: Project.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Project.startDate, ascending: true)],
            predicate: NSPredicate(format: "ANY pairings.yarnWeightAndYardage.yarn == %@", yarn)
        )
    }
    
    // Internal state trackers
    @State private var showEditYarnForm        : Bool = false
    @State private var showCopyYarnForm        : Bool = false
    @State private var copiedYarn              : Yarn? = nil
    @State private var yarnInfoToast           : Toast? = nil
    @State private var showDeleteConfirmation  : Bool = false
    @State private var showChoosePatternDialog : Bool = false
    @State private var showChooseSkeinDialog   : Bool = false
    @State private var showAddProjectForm      : Bool = false
    @State private var animateCheckmark        : Bool = false
    @State private var patternSuggestions      : [PatternSuggestion] = []
    @State private var favoritedPatterns       : [FavoritePairing] = []
    @State private var patternWAndYForProject  : WeightAndYardage? = nil
    @State private var newProject              : Project? = nil
    @State private var displayedProject        : Project? = nil
    
    @FetchRequest private var projects: FetchedResults<Project>
    
    var yarnProperties: [DetailProp] {
        var props : [DetailProp] = []
        
        if yarn.isArchived {
            props.append(DetailProp(text: "Archived", icon: "tray.and.arrow.down"))
        }
        
        if yarn.isCaked {
            props.append(DetailProp(text: "Caked", icon: "birthday.cake"))
        }
        
        if yarn.isSockSet {
            props.append(DetailProp(text: "Sock Set", icon: "shoeprints.fill"))
        }
        
        if yarn.isMini {
            props.append(DetailProp(text: "Mini", icon: "arrow.down.right.and.arrow.up.left"))
        }
        
        if yarn.colorType == ColorType.variegated.rawValue {
            props.append(DetailProp(text: "Variegated", icon: "swirl.circle.righthalf.filled"))
        } else if yarn.colorType == ColorType.tonal.rawValue {
            props.append(DetailProp(text: "Tonal", icon: "circle.fill"))
        }
                         
        props.append(DetailProp(text: "\(projects.count == 1 ? "1 project" : "\(projects.count) projects")", icon: "hammer"))
                      
        return props
    }
    
    var body: some View {
        if isNewYarn || isPopover {
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
        browseMode || !projectPairing.isEmpty || (!isNewYarn && !isPopover)
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
            Button("Select", action: selectYarn)
                .disabled(yarn.weightAndYardageArray.isEmpty)
        } else if !projectPairing.isEmpty {
            ProgressView()
        } else {
            moreMenu
        }
    }
    
    private func selectYarn() {
        if yarn.weightAndYardageArray.count > 1 {
            showChooseSkeinDialog = true
        } else if let skein = yarn.weightAndYardageArray.first,
                  let patternWAndY = patternWAndYBrowsingFor {
            projectPairing.append(
                ProjectPairingItem(
                    patternWeightAndYardage: patternWAndY,
                    yarnWeightAndYardage: skein
                )
            )
            browseMode = false
        }
    }
    
    private var moreMenu: some View {
        Menu {
            Button {
                showEditYarnForm = true
            } label : {
                Label("Edit", systemImage : "pencil")
            }
            
            if !favoritedPatterns.isEmpty {
                Button {
                    if favoritedPatterns.count > 1 {
                        showChoosePatternDialog = true
                    } else {
                        showAddProjectForm = true
                    }
                } label : {
                    Label("Start a Project", systemImage : "hammer")
                }
            }
            
            Button {
                YarnUtils.shared.toggleYarnArchived(at: yarn)
                
                selectedTab = selectedTab == YarnTab.active ? YarnTab.archived : YarnTab.active
            } label: {
                Label(yarn.isArchived ? "Unarchive" : "Archive", systemImage : yarn.isArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
            }
            
            Button {
                showCopyYarnForm = true
            } label: {
                Label("Copy", systemImage : "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage : "trash")
            }
        } label: {
            Label("More", systemImage : "ellipsis.circle")
        }
    }
    
    private var content: some View {
        scrollContent
            .navigationTitle(yarn.name ?? "N/A")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Are you sure you want to delete this yarn?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    YarnUtils.shared.removeYarn(at: yarn, with: managedObjectContext)
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditYarnForm, onDismiss: getSuggestions) {
                AddOrEditYarnForm(yarnToEdit : yarn)
            }
            .fullScreenCover(isPresented: $showCopyYarnForm, onDismiss: { copiedYarn = nil }) {
                copyYarnCover
            }
            .sheet(isPresented: $showAddProjectForm) {
                addProjectSheet
            }
            .sheet(item: $newProject) { project in
                ProjectInfo(project: project, isNewProject : true, isPopover: true)
            }
            .sheet(item: $displayedProject) { project in
                ProjectInfo(project: project, isPopover: true)
            }
            .modifier(dialogs)
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                getSuggestions()
            }
    }
    
    private var scrollContent: some View {
        ScrollView {
            successHeader
            
            ConditionalStack() {
                ImageCarousel(images : .constant(yarn.uiImages))
                
                LazyVStack {
                    titleSection
                    
                    InfoCapsules(detailProps: yarnProperties)
                    
                    VStack {
                        weightCard
                        skeinSections
                        compositionSection
                        projectsSection
                        colorSection
                        notesSection
                    }
                }
            }
            .foregroundStyle(Color.primary)
            .padding()
        }
        .toastView(toast: $yarnInfoToast)
        .scrollBounceBehavior(.basedOnSize)
    }
    
    @ViewBuilder
    private var successHeader: some View {
        if isNewYarn {
            VStack {
                Label("", systemImage: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.green)
                    .symbolEffect(.bounce, value: animateCheckmark)
                    .padding()
                    .accessibilityHidden(true)
                
                Text("Successfully created yarn")
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
            Text(yarn.name ?? "N/A").bold().font(.largeTitle).foregroundStyle(Color.primary).multilineTextAlignment(.center)
            
            Text(yarn.dyer ?? "N/A").bold().foregroundStyle(Color(UIColor.secondaryLabel))
        }
    }
    
    private var weightCard: some View {
        InfoCard() {
            HStack {
                Text("Weight").foregroundStyle(Color(UIColor.secondaryLabel))
                Spacer()
                Text(yarn.weightAndYardageItems.first?.weight.rawValue ?? "N/A")
                    .font(.headline).bold().foregroundStyle(Color.primary)
            }
        }
    }
    
    private var skeinSections: some View {
        ForEach(yarn.weightAndYardageArray, id: \.id) { wAndY in
            skeinSection(for: wAndY)
        }
    }
    
    @ViewBuilder
    private func skeinSection(for wAndY: WeightAndYardage) -> some View {
        if wAndY.originalLength != wAndY.currentLength {
            originalAmountsCard(for: wAndY)
        }
        
        ViewWeightAndYardage(
            weightAndYardage: wAndY,
            isSockSet: yarn.isSockSet,
            totalCount: yarn.weightAndYardageArray.count
        )
        
        if let suggestion : PatternSuggestion = patternSuggestions.first(where: {$0.yarnWAndY.id == wAndY.id}) {
            PossiblePatterns(
                patternSuggestion : suggestion,
                favoritedPatterns : $favoritedPatterns
            )
        }
    }
    
    private func originalAmountsCard(for wAndY: WeightAndYardage) -> some View {
        InfoCard() {
            VStack {
                HStack {
                    Text("Original Length").foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text("\(wAndY.isExact ? "" : "~")\(wAndY.originalLength.formatted) \(wAndY.unitOfMeasure?.lowercased() ?? "")")
                        .font(.headline).bold().foregroundStyle(Color.primary)
                }
                .yarnDataRow()
                
                Divider()
                
                HStack {
                    Text("Original Skeins").foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text(wAndY.originalSkeins.formatted)
                        .font(.headline).bold().foregroundStyle(Color.primary)
                }
                .yarnDataRow()
            }
        }
    }
    
    @ViewBuilder
    private var compositionSection: some View {
        if !yarn.compositionItems.isEmpty {
            InfoCard(
                header : {
                    HStack {
                        Spacer()
                        Text("Composition")
                        Spacer()
                    }
                }
            ) {
                VStack {
                    CompositionChart(composition: yarn.compositionItems, smallMode: true)
                    CompositionText(composition: yarn.compositionItems)
                }
            }
        }
    }
    
    @ViewBuilder
    private var projectsSection: some View {
        if projects.count > 0 {
            Text("Project\(projects.count > 1 ? "s" : "")")
                .infoCardHeader()
            
            SimpleHorizontalScroll(count: projects.count) {
                ForEach(projects, id : \.id) { project in
                    ProjectPreview(
                        project: project,
                        displayedProject: $displayedProject,
                        yarnId : yarn.id,
                        disableOnTap : isPopover
                    )
                }
            }
        }
    }
    
    private var colorSection: some View {
        InfoCard(noPadding: true) {
            ForEach(yarn.colorPickerItems, id: \.id) { colorPickerItem in
                colorRow(for: colorPickerItem)
            }
        }
    }
    
    private func colorRow(for colorPickerItem: ColorPickerItem) -> some View {
        let colorName = colorPickerItem.description != "" ? colorPickerItem.description : colorPickerItem.name
        
        return VStack {
            colorPickerItem.color
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .frame(height: 35)
                .clipShape(
                    .rect(
                        topLeadingRadius: 10,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 10
                    )
                )
            
            HStack {
                Text("Color").foregroundStyle(Color(UIColor.secondaryLabel))
                Spacer()
                Text(colorName).font(.headline).bold().foregroundStyle(Color.primary)
            }
            .padding(.horizontal, 15)
            .padding(.top, 8)
            .padding(.bottom, 15)
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        if let notes = yarn.notes, notes != "" {
            InfoCard() {
                Text(notes)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // Swap to the success screen in place so this page never flashes between the two
    @ViewBuilder
    private var copyYarnCover: some View {
        if let copiedYarn {
            YarnInfo(
                yarn: copiedYarn,
                selectedTab: $selectedTab,
                isNewYarn: true,
                isPopover: true
            )
            .transition(.opacity)
        } else {
            AddOrEditYarnForm(yarnToEdit: yarn, isCopy: true) { addedYarn in
                // Copies are always active — switch tabs so the new yarn is visible in the list
                if selectedTab == .archived {
                    selectedTab = .active
                }
                withAnimation {
                    copiedYarn = addedYarn
                }
            }
        }
    }
    
    @ViewBuilder
    private var addProjectSheet: some View {
        if let firstFavorite = favoritedPatterns.first?.patternWeightAndYardage {
            let patternWandY : WeightAndYardage = patternWAndYForProject ?? firstFavorite
            
            if let yarnWandY = favoritedPatterns.first(where: { $0.patternWeightAndYardage == patternWandY })?.yarnWeightAndYardage,
               let pattern = patternWandY.pattern {
                AddOrEditProjectForm(
                    projectToEdit: nil,
                    preSelectedPattern: pattern,
                    preSelectedPairings : [ProjectPairingItem(patternWeightAndYardage: patternWandY, yarnWeightAndYardage: yarnWandY)]
                ) { addedProject in
                    // Capture the newly added project
                    newProject = addedProject
                    showAddProjectForm = false
                }
            }
        }
    }
    
    private var dialogs: YarnInfoDialogs {
        YarnInfoDialogs(
            yarn: yarn,
            favoritedPatterns: favoritedPatterns,
            patternWAndYBrowsingFor: patternWAndYBrowsingFor,
            showChoosePatternDialog: $showChoosePatternDialog,
            showChooseSkeinDialog: $showChooseSkeinDialog,
            patternWAndYForProject: $patternWAndYForProject,
            showAddProjectForm: $showAddProjectForm,
            projectPairing: $projectPairing,
            browseMode: $browseMode
        )
    }
    
    func getSuggestions() {
        // viewContext is main-queue bound; perform keeps the fetches on its queue without blocking appear
        managedObjectContext.perform {
            var temp : [PatternSuggestion] = []
            
            for wAndY in yarn.weightAndYardageItems {
                temp.append(
                    PatternSuggestion(
                        yarnWAndY: wAndY.existingItem!,
                        suggestedWAndY: YarnUtils.shared.getMatchingPatterns(for: wAndY, in: managedObjectContext)
                    )
                )
            }
            
            self.patternSuggestions = temp
            self.favoritedPatterns = YarnUtils.shared.favoritedPatterns(for: yarn, in: managedObjectContext)
        }
    }
}

struct YarnDataRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 5)
    }
}



struct YarnInfoDialogs: ViewModifier {
    var yarn : Yarn
    var favoritedPatterns : [FavoritePairing]
    var patternWAndYBrowsingFor : WeightAndYardage?
    @Binding var showChoosePatternDialog : Bool
    @Binding var showChooseSkeinDialog : Bool
    @Binding var patternWAndYForProject : WeightAndYardage?
    @Binding var showAddProjectForm : Bool
    @Binding var projectPairing : [ProjectPairingItem]
    @Binding var browseMode : Bool
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("", isPresented: $showChoosePatternDialog) {
                ForEach(favoritedPatterns, id: \.id) { element in
                    if let wAndY = element.patternWeightAndYardage {
                        Button(patternLabel(for: wAndY)) {
                            patternWAndYForProject = wAndY
                            showAddProjectForm = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You've favorited multiple patterns. Which pattern would you like to use this yarn for?")
            }
            .confirmationDialog("", isPresented: $showChooseSkeinDialog) {
                ForEach(yarn.weightAndYardageArray, id: \.id) { element in
                    Button(skeinLabel(for: element)) {
                        if let patternWAndY = patternWAndYBrowsingFor {
                            projectPairing.append(
                                ProjectPairingItem(
                                    patternWeightAndYardage: patternWAndY,
                                    yarnWeightAndYardage: element
                                )
                            )
                        }
                        
                        browseMode = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This yarn has multiple skeins. Which one would you like to use for the project?")
            }
    }
    
    private func patternLabel(for wAndY: WeightAndYardage) -> String {
        let name = wAndY.pattern?.name ?? "Pattern"
        
        guard let pattern = wAndY.pattern, pattern.weightAndYardageArray.count > 1 else {
            return name
        }
        
        return "\(name) (Color \(PatternUtils.shared.getLetter(for: Int(wAndY.order))))"
    }
    
    private func skeinLabel(for wAndY: WeightAndYardage) -> String {
        switch wAndY.order {
        case 0: return "Main Skein"
        case 1: return "Mini Skein"
        default: return "Mini #2"
        }
    }
}
