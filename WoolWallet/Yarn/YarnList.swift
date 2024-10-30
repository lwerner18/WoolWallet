//
//  YarnList.swift
//  WoolWallet
//
//  Created by Mac on 3/11/24.
//

import Foundation
import SwiftUI

struct TabCount<T: CaseIterable & Identifiable & Equatable & CustomStringConvertible> {
    var tab : T
    var count : Int
}

struct YarnList: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    
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
    
    // Internal state trackers
    @State var searchText                     : String = ""
    @State private var showAddYarnForm        : Bool = false
    @State private var showFilterScreen       : Bool = false
    @State private var showNewYarnDetail      : Bool = false
    @State private var newYarn                : Yarn? = nil
    @State private var toast                  : Toast? = nil
    @State private var selectedColors         : [NamedColor] = []
    @State private var selectedWeights        : [Weight] = []
    @State private var selectedTab            : YarnTab = YarnTab.active
    @State private var sockSet                : Int = -1
    @State private var colorType              : ColorType? = nil
    @State private var showConfirmationDialog : Bool = false
    @State private var yarnToEdit             : Yarn? = nil
    @State private var yarnToDelete           : Yarn? = nil
    
    @FetchRequest(
        entity: Yarn.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Yarn.name, ascending: true)] // Optional: Sort by name
    ) private var allYarns: FetchedResults<Yarn>
    
    private var uniqueDyers: [String] {
        // Extract dyers and remove duplicates
        let dyers = Set(allYarns.compactMap { $0.dyer })
        return Array(dyers).sorted() // Optional: Sort the list of dyers
    }
    
    private var activeNumber: Int {
        return allYarns.filter {!$0.isArchived}.count
    }
    
    
    private var archivedNumber: Int {
        return allYarns.filter {$0.isArchived}.count
    }
    
    private var tabCounts: [TabCount<YarnTab>] {
        return [
            TabCount(tab: YarnTab.active, count: allYarns.filter {!$0.isArchived}.count),
            TabCount(tab: YarnTab.archived, count: allYarns.filter {$0.isArchived}.count),
        ]
    }
    
    // Computed property for the count of filtered yarns
    private var filteredYarnCount: Int {
        filteredYarn.count
    }
    
    var showFilterCapsules : Bool {
        return !selectedColors.isEmpty || searchText != "" || !selectedWeights.isEmpty || sockSet != -1 || colorType != nil
    }
    
    var filteredSuggestions: [String] {
        guard !searchText.isEmpty else { return [] }
        return uniqueDyers.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    private var filteredFetchRequest = FetchRequest<Yarn>(
        sortDescriptors: [SortDescriptor(\.name)],
        predicate: NSPredicate(value: true),
        animation: .default
    )
    
    // Computed property to get all the yarn with an optional searchText
    private var filteredYarn: FetchedResults<Yarn> {
        
        // Apply sorting
        filteredFetchRequest.wrappedValue.nsSortDescriptors = [NSSortDescriptor(keyPath: \Yarn.name, ascending: true)]
        
        var predicates: [NSPredicate] = []
        if searchText != "" {
            var searchPredicate = [NSPredicate(format: "name CONTAINS[c] %@", searchText)]
            searchPredicate.append(NSPredicate(format: "dyer CONTAINS[c] %@", searchText))
            
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicate)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for color filter
        if !selectedColors.isEmpty {
            let colorPredicates = selectedColors.map { color in
                NSPredicate(format: "ANY colors.name = %@", color.name)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: colorPredicates)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for weight filter
        if !selectedWeights.isEmpty {
            let weightPredicates = selectedWeights.map { weight in
                NSPredicate(format: "ANY weightAndYardages.weight = %@", weight.rawValue)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: weightPredicates)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for sock set
        if sockSet != -1 {
            // sock sets only
            if sockSet == 1 {
                predicates.append(NSPredicate(format: "isSockSet = %@", true as NSNumber))
            } else {
                // no sock sets
                let noSockSetsPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "isSockSet == %@", NSNumber(value: false)),
                    NSPredicate(format: "isSockSet == nil")
                ])
                predicates.append(noSockSetsPredicate)
            }
        }
        
        if colorType != nil {
            predicates.append(NSPredicate(format: "colorType = %@", colorType!.rawValue))
        }
        
        switch(selectedTab) {
        case .active:
            let activePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "isArchived == %@", NSNumber(value: false)),
                NSPredicate(format: "isArchived == nil")
            ])
            predicates.append(activePredicate)
        case .archived:
            predicates.append(NSPredicate(format: "isArchived = %@", true as NSNumber))
        }
        
        filteredFetchRequest.wrappedValue.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        return filteredFetchRequest.wrappedValue
    }
    
    var body: some View {
        NavigationStack {
            if !browseMode {
                Tabs(selectedTab: $selectedTab, tabCounts: tabCounts)
            }
            
            
            HStack {
                if showFilterCapsules {
                    FilterCapsules(
                        showFilterScreen: $showFilterScreen,
                        selectedColors: $selectedColors,
                        selectedWeights: $selectedWeights,
                        sockSet: $sockSet,
                        colorType: $colorType
                    )
                }
                
            }
            
            ScrollView {
                if filteredYarn.isEmpty {
                    ZStack {
                        // Reserve space matching the scroll view's frame
                        Spacer().containerRelativeFrame([.horizontal, .vertical])
                        
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
                                            .foregroundColor(.blue) // Customize the color to look like a link
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
                } else {
                    ScrollView {
                        LazyVGrid(columns: [.init(.adaptive(minimum:150))], spacing: 5) {
                            ForEach(filteredYarn) { yarn in
                                NavigationLink(
                                    destination: YarnInfo(
                                        yarn: yarn,
                                        toast : $toast,
                                        selectedTab : $selectedTab,
                                        browseMode : $browseMode,
                                        projectPairing: $projectPairing,
                                        patternWAndYBrowsingFor : patternWAndYBrowsingFor
                                    )
                                ) {
                                    VStack {
                                        ImageCarousel(images: .constant(yarn.uiImages), smallMode: true)
                                            .contextMenu {
                                                if !browseMode {
                                                    Button {
                                                        yarnToEdit = yarn
                                                    } label: {
                                                        Label("Edit", systemImage : "pencil")
                                                    }
                                                    
                                                    Button {
                                                        YarnUtils.shared.toggleYarnArchived(at: yarn)
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
                                        
                                        
                                        Text(yarn.name ?? "No Name")
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(Color.primary)
                                            .bold()
                                        
                                        Text(yarn.dyer ?? "N/A")
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                            .font(.caption)
                                            .bold()
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.top, 3)
                                    
                                }
                            
                            }
                        }
                    }
                    .padding(.vertical, 13)
                    .padding(.horizontal, 5)
                }
                
            }
            .navigationTitle("My Stash")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by Name or Dyer...",
                suggestions: {
                    ForEach(filteredSuggestions, id: \.self) { suggestion in
                        Text(suggestion).searchCompletion(suggestion).padding(.leading, 5)
                    }
                }
            )
            .onChange(of: searchText) {
                if searchText.isEmpty {
                    searchText = ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterScreen = true
                    }) {
                        Image(systemName: "slider.horizontal.3") // Use a system icon
                            .imageScale(.large)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddYarnForm = true
                    }) {
                        Image(systemName: "plus") // Use a system icon
                            .imageScale(.large)
                    }
                }
            }
        }
        .popover(isPresented: $showFilterScreen) {
            FilterYarn(
                selectedColors: $selectedColors,
                selectedWeights: $selectedWeights,
                sockSet : $sockSet,
                colorType : $colorType,
                filteredYarnCount: filteredYarnCount
            )
        }
        .fullScreenCover(isPresented: $showAddYarnForm) {
            AddOrEditYarnForm(toast : $toast, yarnToEdit : nil)  { addedYarn in
                if browseMode {
                    projectPairing.append(
                        ProjectPairingItem(
                            patternWeightAndYardage: patternWAndYBrowsingFor!,
                            yarnWeightAndYardage: addedYarn.weightAndYardageItems.first!.existingItem!
                        )
                    )
                    browseMode = false
                } else {
                    newYarn = addedYarn
                }
                
                showAddYarnForm = false
            }
        }
        .fullScreenCover(item: $yarnToEdit, onDismiss: { yarnToEdit = nil}) { yarn in
            AddOrEditYarnForm(toast : $toast, yarnToEdit : yarn)
        }
        .popover(item: $newYarn) { yarn in
            YarnInfo(yarn: yarn, toast : $toast, selectedTab : $selectedTab, isNewYarn : true)
        }
        .alert("Are you sure you want to delete this yarn?", isPresented: $showConfirmationDialog) {
            if let yarnToDelete = yarnToDelete {
                Button("Delete", role: .destructive) {
                    YarnUtils.shared.removeYarn(at: yarnToDelete, with: managedObjectContext)
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .toastView(toast: $toast)
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct FilterCapsules : View {
    @Binding var showFilterScreen : Bool
    @Binding var selectedColors   : [NamedColor]
    @Binding var selectedWeights  : [Weight]
    @Binding var sockSet          : Int
    @Binding var colorType        : ColorType?
    
    var body : some View {
        LazyVGrid(columns: [.init(.adaptive(minimum:120))], spacing: 10) {
            ForEach(selectedWeights, id: \.self) { weight in
                Button(action: {
                    if let index = selectedWeights.firstIndex(where: { $0 == weight }) {
                        selectedWeights.remove(at: index)
                    }
                }) {
                    HStack() {
                        Spacer()
                        
                        Text(weight.rawValue)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        Spacer()
                        
                        Image(systemName: "xmark")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .font(.caption)
                    }
                    .filterCapsule()
                }
            }
            
            if sockSet != -1 {
                Button(action: {
                    sockSet = -1
                }) {
                    HStack() {
                        Spacer()
                        
                        Text(sockSet == 1 ? "Sock Sets Only" : "No Sock Sets")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        Spacer()
                        
                        Image(systemName: "xmark")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .font(.caption)
                    }
                    .filterCapsule()
                }
            }
            
            if colorType != nil {
                Button(action: {
                    colorType = nil
                }) {
                    HStack() {
                        Spacer()
                        
                        Text(colorType!.rawValue)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        Spacer()
                        
                        Image(systemName: "xmark")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .font(.caption)
                    }
                    .filterCapsule()
                }
            }
            
            ForEach(selectedColors) { colorGroup in
                Button(action: {
                    if let index = selectedColors.firstIndex(where: { $0.id == colorGroup.id }) {
                        selectedColors.remove(at: index)
                    }
                }) {
                    HStack() {
                        Spacer()
                        
                        // Diamond-shaped color view
                        Circle()
                            .fill(Color(uiColor : colorGroup.colors[0]))
                            .frame(width: 13, height: 13)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 0.5) // Black border with width
                            )
                        
                        Text(colorGroup.name)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .fixedSize()
                        
                        Spacer()
                        
                        Image(systemName: "xmark")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .font(.caption)
                    }
                    .filterCapsule()
                }
            }
            
            Button(action: {
                showFilterScreen = true
            }) {
                Image(systemName: "plus.circle")
                    .font(.title2)
            }
        }
        .padding()
    }
}
