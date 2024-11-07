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
        filteredFetchRequest.wrappedValue.nsSortDescriptors = [NSSortDescriptor(keyPath: \Yarn.name, ascending: true)]
        
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
        
        switch(selectedTab) {
        case .notUsed:
            predicates.append(NSPredicate(format: "projects.@count == 0"))
        case .used:
            predicates.append(NSPredicate(format: "projects.@count > 0"))
        case .all:
            print("")
        }
        
        filteredFetchRequest.wrappedValue.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        return filteredFetchRequest.wrappedValue
    }
    
    @FetchRequest(
        entity: Pattern.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Pattern.name, ascending: true)] // Optional: Sort by name
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
        return !selectedItems.isEmpty || !selectedTypes.isEmpty || !selectedWeights.isEmpty
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
    @State private var selectedTab            : PatternTab = PatternTab.all
    @State private var isRefreshing           : Bool = false
                     
    
    var body: some View {
        NavigationStack {
            Tabs(selectedTab: $selectedTab, tabCounts: tabCounts)
            
            if showFilterCapsules {
                PatternFilterCapsules(
                    showFilterScreen: $showFilterScreen,
                    selectedItems: $selectedItems,
                    selectedTypes : $selectedTypes,
                    selectedWeights : $selectedWeights
                )
            }
            
            VStack {
                if filteredPatterns.isEmpty {
                    ScrollView {
                        ZStack {
                            // Reserve space matching the scroll view's frame
                            Spacer().containerRelativeFrame([.horizontal, .vertical])
                            
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
                                                    .foregroundColor(.blue) // Customize the color to look like a link
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
                } else {
                    List {
                        ForEach(filteredPatterns, id: \.id) { pattern in
                            NavigationLink(
                                destination: PatternInfo(pattern: pattern, browseMode: $browseMode, browsePattern : $browsePattern)
                            ) {
                                
                                HStack {
                                    
                                    Text("").frame(maxWidth: 0)
                                    
                                    PatternItemDisplay(pattern: pattern)
                                    
                                    
                                    VStack(alignment: .leading) {
                                        Spacer()
                                        
                                        Text(pattern.name ?? "No Name")
                                            .foregroundStyle(Color.primary)
                                            .bold()
                                        
                                        if pattern.designer != nil {
                                            Text(pattern.designer!)
                                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                                .font(.footnote)
                                                .bold()
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.leading, 4)
                                    
                                    Spacer()
                                    
                                    VStack(spacing: 3) {
                                        Text(pattern.type ?? "")
                                            .foregroundStyle(Color.primary)
                                            .font(.caption)
                                        
                                        let projectsNum = pattern.projects?.count ?? 0
                                        
                                        if projectsNum != 0 {
                                            Text("Used in \(projectsNum == 1 ? "1 project" : "\(projectsNum) projects")")
                                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                                .font(.caption)
                                        }
                                        
                                        if pattern.patternItems.first?.item == Item.other {
                                            Text(
                                                PatternUtils.shared.joinedItems(patternItems: pattern.patternItems)
                                            )
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                            .font(.caption2)
                                        }
                                    }
                                }
                                .swipeActions(allowsFullSwipe: false) {
                                    if !browseMode {
                                        Button {
                                            patternToEdit = pattern
                                        } label: {
                                            Label("", systemImage : "pencil")
                                            
                                        }
                                        .tint(Color.accentColor)
                                        
                                        Button(role: .destructive) {
                                            patternToDelete = pattern
                                            showConfirmationDialog = true
                                        } label: {
                                            Label("", systemImage : "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Patterns")
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
                        showAddPatternForm = true
                    }) {
                        Image(systemName: "plus") // Use a system icon
                            .imageScale(.large)
                    }
                }
            }
            .fullScreenCover(isPresented: $showAddPatternForm) {
                AddOrEditPatternForm(patternToEdit : nil)  { addedPattern in
                    if browseMode {
                        browsePattern = addedPattern
                        browseMode = false
                    } else {
                        newPattern = addedPattern
                    }
                    
                    showAddPatternForm = false
                }
            }
            .fullScreenCover(item: $patternToEdit, onDismiss: { patternToEdit = nil}) { pattern in
                AddOrEditPatternForm(patternToEdit : pattern)
            }
            .popover(item: $newPattern) { pattern in
                PatternInfo(pattern: pattern, isNewPattern : true)
            }
            .alert("Are you sure you want to delete this pattern?", isPresented: $showConfirmationDialog) {
                if let pattern = patternToDelete {
                    Button("Delete", role: .destructive) {
                        PatternUtils.shared.removePattern(at: pattern, with: managedObjectContext)
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .popover(isPresented: $showFilterScreen) {
                FilterPattern(
                    selectedItems: $selectedItems,
                    selectedTypes: $selectedTypes,
                    selectedWeights: $selectedWeights,
                    filteredPatternCount: filteredPatterns.count
                )
            }
            .onChange(of: browsePattern) {
                dismiss()
            }
           
        }
    }
}

struct PatternFilterCapsules : View {
    @Binding var showFilterScreen : Bool
    @Binding var selectedItems    : [Item]
    @Binding var selectedTypes    : [PatternType]
    @Binding var selectedWeights  : [Weight]
    
    var body : some View {
        LazyVGrid(columns: [.init(.adaptive(minimum:120))], spacing: 10) {
            ForEach(selectedTypes, id: \.id) { type in
                FilterCapsule(text : type.rawValue, showX: true, onClick : {
                    if let index = selectedTypes.firstIndex(where: { $0 == type }) {
                        selectedTypes.remove(at: index)
                    }
                })
            }
            
            ForEach(selectedWeights, id: \.id) { weight in
                FilterCapsule(
                    text : weight.rawValue,
                    showX: true,
                    onClick : {
                        if let index = selectedWeights.firstIndex(where: { $0 == weight }) {
                            selectedWeights.remove(at: index)
                        }
                    }
                )
            }
            
            ForEach(selectedItems, id: \.id) { item in
                FilterCapsule(showX: true, onClick : {
                    if let index = selectedItems.firstIndex(where: { $0 == item }) {
                        selectedItems.remove(at: index)
                    }
                }) {
                    if item != Item.none {
                        PatternItemDisplayWithItem(item: item, size: Size.extraSmall)
                    }
                    
                    Text(item.rawValue)
                        .foregroundColor(Color(UIColor.secondaryLabel))
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

