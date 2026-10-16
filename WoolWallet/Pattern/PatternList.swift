//
//  PatternList.swift
//  WoolWallet
//
//  Created by Mac on 9/3/24.
//

import Foundation
import SwiftUI

struct PatternList: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Binding var browseMode : Bool
    @Binding var browsePattern : Pattern?
    
    init(
        browseMode: Binding<Bool> = .constant(false),
        browsePattern : Binding<Pattern?> = .constant(nil)
    ) {
        self._browseMode = browseMode
        self._browsePattern = browsePattern
    }
    
    private var filteredFetchRequest = FetchRequest<Pattern>(
        sortDescriptors: [SortDescriptor(\.name)],
        predicate: NSPredicate(value: true),
        animation: .default
    )
    
    // Computed property to get all the patterns with an optional searchText
    private var filteredPatterns: FetchedResults<Pattern> {
        
        // Apply sorting based on the selected option
        filteredFetchRequest.wrappedValue.nsSortDescriptors = sort.sortDescriptors
        
        var predicates: [NSPredicate] = []
        if searchText != "" {
            var searchPredicate = [NSPredicate(format: "name CONTAINS[c] %@", searchText)]
            searchPredicate.append(NSPredicate(format: "designer CONTAINS[c] %@", searchText))
            
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicate)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for item filter
        if !selectedItems.isEmpty {
            let itemsPredicate = selectedItems.map { item in
                NSPredicate(format: "ANY items.item = %@", item.rawValue)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: itemsPredicate)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for type filter
        if !selectedTypes.isEmpty {
            let typesPredicate = selectedTypes.map { type in
                NSPredicate(format: "type = %@", type.rawValue)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: typesPredicate)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for weight filter
        if !selectedWeights.isEmpty {
            let weightPredicates = selectedWeights.map { weight in
                NSPredicate(format: "ANY recWeightAndYardages.weight = %@", weight.rawValue)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: weightPredicates)
            predicates.append(compoundPredicate)
        }
        
        if owned != nil {
            // sock sets only
            if owned! {
                predicates.append(NSPredicate(format: "owned = %@", true as NSNumber))
            } else {
                predicates.append(NSPredicate(format: "owned = %@", NSNumber(value: false)))
            }
        }
        
        switch(selectedTab) {
        case .notUsed:
            predicates.append(NSPredicate(format: "projects.@count == 0"))
        case .used:
            predicates.append(NSPredicate(format: "projects.@count > 0"))
        case .all:
            break
        }
        
        filteredFetchRequest.wrappedValue.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        return filteredFetchRequest.wrappedValue
    }
    
    @FetchRequest(
        fetchRequest: Pattern.fetchPartialRequest()
    ) private var allPatterns: FetchedResults<Pattern>
    
    private var uniqueDesigners: [String] {
        // Extract designers and remove duplicates
        let designers = Set(allPatterns.compactMap { $0.designer })
        return Array(designers).sorted() // Optional: Sort the list of designers
    }
    
    private var tabCounts: [TabCount<PatternTab>] {
        return [
            TabCount(tab: PatternTab.all, count: allPatterns.count),
            TabCount(tab: PatternTab.notUsed, count: allPatterns.filter {!$0.hasProjects}.count),
            TabCount(tab: PatternTab.used, count: allPatterns.filter {$0.hasProjects}.count),
        ]
    }
    
    var filteredSuggestions: [String] {
        guard !searchText.isEmpty else { return [] }
        return uniqueDesigners.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    var showFilterCapsules : Bool {
        return !selectedItems.isEmpty || !selectedTypes.isEmpty || !selectedWeights.isEmpty || owned != nil
    }
    
    @State private var showConfirmationDialog : Bool = false
    @State private var showFilterScreen       : Bool = false
    @State         var searchText             : String = ""
    @State private var showAddPatternForm     : Bool = false
    @State private var newPattern             : Pattern? = nil
    @State private var patternToDelete        : Pattern? = nil
    @State private var patternToEdit          : Pattern? = nil
    @State private var selectedItems          : [Item] = []
    @State private var selectedTypes          : [PatternType] = []
    @State private var selectedWeights        : [Weight] = []
    @State private var owned                  : Bool? = nil
    @State private var selectedTab            : PatternTab = PatternTab.all
    @State private var isRefreshing           : Bool = false
    @State private var patternToRead          : Pattern? = nil
    @State private var patternForProject      : Pattern? = nil
    @State private var newProject             : Project? = nil
    
    @AppStorage("patternListSort") private var sort : PatternSort = .name
    @AppStorage("patternListLayout") private var layout : PatternLayout = .grid
                     
    
    var body: some View {
        NavigationStack {
            Tabs(selectedTab: $selectedTab, tabCounts: tabCounts)
            
            if showFilterCapsules {
                PatternFilterCapsules(
                    showFilterScreen: $showFilterScreen,
                    selectedItems: $selectedItems,
                    selectedTypes : $selectedTypes,
                    selectedWeights : $selectedWeights,
                    owned : $owned
                )
            }
            
            VStack {
                if filteredPatterns.isEmpty {
                    ScrollView {
                        ZStack {
                            // Reserve space matching the scroll view's frame
                            Spacer().containerRelativeFrame([.horizontal, .vertical])
                            
                            if selectedTab == PatternTab.all {
                                VStack {
                                    Image("moPissed") // Replace with your image's name
                                        .resizable() // If you want to adjust the size
                                        .scaledToFit() // Adjust the image's aspect ratio
                                        .frame(width: 300, height: 225) // Set desired frame size
                                    
                                    Text("You don't have a single pattern.")
                                        .font(.title)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                    
                                    VStack {
                                        HStack(spacing: 0) {
                                            Text("Please")
                                            
                                            if !browseMode {
                                                Button(action: {
                                                    showAddPatternForm = true
                                                }) {
                                                    Text(" add a pattern ")
                                                        .foregroundStyle(Color.accentColor)
                                                }
                                                .buttonStyle(PlainButtonStyle()) // Remove default button styling
                                                .padding(0)
                                                
                                                Text("or")
                                            }
                                            
                                            Text(" modify your search.")
                                                .font(.body)
                                        }
                                        
                                    }
                                    .padding(.top, 5)
                                }
                                .padding()
                            } else if selectedTab == PatternTab.notUsed {
                                VStack {
                                    Image("babyMo") // Replace with your image's name
                                        .resizable() // If you want to adjust the size
                                        .scaledToFit() // Adjust the image's aspect ratio
                                        .frame(width: 300, height: 225) // Set desired frame size
                                    
                                    Text("You must be exhausted. There are no unused patterns.")
                                        .font(.title)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                    
                                    VStack {
                                        HStack(spacing: 0) {
                                            Text("Please")
                                            
                                            if !browseMode {
                                                Button(action: {
                                                    showAddPatternForm = true
                                                }) {
                                                    Text(" add a pattern ")
                                                        .foregroundStyle(Color.accentColor)
                                                }
                                                .buttonStyle(PlainButtonStyle()) // Remove default button styling
                                                .padding(0)
                                                
                                                Text("or")
                                            }
                                            
                                            Text(" modify your search.")
                                                .font(.body)
                                        }
                                        
                                    }
                                    .padding(.top, 5)
                                }
                                .padding()
                            } else {
                                VStack {
                                    Image("moSearch") // Replace with your image's name
                                        .resizable() // If you want to adjust the size
                                        .scaledToFit() // Adjust the image's aspect ratio
                                        .frame(width: 300, height: 225) // Set desired frame size
                                    
                                    Text("There doesn't seem to be anything here.")
                                        .font(.title)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                    
                                    VStack {
                                        HStack(spacing: 0) {
                                            Text("Please")
                                            
                                            if !browseMode {
                                                Button(action: {
                                                    showAddPatternForm = true
                                                }) {
                                                    Text(" add a pattern ")
                                                        .foregroundStyle(Color.accentColor)
                                                }
                                                .buttonStyle(PlainButtonStyle()) // Remove default button styling
                                                .padding(0)
                                                
                                                Text("or")
                                            }
                                            
                                            Text(" modify your search.")
                                                .font(.body)
                                        }
                                        
                                    }
                                    .padding(.top, 5)
                                }
                                .padding()
                            }
                        }
                    }
                } else if layout == .grid {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 20) {
                            ForEach(filteredPatterns, id: \.objectID) { pattern in
                                patternGridItem(for: pattern)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                } else {
                    List {
                        ForEach(filteredPatterns, id: \.objectID) { pattern in
                            patternListItem(for: pattern)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(browseMode ? "Browse Patterns" : "Patterns")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by Name or Designer...",
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
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Layout", selection: $layout.animation()) {
                            ForEach(PatternLayout.allCases) { option in
                                Label(option.rawValue, systemImage: option.systemImage).tag(option)
                            }
                        }
                        
                        Section("Sort By") {
                            Picker("Sort By", selection: $sort.animation()) {
                                ForEach(PatternSort.allCases) { option in
                                    Label(option.rawValue, systemImage: option.systemImage).tag(option)
                                }
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
                        showAddPatternForm = true
                    }) {
                        Label("Add Pattern", systemImage: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showAddPatternForm, onDismiss: { newPattern = nil }) {
                // Swap to the success screen in place so the list never flashes between the two
                if let newPattern {
                    PatternInfo(pattern: newPattern, isNewPattern : true)
                        .transition(.opacity)
                } else {
                    AddOrEditPatternForm(patternToEdit : nil)  { addedPattern in
                        if browseMode {
                            browsePattern = addedPattern
                            browseMode = false
                            showAddPatternForm = false
                        } else {
                            withAnimation {
                                newPattern = addedPattern
                            }
                        }
                    }
                }
            }
            .fullScreenCover(item: $patternToEdit, onDismiss: { patternToEdit = nil}) { pattern in
                AddOrEditPatternForm(patternToEdit : pattern)
            }
            .alert("Are you sure you want to delete this pattern?", isPresented: $showConfirmationDialog) {
                if let pattern = patternToDelete {
                    Button("Delete", role: .destructive) {
                        // Give the alert a moment to fade so the row is visible as it goes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            deletePattern(pattern)
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showFilterScreen) {
                FilterPattern(
                    selectedItems: $selectedItems,
                    selectedTypes: $selectedTypes,
                    selectedWeights: $selectedWeights,
                    owned : $owned,
                    filteredPatternCount: filteredPatterns.count
                )
            }
            .onChange(of: browsePattern) { _, selected in
                // Parent presents this list with navigationDestination(isPresented: browseMode).
                // dismiss() would close the project form; flipping browseMode pops instead.
                if selected != nil {
                    browseMode = false
                }
            }
            .fullScreenCover(item: $patternToRead) { pattern in
                if let document = pattern.document {
                    SavedPatternReader(document: document, title: pattern.name ?? "Pattern")
                }
            }
            .sheet(item: $patternForProject, onDismiss: { newProject = nil }) { pattern in
                // Swap to the success screen in place so the list never flashes between the two
                if let newProject {
                    ProjectInfo(project: newProject, isNewProject : true, isPopover : true)
                        .transition(.opacity)
                } else {
                    AddOrEditProjectForm(projectToEdit: nil, preSelectedPattern: pattern) { addedProject in
                        withAnimation {
                            newProject = addedProject
                        }
                    }
                }
            }
        }
    }
    
    private func patternInfo(for pattern: Pattern) -> some View {
        PatternInfo(pattern: pattern, selectedTab: $selectedTab, browseMode: $browseMode, browsePattern : $browsePattern)
    }
    
    private func selectPattern(_ pattern: Pattern) {
        browsePattern = pattern
        browseMode = false
    }
    
    @ViewBuilder
    private func patternGridItem(for pattern: Pattern) -> some View {
        if browseMode {
            Button {
                selectPattern(pattern)
            } label: {
                PatternCard(pattern: pattern)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Selects this pattern for the project")
        } else {
            NavigationLink(destination: patternInfo(for: pattern)) {
                PatternCard(pattern: pattern)
            }
            .buttonStyle(.plain)
            .contextMenu {
                patternActions(for: pattern)
            } preview: {
                coverPreview(for: pattern)
            }
        }
    }
    
    @ViewBuilder
    private func patternListItem(for pattern: Pattern) -> some View {
        if browseMode {
            Button {
                selectPattern(pattern)
            } label: {
                PatternRow(pattern: pattern)
            }
            .accessibilityHint("Selects this pattern for the project")
        } else {
            NavigationLink(destination: patternInfo(for: pattern)) {
                PatternRow(pattern: pattern)
            }
            .swipeActions(allowsFullSwipe: false) {
                Button {
                    patternToEdit = pattern
                } label: {
                    Label("Edit", systemImage : "pencil")
                }
                .tint(Color.accentColor)
                
                // A destructive role slides the row out before the user confirms
                Button {
                    patternToDelete = pattern
                    showConfirmationDialog = true
                } label: {
                    Label("Delete", systemImage : "trash")
                }
                .tint(Color.red)
            }
            .contextMenu {
                patternActions(for: pattern)
            } preview: {
                coverPreview(for: pattern)
            }
        }
    }
    
    @ViewBuilder
    private func patternActions(for pattern: Pattern) -> some View {
        if pattern.document != nil {
            Button {
                patternToRead = pattern
            } label: {
                Label("Read Pattern", systemImage: "book.pages")
            }
        }
        
        if !browseMode {
            Button {
                patternForProject = pattern
            } label: {
                Label("Start a Project", systemImage: "hammer")
            }
            
            Button {
                patternToEdit = pattern
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                patternToDelete = pattern
                showConfirmationDialog = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func coverPreview(for pattern: Pattern) -> some View {
        PatternCover(pattern: pattern, cornerRadius: 0)
            .frame(width: 270, height: 360)
    }
    
    private func deletePattern(_ pattern: Pattern) {
        guard !pattern.isDeleted else { return }
        
        withAnimation {
            PatternUtils.shared.removePattern(at: pattern, with: managedObjectContext)
        }
    }
}

struct PatternFilter : Hashable {
    var type : PatternType? = nil
    var item : Item? = nil
    var weight : Weight? = nil
    var owned : Bool? = nil
    var last : Bool = false
}

struct PatternFilterCapsules : View {
    @Binding var showFilterScreen : Bool
    @Binding var selectedItems    : [Item]
    @Binding var selectedTypes    : [PatternType]
    @Binding var selectedWeights  : [Weight]
    @Binding var owned            : Bool?
    
    var patternFilters: [PatternFilter] {
        var filterItems : [PatternFilter] = []
        
        selectedTypes.forEach { type in
            filterItems.append(PatternFilter(type : type))
        }
        
        selectedWeights.forEach { weight in
            filterItems.append(PatternFilter(weight : weight))
        }
        
        selectedItems.forEach { item in
            filterItems.append(PatternFilter(item : item))
        }
        
        if owned != nil {
            filterItems.append(PatternFilter(owned : owned))
        }
        
        filterItems.append(PatternFilter(last: true))
        
        return filterItems
    }
    
    
    var body : some View {
        FlexView(data: patternFilters, spacing: 6) { patternFilter in
            HStack {
                if patternFilter.type != nil {
                    FilterCapsule(text : patternFilter.type!.rawValue, showX: true, onClick : {
                        if let index = selectedTypes.firstIndex(where: { $0 == patternFilter.type! }) {
                            selectedTypes.remove(at: index)
                        }
                    })
                } else if patternFilter.weight != nil {
                    FilterCapsule(
                        text : patternFilter.weight!.rawValue,
                        showX: true,
                        onClick : {
                            if let index = selectedWeights.firstIndex(where: { $0 == patternFilter.weight! }) {
                                selectedWeights.remove(at: index)
                            }
                        }
                    )
                } else if patternFilter.item != nil {
                    FilterCapsule(showX: true, onClick : {
                        if let index = selectedItems.firstIndex(where: { $0 == patternFilter.item! }) {
                            selectedItems.remove(at: index)
                        }
                    }) {
                        if patternFilter.item != Item.none {
                            PatternItemDisplayWithItem(item: patternFilter.item!, size: Size.extraSmall)
                        }
                        
                        Text(patternFilter.item!.rawValue)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                } else if patternFilter.owned != nil {
                    FilterCapsule(
                        text : patternFilter.owned! ? "Owned" : "Not Owned",
                        showX: true,
                        onClick : { owned = nil }
                    )
                } else if patternFilter.last {
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

