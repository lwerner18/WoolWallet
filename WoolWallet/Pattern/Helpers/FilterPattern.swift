//
//  FilterPattern.swift
//  WoolWallet
//
//  Created by Mac on 11/4/24.
//

import Foundation
import SwiftUI

struct FilterPattern: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    
    // Binding variables
    @Binding var selectedItems : [Item]
    @Binding var selectedTypes : [PatternType]
    @Binding var selectedWeights : [Weight]
    var filteredPatternCount: Int
    
    // Computed property
    private var filtersApplied: Bool {
        !selectedItems.isEmpty || !selectedTypes.isEmpty || !selectedWeights.isEmpty
    }
    
    // init function
    init(
        selectedItems : Binding<[Item]>,
        selectedTypes : Binding<[PatternType]>,
        selectedWeights : Binding<[Weight]>,
        filteredPatternCount : Int
    ) {
        self._selectedItems = selectedItems
        self._selectedTypes = selectedTypes
        self._selectedWeights = selectedWeights
        self.filteredPatternCount = filteredPatternCount
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading) {
                        
                        Text("Type").bold()
                        
                        ScrollView {
                            LazyVGrid(columns: [.init(.adaptive(minimum:120))], spacing: 10) {
                                ForEach(PatternType.allCases, id: \.id) { type in
                                    FilterCapsule(
                                        text : type.rawValue,
                                        highlighted : selectedTypes.contains(type),
                                        onClick : { toggleTypeSelection(for: type)}
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Text("Weight").bold().padding(.top, 10)
                        
                        ScrollView {
                            LazyVGrid(columns: [.init(.adaptive(minimum:120))], spacing: 10) {
                                ForEach(Weight.allCases, id: \.id) { weight in
                                    if weight != Weight.none {
                                        FilterCapsule(
                                            text : weight.rawValue,
                                            highlighted : selectedWeights.contains(weight),
                                            onClick : { toggleWeightSelection(for: weight)}
                                        )
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Text("Item").bold().padding(.top, 10)
                        
                        ScrollView {
                            LazyVGrid(columns: [.init(.adaptive(minimum:175))], spacing: 10) {
                                ForEach(Item.allCases, id: \.id) { item in
                                    if item != Item.none {
                                        FilterCapsule(highlighted : selectedItems.contains(item), onClick : {  toggleItemSelection(for: item)}) {
                                            if item != Item.none {
                                                PatternItemDisplayWithItem(item: item, size: Size.extraSmall)
                                            }
                                            
                                            Text(item.rawValue)
                                                .foregroundColor(
                                                    selectedItems.contains(item)
                                                    ? Color.accentColor
                                                    : Color(UIColor.secondaryLabel)
                                                )
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
                
                HStack{
                    Button {
                        dismiss()
                    } label: {
                        Text("Show \(filteredPatternCount) result\(filteredPatternCount != 1 ? "s" : "")")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!filtersApplied)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 10)
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        resetFilters()
                    }) {
                        Text("Reset")
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .ignoresSafeArea(edges: .bottom)
        
    }
    
    func resetFilters() {
        selectedItems = []
        selectedTypes = []
        selectedWeights = []
    }
    
    func toggleItemSelection(for item: Item) {
        if selectedItems.contains(item) {
            if let index = selectedItems.firstIndex(where: { $0 == item }) {
                selectedItems.remove(at: index)
            }
        } else {
            selectedItems.append(item)
        }
    }
    
    func toggleTypeSelection(for type: PatternType) {
        if selectedTypes.contains(type) {
            if let index = selectedTypes.firstIndex(where: { $0 == type }) {
                selectedTypes.remove(at: index)
            }
        } else {
            selectedTypes.append(type)
        }
    }
    
    func toggleWeightSelection(for item: Weight) {
        if selectedWeights.contains(item) {
            if let index = selectedWeights.firstIndex(where: { $0 == item }) {
                selectedWeights.remove(at: index)
            }
        } else {
            selectedWeights.append(item)
        }
    }
}

