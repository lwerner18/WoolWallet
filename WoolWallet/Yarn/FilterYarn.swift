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
    
    // Binding variables
    @Binding var showSheet: Bool
    @Binding var selectedColors: [NamedColor]
    @Binding var selectedWeights: [Weight]
    @Binding var sockSet: Int
//    @Binding var minLength: Int
//    @Binding var maxLength: Int
    var filteredYarnCount: Int
    
    // Computed property
    private var filtersApplied: Bool {
        !selectedColors.isEmpty || !selectedWeights.isEmpty || sockSet != -1
    }
    
    // init function
    init(
        showSheet : Binding<Bool>,
        selectedColors : Binding<[NamedColor]>,
        selectedWeights : Binding<[Weight]>,
        sockSet : Binding<Int>,
//        minLength : Binding<Int>,
//        maxLength : Binding<Int>,
        filteredYarnCount : Int
    ) {
        self._showSheet = showSheet
        self._selectedColors = selectedColors
        self._selectedWeights = selectedWeights
        self._sockSet = sockSet
        self.filteredYarnCount = filteredYarnCount
    }
    
    var body: some View {
        VStack {
            // Toolbar-like header
            HStack {
                Text("Filter").bold().font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                
                Spacer()
                
                Button(action: {
                    showSheet = false
                    resetFilters()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.black)
                        .font(.title)
                }
                .clipShape(Circle())
                .shadow(radius: 1)
            }
            .padding(.bottom, 10) // Padding around the button
            .padding(.top, 20) // Padding around the button
            .padding(.horizontal, 20) // Padding around the button
            
//            Divider() // Adds a thin line (border) below the HStack
//                .background(Color.gray) // Color of the border
//                .frame(height: 1) // Height of the border
//                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading) {
                    
                    Text("Weight").bold()
                    
                    ScrollView {
                        LazyVGrid(columns: [.init(.adaptive(minimum:120))], spacing: 10) {
                            ForEach(weights, id: \.self) { weight in
                                if weight != Weight.none {
                                    Button(action: {
                                        toggleWeightSelection(for: weight)
                                    }) {
                                        HStack() {
                                            
                                            Text(weight.rawValue)
                                                .foregroundColor(
                                                    selectedWeights.contains(weight) ? .blue : .gray
                                                )
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .padding(10)
                                        .background(
                                            selectedWeights.contains(weight) ?
                                                .blue.opacity(0.2) : .clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8)) // Apply rounded corners
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                                                .stroke(selectedWeights.contains(weight) ? .blue.opacity(0.2) : .gray, lineWidth: 0.3)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Text("Sock Set").bold().padding(.top, 10)
                    
                    HStack {
                        Button(action: {
                            if sockSet == 1 {
                                sockSet = -1
                            } else {
                                sockSet = 1
                            }
                        }) {
                            HStack() {
                                
                                Text("Yes")
                                    .foregroundColor(
                                        sockSet == 1 ? .blue : .gray
                                    )
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding(10)
                            .background(
                                sockSet == 1 ? .blue.opacity(0.2) : .clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8)) // Apply rounded corners
                            .overlay(
                                RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                                    .stroke(sockSet == 1 ? .blue.opacity(0.2) : .gray, lineWidth: 0.3)
                            )
                        }
                        
                        Button(action: {
                            if sockSet == 0 {
                                sockSet = -1
                            } else {
                                sockSet = 0
                            }
                        }) {
                            HStack() {
                                
                                Text("No")
                                    .foregroundColor(
                                        sockSet == 0 ? .blue : .gray
                                    )
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding(10)
                            .background(
                                sockSet == 0 ? .blue.opacity(0.2) : .clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8)) // Apply rounded corners
                            .overlay(
                                RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                                    .stroke(sockSet == 0 ? .blue.opacity(0.2) : .gray, lineWidth: 0.3)
                            )
                        }
                    }
                    
                    Text("Color").bold().padding(.top, 10)
                    
                    ScrollView {
                        LazyVGrid(columns: [.init(.adaptive(minimum:84))], spacing: 10) {
                            ForEach(namedColors) { colorGroup in
                                Button(action: {
                                    toggleColorSelection(for: colorGroup)
                                }) {
                                    HStack() {
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
                                                    .blue : .gray
                                            )
                                            .fixedSize()
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding(10)
                                    .background(
                                        selectedColors.contains(colorGroup) ?
                                            .blue.opacity(0.2) : .clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Apply rounded corners
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                                            .stroke(selectedColors.contains(colorGroup) ? .blue.opacity(0.2) : .gray, lineWidth: 0.3)
                                    )
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
                    resetFilters()
                } label: {
                    Text("Reset").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button {
                    showSheet = false
                } label: {
                    Text("Show \(filteredYarnCount) result\(filteredYarnCount != 1 ? "s" : "")").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!filtersApplied)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 10)
        }
    }
    
    func resetFilters() {
        selectedColors = []
        selectedWeights = []
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
