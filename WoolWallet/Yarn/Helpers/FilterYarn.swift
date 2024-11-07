//
//  SortAndFilterYarn.swift
//  WoolWallet
//
//  Created by Mac on 8/22/24.
//

import Foundation
import SwiftUI

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
                        
                        Text("Weight").bold()
                        
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
                        
                        Text("Sock Set").bold().padding(.top, 10)
                        
                        HStack {
                            FilterCapsule(
                                text : "Yes",
                                highlighted : sockSet == 1,
                                onClick : { sockSet = sockSet == 1 ? -1 : 1 }
                            )
                            
                            FilterCapsule(
                                text : "No",
                                highlighted : sockSet == 0,
                                onClick : { sockSet = sockSet == 0 ? -1 : 0 }
                            )
                        }
                        
                        Text("Color").bold().padding(.top, 10)
                        
                        ScrollView {
                            LazyVGrid(columns: [.init(.adaptive(minimum:84))], spacing: 10) {
                                ForEach(ColorType.allCases, id: \.id) { colorTypeEnum in
                                    FilterCapsule(
                                        text : colorTypeEnum.rawValue,
                                        highlighted : colorType == colorTypeEnum,
                                        onClick : { colorType = colorType == colorTypeEnum ? nil : colorTypeEnum }
                                    )
                                }
                                
                                ForEach(namedColors) { colorGroup in
                                    FilterCapsule(
                                        highlighted : selectedColors.contains(colorGroup),
                                        onClick : { toggleColorSelection(for: colorGroup) }
                                    ) {
                                        // Diamond-shaped color view
                                        Circle()
                                            .fill(Color(uiColor : colorGroup.colors[0]))
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black, lineWidth: 0.25) // Black border with width
                                            )
                                        
                                        Text(colorGroup.name)
                                            .foregroundColor(
                                                selectedColors.contains(colorGroup) ?
                                                Color.accentColor : Color(UIColor.secondaryLabel)
                                            )
                                            .fixedSize()
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
