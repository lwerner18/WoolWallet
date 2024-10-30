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
    
    var filteredSuggestions: [String] {
        guard !searchText.isEmpty else { return [] }
        return uniqueDesigners.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    @State private var showConfirmationDialog : Bool = false
    @State var         searchText             : String = ""
    @State private var showAddPatternForm     : Bool = false
    @State private var newPattern             : Pattern? = nil
    @State private var patternToDelete        : Pattern? = nil
    @State private var patternToEdit          : Pattern? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                if filteredPatterns.isEmpty {
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
                } else {
                    List {
                        ForEach(filteredPatterns) { pattern in
                            NavigationLink(
                                destination: PatternInfo(pattern: pattern, browseMode: $browseMode, browsePattern : $browsePattern)
                            ) {
                                let itemDisplay =
                                    PatternUtils.shared.getItemDisplay(
                                        for: pattern.patternItems.isEmpty ? nil : pattern.patternItems.first?.item
                                    )
                                HStack {
                                    
                                    Text("").frame(maxWidth: 0)
                                    
                                    if itemDisplay.custom {
                                        Image(itemDisplay.icon)
                                            .iconCircle(background: itemDisplay.color)
                                    } else {
                                        Image(systemName: itemDisplay.icon)
                                            .iconCircle(background: itemDisplay.color)
                                    }
                          
                                    
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
                                    
                                    VStack {
                                        Text(pattern.type ?? "")
                                            .foregroundStyle(Color.primary)
                                            .font(.caption)
                                        
                                        let projectsNum = pattern.projects?.count ?? 0
                                        
                                        Text("Used in \(projectsNum == 1 ? "1 project" : "\(projectsNum) projects")")
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                            .font(.caption)
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
            .onChange(of: browsePattern) {
                dismiss()
            }
           
        }
    }
}
