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

struct DetailProp : Hashable, Identifiable {
    /// Stable across redraws so capsule layouts don't reshuffle
    var id : String { "\(icon)|\(text)" }
    
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
    /// When set, deleting closes this page and hands the deletion back so the list can animate it
    var onDelete : (() -> Void)?
    
    init(
        yarn: Yarn,
        selectedTab : Binding<YarnTab> = .constant(YarnTab.active),
        browseMode: Binding<Bool> = .constant(false),
        projectPairing : Binding<[ProjectPairingItem]> = .constant([]),
        patternWAndYBrowsingFor : WeightAndYardage? = nil,
        isNewYarn : Bool = false,
        isPopover : Bool = false,
        onDelete : (() -> Void)? = nil
    ) {
        self.onDelete = onDelete
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
    @State private var showPhotoViewer         : Bool = false
    @State private var photoPage               : Int = 0
    @State private var showSummaryExport       : Bool = false
    
    @FetchRequest private var projects: FetchedResults<Project>
    
    /// Status flags only — project usage lives in its own section
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
                      
        return props
    }
    
    private var heroSubtitle: String {
        [yarn.dyer, yarn.primaryWeightLabel]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
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
            projectPairing.removeAll { $0.patternWeightAndYardage.id == patternWAndY.id }
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
            
            Button {
                showSummaryExport = true
            } label: {
                Label("Export Summary", systemImage: "square.and.arrow.up")
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
            .navigationTitle(yarn.name ?? "Yarn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Are you sure you want to delete this yarn?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let onDelete {
                        dismiss()
                        onDelete()
                    } else {
                        YarnUtils.shared.removeYarn(at: yarn, with: managedObjectContext)
                        
                        dismiss()
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditYarnForm, onDismiss: getSuggestions) {
                AddOrEditYarnForm(yarnToEdit : yarn)
            }
            .fullScreenCover(isPresented: $showCopyYarnForm, onDismiss: { copiedYarn = nil }) {
                copyYarnCover
            }
            .sheet(isPresented: $showAddProjectForm, onDismiss: { newProject = nil }) {
                // Swap to the success screen in place so this page never flashes between the two
                if let newProject {
                    ProjectInfo(project: newProject, isNewProject : true, isPopover: true)
                        .transition(.opacity)
                } else {
                    addProjectSheet
                }
            }
            .sheet(item: $displayedProject) { project in
                ProjectInfo(project: project, isPopover: true)
            }
            .modifier(dialogs)
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showSummaryExport) {
                SummaryExportPreview(subject: .yarn(yarn))
            }
            .onAppear {
                getSuggestions()
            }
    }
    
    private var scrollContent: some View {
        ScrollView {
            successHeader
            
            VStack(spacing: 0) {
                if yarn.hasImages {
                    photoCard
                }
                
                VStack(spacing: 0) {
                    hero
                    
                    amountSections
                    compositionSection
                    projectsSection
                    notesSection
                    RecordDates(added: yarn.dateAdded, updated: yarn.dateUpdated)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom)
                .padding(.top, yarn.hasImages ? 8 : 12)
            }
            .foregroundStyle(Color.primary)
        }
        .toastView(toast: $yarnInfoToast)
        .scrollBounceBehavior(.basedOnSize)
        .fullScreenCover(isPresented: $showPhotoViewer) {
            PhotoViewer(images: yarn.uiImages.map(\.image), startIndex: photoPage)
        }
    }
    
    /// Rounded photo card over a wash of the yarn's colors
    @ViewBuilder
    private var photoCard: some View {
        let count = yarn.images?.count ?? 0
        let colors = Array(yarn.sortedYarnColors.prefix(5))
        let wash = colors.isEmpty
            ? [Color(UIColor.tertiarySystemFill), Color(UIColor.secondarySystemFill)]
            : (colors.count == 1 ? [colors[0], colors[0].opacity(0.55)] : colors)
        
        ZStack {
            LinearGradient(colors: wash, startPoint: .topLeading, endPoint: .bottomTrailing)
            
            StoredPhotoPager(images: yarn.images, maxPixelSize: 1600, page: $photoPage) {
                Color(UIColor.tertiarySystemFill)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .bottom) {
                if count > 1 {
                    ScrollDots(
                        currentIndex: photoPage,
                        numberOfDots: count,
                        size: .small,
                        hasBottomPadding: true
                    )
                    .allowsHitTesting(false)
                }
            }
            .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .onTapGesture {
                showPhotoViewer = true
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(count > 1 ? "Yarn photos, \(photoPage + 1) of \(count)" : "Yarn photo")
            .accessibilityHint(count > 1 ? "Swipe to browse photos. Double tap to open full screen." : "Opens the photo full screen")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                showPhotoViewer = true
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var successHeader: some View {
        if isNewYarn {
            VStack(spacing: 6) {
                Label("", systemImage: "checkmark.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.green)
                    .symbolEffect(.bounce, value: animateCheckmark)
                    .padding(.bottom, 4)
                    .accessibilityHidden(true)
                
                Text("Yarn added")
                    .font(.title2.bold())
                
                Text("Now get crafting!")
                    .foregroundStyle(Color.secondary)
                    .font(.subheadline)
            }
            .padding(.bottom, 8)
            .padding(.horizontal)
            .onAppear {
                animateCheckmark.toggle()
            }
        }
    }
    
    /// Compact title block — dyer/weight, then status + color capsules together
    private var hero: some View {
        let colors = yarn.colorPickerItems.sorted { $0.name < $1.name }
        let hasChips = !yarnProperties.isEmpty || !colors.isEmpty
        
        return VStack(alignment: .leading, spacing: 6) {
            Text(yarn.name ?? "Untitled")
                .font(.title.bold())
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            
            if !heroSubtitle.isEmpty {
                Text(heroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
            }
            
            if hasChips {
                HeroChipFlow(spacing: 6) {
                    ForEach(yarnProperties) { prop in
                        Label(prop.text, systemImage: prop.icon)
                            .infoCapsule(isSmall: true)
                    }
                    
                    ForEach(colors, id: \.id) { item in
                        colorCapsule(item)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.bottom, 4)
    }
    
    private func colorCapsuleLabel(_ item: ColorPickerItem) -> String {
        !item.description.isEmpty && item.description != item.name ? item.description : item.name
    }
    
    private func colorCapsule(_ item: ColorPickerItem) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
            
            Text(colorCapsuleLabel(item))
        }
        .infoCapsule(isSmall: true)
        .accessibilityLabel(colorCapsuleLabel(item))
    }
    
    @ViewBuilder
    private var amountSections: some View {
        if yarn.isSockSet {
            sockSetAmountSections
        } else {
            regularAmountSections
        }
    }
    
    /// Sock sets keep one "Skeins" block with a shared weight card, then each skein named underneath
    @ViewBuilder
    private var sockSetAmountSections: some View {
        let skeins = yarn.weightAndYardageArray
        
        if !skeins.isEmpty {
            Text("Skeins")
                .infoCardHeader()
            
            weightCard
            
            ForEach(skeins, id: \.objectID) { wAndY in
                skeinCards(for: wAndY)
                
                if let suggestion = patternSuggestions.first(where: { $0.yarnWAndY.id == wAndY.id }) {
                    PossiblePatterns(
                        patternSuggestion: suggestion,
                        favoritedPatterns: $favoritedPatterns
                    )
                }
            }
        }
    }
    
    /// Regular yarn splits weight, amount, original, and possible patterns into their own sections
    @ViewBuilder
    private var regularAmountSections: some View {
        let skeins = yarn.weightAndYardageArray
        let hasWeight = yarn.weightAndYardageItems.first.map { $0.weight != .none } ?? false
        let originals = skeins.filter { $0.originalLength != $0.currentLength }
        
        if hasWeight {
            Text("Weight")
                .infoCardHeader()
            
            weightCard
        }
        
        if !skeins.isEmpty {
            Text("Amount")
                .infoCardHeader()
            
            ForEach(skeins, id: \.objectID) { wAndY in
                ViewWeightAndYardage(
                    weightAndYardage: wAndY,
                    isSockSet: false,
                    totalCount: skeins.count
                )
            }
        }
        
        if !originals.isEmpty {
            Text(originals.count == 1 ? "Original Amount" : "Original Amounts")
                .infoCardHeader()
            
            ForEach(originals, id: \.objectID) { wAndY in
                originalAmountsCard(for: wAndY)
            }
        }
        
        ForEach(skeins, id: \.objectID) { wAndY in
            if let suggestion = patternSuggestions.first(where: { $0.yarnWAndY.id == wAndY.id }) {
                PossiblePatterns(
                    patternSuggestion: suggestion,
                    favoritedPatterns: $favoritedPatterns
                )
            }
        }
    }
    
    @ViewBuilder
    private var weightCard: some View {
        if let weight = yarn.weightAndYardageItems.first?.weight, weight != .none {
            InfoCard() {
                HStack {
                    Text("Weight")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text(weight.rawValue)
                        .font(.headline.bold())
                        .foregroundStyle(Color.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func skeinCards(for wAndY: WeightAndYardage) -> some View {
        if wAndY.originalLength != wAndY.currentLength {
            originalAmountsCard(for: wAndY)
        }
        
        ViewWeightAndYardage(
            weightAndYardage: wAndY,
            isSockSet: yarn.isSockSet,
            totalCount: yarn.weightAndYardageArray.count
        )
    }
    
    private func originalAmountsCard(for wAndY: WeightAndYardage) -> some View {
        InfoCard() {
            VStack {
                HStack {
                    Text("Original Length")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text("\(wAndY.isExact ? "" : "~")\(wAndY.originalLength.formatted) \(wAndY.unitOfMeasure?.lowercased() ?? "")")
                        .font(.headline.bold())
                        .foregroundStyle(Color.primary)
                }
                .yarnDataRow()
                
                Divider()
                
                HStack {
                    Text("Original Skeins")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text(wAndY.originalSkeins.formatted)
                        .font(.headline.bold())
                        .foregroundStyle(Color.primary)
                }
                .yarnDataRow()
            }
        }
    }
    
    @ViewBuilder
    private var compositionSection: some View {
        if !yarn.compositionItems.isEmpty {
            Text("Composition")
                .infoCardHeader()
            
            InfoCard() {
                VStack(spacing: 10) {
                    CompositionChart(
                        composition: yarn.compositionItems,
                        yarnColors: yarn.colorPickerItems.map(\.color),
                        smallMode: true
                    )
                    CompositionText(composition: yarn.compositionItems)
                }
            }
        }
    }
    
    @ViewBuilder
    private var projectsSection: some View {
        let listed = Array(projects).sortedForDisplay
        
        if !listed.isEmpty {
            Text(listed.count == 1 ? "Project" : "Projects")
                .infoCardHeader()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(listed, id: \.objectID) { project in
                        let compact = listed.count == 1 && !project.hasImages
                        
                        ProjectPreview(
                            project: project,
                            displayedProject: $displayedProject,
                            yarnId: yarn.id,
                            disableOnTap: isPopover,
                            compact: compact
                        )
                        .containerRelativeFrame(.horizontal) { length, _ in
                            compact || listed.count == 1 ? length : length * 0.62
                        }
                    }
                }
            }
            .scrollClipDisabled(false)
            .scrollDisabled(listed.count <= 1)
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        if let notes = yarn.notes, !notes.isEmpty {
            Text("Notes")
                .infoCardHeader()
            
            InfoCard() {
                Text(notes)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                    withAnimation {
                        newProject = addedProject
                    }
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

/// Wraps status and color capsules onto as many leading-aligned rows as needed
private struct HeroChipFlow: Layout {
    var spacing : CGFloat = 6
    
    private struct Row {
        var indices : [Int] = []
        var width : CGFloat = 0
        var height : CGFloat = 0
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        
        for row in rows(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            
            for index in row.indices {
                let size = fittedSize(of: subviews[index], maxWidth: bounds.width)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + spacing
            }
            
            y += row.height + spacing
        }
    }
    
    private func fittedSize(of subview: LayoutSubview, maxWidth: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard ideal.width > maxWidth else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
    }
    
    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows : [Row] = []
        var current = Row()
        
        for index in subviews.indices {
            let size = fittedSize(of: subviews[index], maxWidth: maxWidth)
            
            if !current.indices.isEmpty && current.width + spacing + size.width > maxWidth {
                rows.append(current)
                current = Row()
            }
            
            current.width += (current.indices.isEmpty ? 0 : spacing) + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        
        if !current.indices.isEmpty {
            rows.append(current)
        }
        
        return rows
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
                            projectPairing.removeAll { $0.patternWeightAndYardage.id == patternWAndY.id }
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
