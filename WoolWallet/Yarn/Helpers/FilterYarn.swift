//
//  SortAndFilterYarn.swift
//  WoolWallet
//
//  Created by Mac on 8/22/24.
//

import Foundation
import SwiftUI

struct ColorFilter : Hashable {
    var namedColor : NamedColor? = nil
    var colorType : ColorType? = nil
}

struct FilterYarn: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    
    // Binding variables
    @Binding var selectedColors: [NamedColor]
    @Binding var selectedWeights: [Weight]
    @Binding var sockSet: Int
    @Binding var colorType: ColorType?
//    @Binding var minLength: Int
//    @Binding var maxLength: Int
    var filteredYarnCount: Int
    
    // Computed property
    private var filtersApplied: Bool {
        !selectedColors.isEmpty || !selectedWeights.isEmpty || sockSet != -1 || colorType != nil
    }
    
    private var colorFilters: [ColorFilter] {
        var filterItems : [ColorFilter] = []
        
        ColorType.allCases.forEach { colorType in
            filterItems.append(ColorFilter(colorType : colorType))
        }
        
        namedColors.forEach { namedColor in
            filterItems.append(ColorFilter(namedColor : namedColor))
        }
        
        return filterItems
    }
    
    // init function
    init(
        selectedColors : Binding<[NamedColor]>,
        selectedWeights : Binding<[Weight]>,
        sockSet : Binding<Int>,
        colorType : Binding<ColorType?>,
//        minLength : Binding<Int>,
//        maxLength : Binding<Int>,
        filteredYarnCount : Int
    ) {
        self._selectedColors = selectedColors
        self._selectedWeights = selectedWeights
        self._sockSet = sockSet
        self._colorType = colorType
        self.filteredYarnCount = filteredYarnCount
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading) {
                        
                        Text("Weight").bold().padding(.bottom, 8)
                        
                        FlexView(data: Weight.allCases, spacing: 6) { weight in
                            HStack {
                                if weight != Weight.none {
                                    FilterCapsule(
                                        text : weight.rawValue,
                                        highlighted : selectedWeights.contains(weight),
                                        onClick : { toggleWeightSelection(for: weight)}
                                    )
                                }
                            }
                        }
                        
                        Text("Sock Set").bold().padding(.top, 10)
                        
                        FlexView(data: [0, 1], spacing: 6) { value in
                            FilterCapsule(
                                text : value == 0 ? "No" : "Yes",
                                highlighted : sockSet == value,
                                onClick : { sockSet = sockSet == value ? -1 : value }
                            )
                        }
                        
                        Text("Color").bold().padding(.top, 10)
                        
                        FlexView(data: colorFilters, spacing: 6) { colorFilter in
                            HStack{
                                if colorFilter.colorType != nil {
                                    FilterCapsule(
                                        text : colorFilter.colorType!.rawValue,
                                        highlighted : colorType == colorFilter.colorType!,
                                        onClick : { colorType = colorType == colorFilter.colorType ? nil : colorFilter.colorType! }
                                    )
                                } else {
                                    FilterCapsule(
                                        highlighted : selectedColors.contains(colorFilter.namedColor!),
                                        onClick : { toggleColorSelection(for: colorFilter.namedColor!) }
                                    ) {
                                        // Diamond-shaped color view
                                        Circle()
                                            .fill(Color(uiColor : colorFilter.namedColor!.colors[0]))
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black, lineWidth: 0.25) // Black border with width
                                            )
                                        
                                        Text(colorFilter.namedColor!.name)
                                            .foregroundColor(
                                                selectedColors.contains(colorFilter.namedColor!) ?
                                                Color.accentColor : Color(UIColor.secondaryLabel)
                                            )
                                    }
                                }
                            }
                         
                        }
                    }
                    .padding()
                }
                
                HStack{
                    Button {
                        dismiss()
                    } label: {
                        Text("Show \(filteredYarnCount) result\(filteredYarnCount != 1 ? "s" : "")")
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
        selectedColors = []
        selectedWeights = []
        sockSet = -1
        colorType = nil
    }
    
    func toggleColorSelection(for item: NamedColor) {
        if selectedColors.contains(item) {
            if let index = selectedColors.firstIndex(where: { $0.id == item.id }) {
                selectedColors.remove(at: index)
            }
        } else {
            selectedColors.append(item)
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
