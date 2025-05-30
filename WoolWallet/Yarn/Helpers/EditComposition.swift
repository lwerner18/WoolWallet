//
//  EditComposition.swift
//  WoolWallet
//
//  Created by Mac on 9/22/24.
//

import Foundation
import SwiftUI
import Charts

struct CompositionItem : Identifiable, Hashable {
    var id = UUID()
    var percentage: Int
    var material: String
    var materialDescription : String = ""
    var existingItem : Composition? = nil
}

//struct MaterialItem: Identifiable, Equatable {
//    let id = UUID()
//    
//    var value: String
//    var showDescription : Bool = false
//    var description : String = ""
//}

let chartColors : [Color] = [
    Color(hex : "#DAA520"),
    Color(hex : "#A9C78A"),
    Color(hex : "#76B2B8"),
    Color(hex : "#B68BCE"),
    Color(hex : "#C76A4D")
]

struct CompositionText : View {
    var composition : [CompositionItem]
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                let sortedCompositions = composition.sorted { $0.percentage > $1.percentage}
                
                ForEach(sortedCompositions, id: \.id) { compositionItem in
                    let material = YarnUtils.shared.getMaterial(item: compositionItem)
                    
                    if compositionItem.percentage != 0 && material != "" {
                        Text(
                            "\(compositionItem.percentage)% \(material)\(sortedCompositions.last != compositionItem ? "," : "") "
                        )
                        .foregroundStyle(Color.primary)
                        .lineLimit(nil) // Allow wrapping
                    }
                }
            }
            .multilineTextAlignment(.center) // Center the text
            .frame(maxHeight: .infinity) // Vertically center in the parent
            
            Spacer()
        }
    }
}

struct CompositionChart : View {
    var composition : [CompositionItem]
    var smallMode : Bool? = false
    
    // Computed property to calculate the remainingComposition
    var remainingComposition: Int {
        var remaining = 100
        
        for compositionItem in composition {
            if compositionItem.percentage != 0 && compositionItem.material != "" {
                remaining -= Int(compositionItem.percentage)
            }
        }
        
        return remaining
    }
    
    var body: some View {
        Chart {
            if remainingComposition != 0 {
                SectorMark(
                    angle: .value("Percentage", remainingComposition),
//                    innerRadius: .ratio(0.65),
                    angularInset: 2
                )
                .cornerRadius(5)
                .foregroundStyle(Color.gray.opacity(0.5))
                .annotation(position: .overlay) {
                    Text("\(remainingComposition)%")
                        .font(smallMode! ? .caption2 : .body)
                        .foregroundStyle(.white)
                }
            }
            
            ForEach(Array(zip(composition.indices, composition.reversed())), id: \.0) { index, compositionItem in
                if compositionItem.percentage != 0 && YarnUtils.shared.getMaterial(item: compositionItem) != "" {
                    SectorMark(
                        angle: .value("Percentage", compositionItem.percentage),
                        //                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .cornerRadius(5)
                    .foregroundStyle(index <= chartColors.count ? chartColors[index] :  Color.random())
                    //                    .foregroundStyle(by: .value("Material", compositionItem.material ?? "New Material"))
                    .annotation(position: .overlay) {
                        Text("\(compositionItem.percentage)%")
                            .font(smallMode! ? .caption2 : .body)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding()
        .frame(height: smallMode! ? 150 : 200)
    }
}

struct EditComposition: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: Composition.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "materialDescription != nil")
    )
    var compositions: FetchedResults<Composition>
    
    @Binding var composition : [CompositionItem]
    
    @State var tempComposition : [CompositionItem] = []
    @State var showComposition : Bool = false
    
    init(composition: Binding<[CompositionItem]>) {
        self._composition = composition
        
        if composition.isEmpty {
            _tempComposition = State(initialValue : [CompositionItem(percentage: 0, material: "")])
        } else {
            _tempComposition = State(initialValue : composition.wrappedValue)
            _showComposition = State(initialValue : true)
        }
    }
    
    var uniqueMaterials: [String] {
        var compositionsSet = Set<String>()
        
        for composition in compositions {
            if let material = composition.material {
                compositionsSet.insert(material) // Use lowercased for case insensitivity
            }
        }
        
        return Array(compositionsSet) // Convert the set back to an array
    }
    
    // Computed property to calculate the remainingComposition
    var remainingComposition: Int {
        var remaining = 100
        
        for compositionItem in tempComposition {
            if compositionItem.percentage != 0 && compositionItem.material != "" {
                remaining -= Int(compositionItem.percentage)
            }
        }
        
        return remaining
    }
    
    // Computed property to calculate if save should be disabled
    var saveDisabled: Bool {
        let incompleteComposition = tempComposition.first { compositionItem in
            return compositionItem.percentage == 0 || YarnUtils.shared.getMaterial(item: compositionItem) == ""
        }
        
        return incompleteComposition != nil
    }
    
    var body: some View {
        Form {
            if showComposition {
                CompositionText(composition: tempComposition)
                    .transition(.slide)
                    .customFormSection()
              
            }
            
            ForEach(tempComposition.indices, id: \.self) { index in
                Section(
                    header : HStack {
                        Spacer()
                        
                        if remainingComposition != 0 && index == 0 {
                            Button {
                                withAnimation {
                                    addComposition()
                                }
                            } label: {
                                Label("", systemImage : "plus.circle").font(.title3)
                            }
                        }
                        
                        if tempComposition.count > 1 {
                            Button {
                                withAnimation {
                                    removeComposition(tempComposition[index])
                                }
                            } label: {
                                Label("", systemImage : "xmark.circle")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }
                        }
                        
                    }
                ) {
                    PercentagePicker(
                        composition: $tempComposition,
                        compositionItem: $tempComposition[index]
                    )
                    
                    NavigationLink {
                        MaterialPicker(material: $tempComposition[index].material)
                    } label: {
                        HStack {
                            Text("Material")
                            
                            Spacer()
                            
                            Text(tempComposition[index].material != "" ? tempComposition[index].material : "--")
                                .foregroundColor(.gray)
                       
                        }
                    }
                    .id(UUID())
                    
                    if tempComposition[index].material == MaterialCategory.other.rawValue {
                        TextFieldTypeahead(
                            field: $tempComposition[index].materialDescription,
                            label: "Description",
                            allResults: uniqueMaterials
                        )
                        
                    }
                }
                .onChange(of: tempComposition) {
                    if tempComposition.last?.percentage != 0 && tempComposition.last?.material != "" {
                        withAnimation {
                            showComposition = true
                        }
                    } else {
                        withAnimation {
                            showComposition = false
                        }
                    }
                    
                }
                .transition(.slide)
            }
            
            Button("Save", action: {
                composition = tempComposition
                
                dismiss()
            })
            .disabled(saveDisabled)
        }
        .navigationTitle("Composition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    composition = tempComposition
                    
                    dismiss()
                }) {
                    Image(systemName: "checkmark") // Use a system icon
                        .imageScale(.large)
                }
                .disabled(saveDisabled)
            }
        }
    }
    
    private func addComposition() {
        tempComposition.insert(CompositionItem(percentage: 0, material: ""), at: 0)
    }
    
    private func removeComposition(_ item: CompositionItem) {
        tempComposition.removeAll { $0.id == item.id }
    }
}

struct PercentagePicker: View {
    @Binding var composition : [CompositionItem]
    @Binding var compositionItem : CompositionItem
    
    // Computed property to calculate the remainingComposition
    var remainingComposition: Int {
        var remaining = 100
        
        for compositionItem in composition {
            remaining -= Int(compositionItem.percentage)
        }
        
        return remaining + compositionItem.percentage
    }
    
    var body: some View {
        CollapsibleWheelPicker(selection: $compositionItem.percentage) {
            ForEach((0..<remainingComposition + 1).reversed(), id: \.self) {
                Text("\($0) %").tag($0)
            }
            .onAppear {
                if (compositionItem.percentage == 0) {
                    compositionItem.percentage = remainingComposition
                }
            }
        } label: {
            HStack {
                Text("Percentage")
                Spacer()
                Text("\(compositionItem.percentage) %")
            }
            .foregroundStyle(Color.primary)
        }
    }
}

struct CollapsibleWheelPicker<SelectionValue, Content, Label>: View where SelectionValue: Hashable, Content: View, Label: View {
    @Binding var selection: SelectionValue
    @ViewBuilder let content: () -> Content
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        CollapsibleView(label: label) {
            Picker(selection: $selection, content: content) {
                EmptyView()
            }
            .pickerStyle(.wheel)
        }
    }
}


