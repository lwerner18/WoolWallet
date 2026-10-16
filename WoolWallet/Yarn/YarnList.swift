//
//  YarnList.swift
//  WoolWallet
//
//  Created by Mac on 3/11/24.
//

import Foundation
import SwiftUI
import CoreData

struct TabCount<T: CaseIterable & Identifiable & Equatable & CustomStringConvertible> {
    var tab : T
    var count : Int
}

struct YarnList: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var browseMode : Bool
    var preSelectedWeightFilter : [Weight]
    @Binding var projectPairing : [ProjectPairingItem]
    var patternWAndYBrowsingFor : WeightAndYardage?
    
    init(
        browseMode: Binding<Bool> = .constant(false),
        preSelectedWeightFilter : [Weight] = [],
        projectPairing : Binding<[ProjectPairingItem]> = .constant([]),
        patternWAndYBrowsingFor : WeightAndYardage? = nil
    ) {
        self._browseMode = browseMode
        self.preSelectedWeightFilter = preSelectedWeightFilter
        self._projectPairing = projectPairing
        self.patternWAndYBrowsingFor = patternWAndYBrowsingFor
        
        _selectedWeights = State(initialValue: preSelectedWeightFilter)
    }
    
    // Add view model
    @StateObject private var viewModel = YarnListViewModel()
    // -- you may want a debounce helper for search:
    @State private var searchDebounceWorkItem: DispatchWorkItem?
    
    // Internal state trackers
    @State var searchText                     : String = ""
    @State private var showAddYarnForm        : Bool = false
    @State private var showStashCheck         : Bool = false
    /// Added from a stash check, shown once the scanner has closed
    @State private var yarnAddedFromCheck     : Yarn? = nil
    @State private var showFilterScreen       : Bool = false
    @State private var showNewYarnDetail      : Bool = false
    @State private var newYarn                : Yarn? = nil
    @State private var toast                  : Toast? = nil
    /// Shown once the add form has closed, so it isn't hidden behind it
    @State private var toastAfterAdding       : Toast? = nil
    @State private var selectedColors         : [NamedColor] = []
    @State private var selectedWeights        : [Weight] = []
    @State private var selectedTab            : YarnTab = YarnTab.active
    @State private var sockSet                : Int = -1
    @State private var colorType              : ColorType? = nil
    @State private var showConfirmationDialog : Bool = false
    @State private var yarnToEdit             : Yarn? = nil
    @State private var yarnToDelete           : Yarn? = nil
    /// Browse mode: yarn with multiple skeins waiting for the user to pick one
    @State private var yarnPendingSkeinPick   : Yarn? = nil
    @State private var tabsFrame              : CGRect = .zero
    @State private var cellFrames             = CellFrameStore()
    @State private var archiveGhost           : ArchiveGhost? = nil
    @State private var archiveLanded          : Bool = false
    @State private var deletingYarnID         : NSManagedObjectID? = nil
    @State private var yarnDeleted            : Bool = false
    @AppStorage("yarnListSort") private var sort : YarnSort = .name
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
//    @FetchRequest(
//        fetchRequest: Yarn.fetchPartialRequest()
//    ) private var allYarns: FetchedResults<Yarn>
    
    
    private var uniqueDyers: [String] {
        // Extract dyers and remove duplicates
        let dyers = Set(viewModel.yarns.compactMap { $0.dyer })
        return Array(dyers).sorted() // Optional: Sort the list of dyers
    }
    
    private var tabCounts: [TabCount<YarnTab>] {
        return [
            TabCount(tab: YarnTab.active, count: viewModel.activeCount),
            TabCount(tab: YarnTab.archived, count: viewModel.archivedCount),
        ]
    }
    
    var showFilterCapsules : Bool {
        return !selectedColors.isEmpty || searchText != "" || !selectedWeights.isEmpty || sockSet != -1 || colorType != nil
    }
    
    var filteredSuggestions: [String] {
        guard !searchText.isEmpty else { return [] }
        // Leave out an exact match so the list closes once a suggestion is picked
        return uniqueDyers.filter {
            $0.lowercased().contains(searchText.lowercased()) && $0.caseInsensitiveCompare(searchText) != .orderedSame
        }
    }
    
//    private var filteredFetchRequest = FetchRequest<Yarn>(
//        sortDescriptors: [SortDescriptor(\.name)],
//        predicate: NSPredicate(value: true)
//    )
    
//    // Computed property to get all the yarn with an optional searchText
//    private var filteredYarn: FetchedResults<Yarn> {
//        // Apply sorting
//        filteredFetchRequest.wrappedValue.nsSortDescriptors = [
//            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare))
//        ]
//        
//        var predicates: [NSPredicate] = []
//        if searchText != "" {
//            var searchPredicate = [NSPredicate(format: "name CONTAINS[c] %@", searchText)]
//            searchPredicate.append(NSPredicate(format: "dyer CONTAINS[c] %@", searchText))
//            
//            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicate)
//            predicates.append(compoundPredicate)
//        }
//        
//        // Apply predicate for color filter
//        if !selectedColors.isEmpty {
//            let colorPredicates = selectedColors.map { color in
//                NSPredicate(format: "ANY colors.name = %@", color.name)
//            }
//            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: colorPredicates)
//            predicates.append(compoundPredicate)
//        }
//        
//        // Apply predicate for weight filter
//        if !selectedWeights.isEmpty {
//            let weightPredicates = selectedWeights.map { weight in
//                NSPredicate(format: "ANY weightAndYardages.weight = %@", weight.rawValue)
//            }
//            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: weightPredicates)
//            predicates.append(compoundPredicate)
//        }
//        
//        // Apply predicate for sock set
//        if sockSet != -1 {
//            // sock sets only
//            if sockSet == 1 {
//                predicates.append(NSPredicate(format: "isSockSet = %@", true as NSNumber))
//            } else {
//                // no sock sets
//                let noSockSetsPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
//                    NSPredicate(format: "isSockSet == %@", NSNumber(value: false)),
//                    NSPredicate(format: "isSockSet == nil")
//                ])
//                predicates.append(noSockSetsPredicate)
//            }
//        }
//        
//        if colorType != nil {
//            predicates.append(NSPredicate(format: "colorType = %@", colorType!.rawValue))
//        }
//        
//        switch(selectedTab) {
//        case .active:
//            let activePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
//                NSPredicate(format: "isArchived == %@", NSNumber(value: false)),
//                NSPredicate(format: "isArchived == nil")
//            ])
//            predicates.append(activePredicate)
//        case .archived:
//            predicates.append(NSPredicate(format: "isArchived = %@", true as NSNumber))
//        }
//        
//        filteredFetchRequest.wrappedValue.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
//        
//        return filteredFetchRequest.wrappedValue
//    }
    
    var body: some View {
        NavigationStack {
            if !browseMode {
                Tabs(selectedTab: $selectedTab, tabCounts: tabCounts) { tabsFrame = $0 }
            }
            
            HStack {
                if showFilterCapsules {
                    YarnFilterCapsules(
                        showFilterScreen: $showFilterScreen,
                        selectedColors: $selectedColors,
                        selectedWeights: $selectedWeights,
                        sockSet: $sockSet,
                        colorType: $colorType
                    )
                }
                
            }
            
            VStack {
                if viewModel.yarns.isEmpty {
                    ScrollView {
                        ZStack {
                            // Reserve space matching the scroll view's frame
                            Spacer().containerRelativeFrame([.horizontal, .vertical])
                            
                            if selectedTab == YarnTab.active {
                                VStack {
                                    Image("angelEyes") // Replace with your image's name
                                        .resizable() // If you want to adjust the size
                                        .scaledToFit() // Adjust the image's aspect ratio
                                        .frame(width: 300, height: 175) // Set desired frame size
                                    
                                    Text("No yarn?")
                                        .font(.title)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                    
                                    VStack {
                                        Text("We couldn't find anything.")
                                            .font(.body)
                                        
                                        HStack(spacing: 0) {
                                            Text("Please")
                                            
                                            Button(action: {
                                                showAddYarnForm = true
                                            }) {
                                                Text(" add some yarn ")
                                                    .foregroundStyle(Color.accentColor)
                                            }
                                            .buttonStyle(PlainButtonStyle()) // Remove default button styling
                                            .padding(0)
                                            
                                            Text("or modify your search.")
                                                .font(.body)
                                        }
                                        
                                    }
                                    .padding(.top, 5)
                                }
                                .padding()
                            } else {
                                VStack {
                                    Image("momo") // Replace with your image's name
                                        .resizable() // If you want to adjust the size
                                        .scaledToFit() // Adjust the image's aspect ratio
                                        .frame(width: 300, height: 125) // Set desired frame size
                                    
                                    Text("Looking for yarn is tough work! Time for a nap.")
                                        .font(.title)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                    
                                    VStack {
                                        Text("We couldn't find anything.")
                                            .font(.body)
                                        
                                        HStack(spacing: 0) {
                                            Text("Please")
                                            
                                            Button(action: {
                                                showAddYarnForm = true
                                            }) {
                                                Text(" add some yarn ")
                                                    .foregroundStyle(Color.accentColor)
                                            }
                                            .buttonStyle(PlainButtonStyle()) // Remove default button styling
                                            .padding(0)
                                            
                                            Text("or modify your search.")
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
                    ScrollView {
                        LazyVGrid(columns: [.init(.adaptive(minimum: UIDevice.current.userInterfaceIdiom == .pad ? 280 : 160), spacing: 12)], spacing: 14) {
                            ForEach(viewModel.yarns, id: \.objectID) { yarn in
                                yarnGridItem(for: yarn) {
                                    YarnGridCell(yarn: yarn) {
                                        if !browseMode {
                                            Button {
                                                yarnToEdit = yarn
                                            } label: {
                                                Label("Edit", systemImage : "pencil")
                                            }
                                            
                                            Button {
                                                toggleArchived(yarn)
                                            } label: {
                                                Label(yarn.isArchived ? "Unarchive" : "Archive", systemImage : yarn.isArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                                            }
                                            
                                            Button(role: .destructive) {
                                                yarnToDelete = yarn
                                                showConfirmationDialog = true
                                            } label: {
                                                Label("Delete", systemImage : "trash")
                                            }
                                        }
                                    }
                                    .background {
                                        GeometryReader { proxy in
                                            let frame = proxy.frame(in: .global)
                                            
                                            Color.clear
                                                .onAppear { cellFrames.frames[yarn.objectID] = frame }
                                                .onChange(of: frame) { _, newFrame in cellFrames.frames[yarn.objectID] = newFrame }
                                        }
                                    }
                                    // The flying copy stands in for this cell while it animates into the other tab
                                    .opacity(archiveGhost?.yarn == yarn ? 0 : 1)
                                    .scaleEffect(deletingYarnID == yarn.objectID ? 0.4 : 1)
                                    .blur(radius: deletingYarnID == yarn.objectID ? 8 : 0)
                                    .opacity(deletingYarnID == yarn.objectID ? 0 : 1)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                }
            }
            .navigationTitle(browseMode ? "Browse Yarn" : "My Stash")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by Name or Dyer...",
                suggestions: {
                    ForEach(filteredSuggestions, id: \.self) { suggestion in
                        // A plain search completion fills the field but leaves the keyboard up
                        Button {
                            searchText = suggestion
                            hideKeyboard()
                        } label: {
                            Text(suggestion)
                                .foregroundStyle(Color.primary)
                                .padding(.leading, 5)
                        }
                    }
                }
            )
            .onChange(of: searchText) {
                if searchText.isEmpty {
                    searchText = ""
                }
            }
            .toolbar {
                if !browseMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showStashCheck = true
                        } label: {
                            Label("Check Stash for a Label", systemImage: "text.viewfinder")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sort) {
                            ForEach(YarnSort.allCases) { option in
                                Label(option.rawValue, systemImage: option.systemImage).tag(option)
                            }
                        }
                    } label: {
                        Label("View Options", systemImage: "arrow.up.arrow.down.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showFilterScreen = true
                    }) {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAddYarnForm = true
                    }) {
                        Label("Add Yarn", systemImage: "plus")
                    }
                }
            }
        }
        .overlay {
            if let archiveGhost {
                ArchiveGhostView(ghost: archiveGhost) { finishedID in
                    if self.archiveGhost?.id == finishedID {
                        self.archiveGhost = nil
                    }
                    archiveLanded.toggle()
                }
                .id(archiveGhost.id)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: archiveLanded)
        .sensoryFeedback(.impact(weight: .medium), trigger: yarnDeleted)
        .onAppear {
            viewModel.start(context: managedObjectContext)
            
            // initial apply of current filters
            applyFilters()
        }
        // apply filters whenever relevant pieces change (no re-evaluation inside body)
        .onChange(of: selectedColors) { applyFilters() }
        .onChange(of: selectedWeights) { applyFilters() }
        .onChange(of: sockSet) { applyFilters() }
        .onChange(of: colorType) { applyFilters() }
        .onChange(of: selectedTab) { applyFilters() }
        .onChange(of: sort) { applyFilters() }
        
        // debounce searchText so we don't re-run fetch on each keystroke
        .onChange(of: searchText) {
            searchDebounceWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak viewModel, searchText, selectedColors, selectedWeights, sockSet, colorType, selectedTab, sort] in
                viewModel?.updateFilters(
                    searchText: searchText,
                    selectedColors: selectedColors,
                    selectedWeights: selectedWeights,
                    sockSet: sockSet,
                    colorType: colorType,
                    selectedTab: selectedTab,
                    sort: sort
                )
            }
            searchDebounceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30, execute: workItem)
        }
        .sheet(isPresented: $showFilterScreen) {
            FilterYarn(
                selectedColors: $selectedColors,
                selectedWeights: $selectedWeights,
                sockSet : $sockSet,
                colorType : $colorType,
                filteredYarnCount: viewModel.yarns.count
            )
        }
        .fullScreenCover(isPresented: $showAddYarnForm, onDismiss: {
            newYarn = nil
            
            if let toastAfterAdding {
                self.toastAfterAdding = nil
                toast = toastAfterAdding
            }
        }) {
            // Swap to the success screen in place so the list never flashes between the two
            if let newYarn {
                YarnInfo(yarn: newYarn, selectedTab : $selectedTab, isNewYarn : true)
                    .transition(.opacity)
            } else {
                AddOrEditYarnForm(yarnToEdit : nil, onAddSkeins: { yarn, count in
                    if browseMode, let skein = yarn.weightAndYardageArray.first {
                        selectSkein(skein)
                    }
                    
                    toastAfterAdding = Toast(
                        style: .success,
                        message: "Added \(AddSkeinsView.amountText(count, isSockSet: yarn.isSockSet)) to \(yarn.name ?? "your yarn")"
                    )
                    showAddYarnForm = false
                }) { addedYarn in
                    if browseMode, let skein = addedYarn.weightAndYardageArray.first {
                        selectSkein(skein)
                        showAddYarnForm = false
                    } else {
                        withAnimation {
                            newYarn = addedYarn
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showStashCheck, onDismiss: {
            if let yarnAddedFromCheck {
                self.yarnAddedFromCheck = nil
                newYarn = yarnAddedFromCheck
                showAddYarnForm = true
            }
        }) {
            StashCheckSheet { addedYarn in
                yarnAddedFromCheck = addedYarn
                showStashCheck = false
            }
        }
        .fullScreenCover(item: $yarnToEdit, onDismiss: { yarnToEdit = nil}) { yarn in
            AddOrEditYarnForm(yarnToEdit : yarn)
        }
        .alert("Are you sure you want to delete this yarn?", isPresented: $showConfirmationDialog) {
            if let yarnToDelete = yarnToDelete {
                Button("Delete", role: .destructive) {
                    // Give the alert a moment to fade so the card is visible as it goes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        deleteYarn(yarnToDelete)
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("", isPresented: Binding(
            get: { yarnPendingSkeinPick != nil },
            set: { if !$0 { yarnPendingSkeinPick = nil } }
        )) {
            if let yarn = yarnPendingSkeinPick {
                ForEach(yarn.weightAndYardageArray, id: \.objectID) { skein in
                    Button(skeinBrowseLabel(for: skein)) {
                        selectSkein(skein)
                        yarnPendingSkeinPick = nil
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {
                yarnPendingSkeinPick = nil
            }
        } message: {
            Text("This yarn has multiple skeins. Which one would you like to use for the project?")
        }
        .onChange(of: projectPairing) { _, pairings in
            // Parent presents this list with navigationDestination(isPresented: browseMode).
            // dismiss() would close the project form; flipping browseMode pops instead.
            if browseMode, !pairings.isEmpty {
                browseMode = false
            }
        }
        .toastView(toast: $toast)
        .scrollBounceBehavior(.basedOnSize)
    }
    
    @ViewBuilder
    private func yarnGridItem<Cell: View>(for yarn: Yarn, @ViewBuilder cell: () -> Cell) -> some View {
        if browseMode {
            Button {
                selectYarnFromBrowse(yarn)
            } label: {
                cell()
            }
            .buttonStyle(.plain)
            .disabled(yarn.weightAndYardageArray.isEmpty)
            .accessibilityHint("Selects this yarn for the project")
        } else {
            NavigationLink(
                destination: YarnInfo(
                    yarn: yarn,
                    selectedTab : $selectedTab,
                    browseMode : $browseMode,
                    projectPairing: $projectPairing,
                    patternWAndYBrowsingFor : patternWAndYBrowsingFor,
                    onDelete: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            deleteYarn(yarn)
                        }
                    }
                )
            ) {
                cell()
            }
            .buttonStyle(.plain)
        }
    }
    
    private func selectYarnFromBrowse(_ yarn: Yarn) {
        guard patternWAndYBrowsingFor != nil, !yarn.weightAndYardageArray.isEmpty else { return }
        
        if yarn.weightAndYardageArray.count > 1 {
            yarnPendingSkeinPick = yarn
        } else if let skein = yarn.weightAndYardageArray.first {
            selectSkein(skein)
        }
    }
    
    private func selectSkein(_ skein: WeightAndYardage) {
        guard let patternWAndY = patternWAndYBrowsingFor else { return }
        
        // Replace any yarn already chosen for this colorway
        projectPairing.removeAll { $0.patternWeightAndYardage.id == patternWAndY.id }
        projectPairing.append(
            ProjectPairingItem(
                patternWeightAndYardage: patternWAndY,
                yarnWeightAndYardage: skein
            )
        )
        browseMode = false
    }
    
    private func skeinBrowseLabel(for wAndY: WeightAndYardage) -> String {
        switch wAndY.order {
        case 0: return wAndY.yarn?.isSockSet == true ? "Main Skein" : "Skein 1"
        case 1: return "Mini Skein"
        case 2: return "Mini #2"
        default: return "Skein \(Int(wAndY.order) + 1)"
        }
    }
    
    private func applyFilters() {
        viewModel.updateFilters(
            searchText: searchText,
            selectedColors: selectedColors,
            selectedWeights: selectedWeights,
            sockSet: sockSet,
            colorType: colorType,
            selectedTab: selectedTab,
            sort: sort
        )
    }
    
    private func deleteYarn(_ yarn: Yarn) {
        guard !yarn.isDeleted else { return }
        
        guard !reduceMotion else {
            withAnimation {
                YarnUtils.shared.removeYarn(at: yarn, with: managedObjectContext)
            }
            return
        }
        
        let shrinkDuration = 0.25
        
        withAnimation(.easeIn(duration: shrinkDuration)) {
            deletingYarnID = yarn.objectID
        } completion: {
            withAnimation(.snappy) {
                YarnUtils.shared.removeYarn(at: yarn, with: managedObjectContext)
            }
            deletingYarnID = nil
            yarnDeleted.toggle()
        }
    }
    
    private func toggleArchived(_ yarn: Yarn) {
        let destination : YarnTab = yarn.isArchived ? .active : .archived
        
        guard !reduceMotion else {
            withAnimation {
                YarnUtils.shared.toggleYarnArchived(at: yarn)
            }
            return
        }
        
        // Wait for the context menu to settle back onto the cell before it flies away
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {            if let start = cellFrames.frames[yarn.objectID],
               let target = Tabs<YarnTab>.segmentCenter(of: destination, in: tabsFrame) {
                archiveGhost = ArchiveGhost(yarn: yarn, start: start, target: target)
            }
            
            withAnimation(.snappy) {
                YarnUtils.shared.toggleYarnArchived(at: yarn)
            }
        }
    }
}

/// A photo-forward stash card: the yarn photo fills the tile, with name and dyer overlaid
struct YarnGridCell<MenuItems: View>: View {
    @ObservedObject var yarn : Yarn
    @ViewBuilder var menuItems: () -> MenuItems
    
    @State private var photoPage : Int = 0
    
    private var colors : [Color] { yarn.sortedYarnColors }
    private var photoCount : Int { yarn.images?.count ?? 0 }
    
    var body: some View {
        Color.clear
            .aspectRatio(0.85, contentMode: .fit)
            .overlay {
                photo
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 88)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(yarn.name ?? "No Name")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            }
            .overlay(alignment: .topTrailing) {
                if photoCount > 1 {
                    PatternCoverBadge(text: "\(photoPage + 1)/\(photoCount)", systemImage: "photo.on.rectangle")
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .contextMenu(menuItems: menuItems)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([yarn.name, yarn.dyer, yarn.primaryWeightLabel].compactMap { $0 }.joined(separator: ", "))
            .accessibilityHint(photoCount > 1 ? "Swipe to view \(photoCount) photos" : "")
    }
    
    private var subtitle: String {
        [yarn.dyer, yarn.primaryWeightLabel].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
    
    @ViewBuilder
    private var photo: some View {
        if yarn.hasImages {
            StoredPhotoPager(images: yarn.images, maxPixelSize: 700, page: $photoPage) {
                colorWash
            }
        } else {
            colorWash
        }
    }
    
    private var colorWash: some View {
        let wash = colors.isEmpty
            ? [Color(UIColor.tertiarySystemFill), Color(UIColor.secondarySystemFill)]
            : (colors.count == 1 ? [colors[0], colors[0].opacity(0.55)] : Array(colors.prefix(4)))
        
        return LinearGradient(colors: wash, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                if colors.isEmpty {
                    Image(systemName: "volleyball")
                        .font(.largeTitle)
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                        .accessibilityHidden(true)
                }
            }
    }
}

extension YarnGridCell where MenuItems == EmptyView {
    init(yarn: Yarn) {
        self.init(yarn: yarn) { EmptyView() }
    }
}

/// Last known global frame of each grid cell, kept outside view state so scrolling doesn't re-render the list
final class CellFrameStore {
    var frames : [NSManagedObjectID: CGRect] = [:]
}

struct ArchiveGhost: Identifiable {
    let id = UUID()
    let yarn : Yarn
    let start : CGRect
    let target : CGPoint
}

/// A copy of a yarn cell that shrinks along an arc into the segment of the tab it is moving to
private struct ArchiveGhostView: View {
    let ghost : ArchiveGhost
    let onFinish : (UUID) -> Void
    
    @State private var movedX = false
    @State private var movedY = false
    @State private var isShrunk = false
    @State private var isFaded = false
    
    private let duration = 0.55
    
    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            
            YarnGridCell(yarn: ghost.yarn)
                .frame(width: ghost.start.width, height: ghost.start.height)
                .scaleEffect(isShrunk ? 0.05 : 1)
                .opacity(isFaded ? 0 : 1)
                .offset(x: movedX ? ghost.target.x - ghost.start.midX : 0)
                .offset(y: movedY ? ghost.target.y - ghost.start.midY : 0)
                .position(x: ghost.start.midX - origin.x, y: ghost.start.midY - origin.y)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            // Different curves per axis bend the path into an arc
            withAnimation(.easeInOut(duration: duration)) {
                movedX = true
                isShrunk = true
            }
            withAnimation(.easeIn(duration: duration)) {
                movedY = true
            } completion: {
                onFinish(ghost.id)
            }
            withAnimation(.easeIn(duration: 0.15).delay(duration - 0.15)) {
                isFaded = true
            }
        }
    }
}

struct YarnFilter : Hashable {
    var color : NamedColor? = nil
    var weight : Weight? = nil
    var sockSet : Int = -1
    var colorType : ColorType? = nil
    var last : Bool = false
}

struct YarnFilterCapsules : View {
    @Binding var showFilterScreen : Bool
    @Binding var selectedColors   : [NamedColor]
    @Binding var selectedWeights  : [Weight]
    @Binding var sockSet          : Int
    @Binding var colorType        : ColorType?
    
    var yarnFilters: [YarnFilter] {
        var filterItems : [YarnFilter] = []
        
        selectedWeights.forEach { weight in
            filterItems.append(YarnFilter(weight : weight))
        }
        
        if sockSet != -1 {
            filterItems.append(YarnFilter(sockSet : sockSet))
        }
        
        if colorType != nil {
            filterItems.append(YarnFilter(colorType : colorType!))
        }
        
        selectedColors.forEach { color in
            filterItems.append(YarnFilter(color : color))
        }
        
        filterItems.append(YarnFilter(last: true))
        
        return filterItems
    }
    
    var body : some View {
        FlexView(data: yarnFilters, spacing: 6) { yarnFilter in
            HStack {
                if yarnFilter.weight != nil {
                    FilterCapsule(
                        text : yarnFilter.weight!.rawValue,
                        showX: true,
                        onClick : {
                            if let index = selectedWeights.firstIndex(where: { $0 == yarnFilter.weight! }) {
                                selectedWeights.remove(at: index)
                            }
                        }
                    )
                } else if yarnFilter.sockSet != -1 {
                    FilterCapsule(
                        text : yarnFilter.sockSet == 1 ? "Sock Sets Only" : "No Sock Sets",
                        showX: true,
                        onClick : { sockSet = -1 }
                    )
                } else if yarnFilter.colorType != nil {
                    FilterCapsule(
                        text : yarnFilter.colorType!.rawValue,
                        showX: true,
                        onClick : { colorType = nil }
                    )
                } else if yarnFilter.color != nil {
                    FilterCapsule(
                        showX: true,
                        onClick : {
                            if let index = selectedColors.firstIndex(where: { $0.id == yarnFilter.color!.id }) {
                                selectedColors.remove(at: index)
                            }
                        }
                    ) {
                        if yarnFilter.color!.name != "Other" {
                            // Diamond-shaped color view
                            Circle()
                                .fill(Color(uiColor : yarnFilter.color!.colors[0]))
                                .frame(width: 13, height: 13)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 0.5) // Black border with width
                                )
                        }
    
                        Text(yarnFilter.color!.name)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                    
                } else if yarnFilter.last {
                    Button(action: {
                        showFilterScreen = true
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                    .padding(.leading, 5)
                }
            }
         
        }
        .padding()
    }
}
