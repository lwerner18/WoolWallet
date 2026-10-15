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
            .onAppear {
                getSuggestions()
            }
    }
    
    private var scrollContent: some View {
        ScrollView {
            successHeader
            
            ConditionalStack() {
                ImageCarousel(images : .constant(yarn.uiImages), allowsZoom: true)
                
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
                        RecordDates(added: yarn.dateAdded, updated: yarn.dateUpdated)
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
                    CompositionChart(composition: yarn.compositionItems, yarnColors: yarn.colorPickerItems.map(\.color), smallMode: true)
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
    
    @ViewBuilder
    private var colorSection: some View {
        let colors = yarn.colorPickerItems
        
        if !colors.isEmpty {
            InfoCard(
                header : {
                    HStack {
                        Spacer()
                        Text(colors.count == 1 ? "Color" : "Colors")
                        Spacer()
                    }
                }
            ) {
                ColorPalette(colors: colors, blends: yarn.colorType == ColorType.variegated.rawValue)
            }
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

/// A strip of the yarn's colors over named swatches
private struct ColorPalette: View {
    let colors : [ColorPickerItem]
    /// Variegated yarn shifts from one color into the next, so its strip blends instead of breaking into blocks
    var blends : Bool
    
    /// Saved colors have no order, so sort by hue for a palette that reads naturally and stays put;
    /// grays and near-blacks have no meaningful hue and go last, light to dark
    private var sortedColors : [ColorPickerItem] {
        colors.sorted { first, second in
            let a = HueKey(first.color), b = HueKey(second.color)
            if a.isNeutral != b.isNeutral { return !a.isNeutral }
            if a.isNeutral { return a.brightness > b.brightness }
            return a.hue < b.hue
        }
    }
    
    var body: some View {
        let colors = sortedColors
        
        if let only = colors.first, colors.count == 1 {
            swatch(only)
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 14) {
                strip(colors.map(\.color))
                    .frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .accessibilityHidden(true)
                
                // Centered rows look intended whatever the count, where a grid strands an odd one out
                CenteredFlowLayout(spacing: 8) {
                    ForEach(colors, id: \.id) { item in
                        pill(item)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func strip(_ colors: [Color]) -> some View {
        if blends && colors.count > 1 {
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        } else {
            HStack(spacing: 0) {
                ForEach(colors.indices, id: \.self) { index in
                    colors[index]
                }
            }
        }
    }
    
    private func hasCustomName(_ item: ColorPickerItem) -> Bool {
        !item.description.isEmpty && item.description != item.name
    }
    
    /// The only color, shown large
    private func swatch(_ item: ColorPickerItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.color)
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(hasCustomName(item) ? item.description : item.name)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                if hasCustomName(item) {
                    Text(item.name)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private func pill(_ item: ColorPickerItem) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(item.color)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
            
            Text(hasCustomName(item) ? item.description : item.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.primary)
            
            if hasCustomName(item) {
                Text(item.name)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .lineLimit(1)
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemFill), in: Capsule())
        .accessibilityElement(children: .combine)
    }
    
    private struct HueKey {
        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        
        var isNeutral : Bool { saturation < 0.12 || brightness < 0.12 }
        
        init(_ color: Color) {
            UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        }
    }
}

/// Wraps its views onto as many rows as they need, each row centered
private struct CenteredFlowLayout: Layout {
    var spacing : CGFloat = 8
    
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
            var x = bounds.minX + (bounds.width - row.width) / 2
            
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
    
    /// Anything wider than a whole row is narrowed to fit, truncating its text
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
