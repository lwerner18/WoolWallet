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

// Dark enough for the white percentage labels drawn on each slice
let chartColors : [Color] = [
    Color(hex : "#C47A85"), // dusty rose
    Color(hex : "#7E9F78"), // sage
    Color(hex : "#5B97A3"), // teal
    Color(hex : "#9479B8"), // lavender
    Color(hex : "#C9825A"), // terracotta
    Color(hex : "#6A7FB0")  // slate blue
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
    /// Slices take on the yarn's own colors when it has any
    var yarnColors : [Color] = []
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
            
            let sliceColors = CompositionChart.sliceColors(from: yarnColors, count: composition.count)
            
            ForEach(Array(zip(composition.indices, composition.reversed())), id: \.0) { index, compositionItem in
                if compositionItem.percentage != 0 && YarnUtils.shared.getMaterial(item: compositionItem) != "" {
                    let slice = sliceColors[index]
                    
                    SectorMark(
                        angle: .value("Percentage", compositionItem.percentage),
                        //                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .cornerRadius(5)
                    .foregroundStyle(slice.color)
                    //                    .foregroundStyle(by: .value("Material", compositionItem.material ?? "New Material"))
                    .annotation(position: .overlay) {
                        Text("\(compositionItem.percentage)%")
                            .font(smallMode! ? .caption2 : .body)
                            .foregroundStyle(slice.isLight ? Color.black.opacity(0.8) : Color.white)
                    }
                }
            }
        }
        .padding()
        .frame(height: smallMode! ? 150 : 200)
    }
    
    /// One color per slice. With fewer yarn colors than slices, the colors repeat a shade lighter or darker
    /// so neighboring slices stay apart.
    static func sliceColors(from yarnColors: [Color], count: Int) -> [(color: Color, isLight: Bool)] {
        guard !yarnColors.isEmpty else {
            return (0..<count).map { (chartColors[$0 % chartColors.count], false) }
        }
        
        // Stored colors come back in no particular order, so sort them to keep each slice's color stable
        let bases = yarnColors.map { HSB(UIColor($0)) }.sorted { ($0.hue, $0.brightness) < ($1.hue, $1.brightness) }
        
        return (0..<count).map { index in
            var shade = bases[index % bases.count]
            let step = CGFloat(index / bases.count)
            
            // Pulled in from the extremes so white and black slices still show against the card
            shade.brightness = min(max(shade.brightness, 0.25), 0.9)
            shade.brightness += (shade.brightness > 0.55 ? -0.2 : 0.2) * step
            shade.brightness = min(max(shade.brightness, 0.15), 0.95)
            
            return (shade.color, shade.isLight)
        }
    }
    
    private struct HSB {
        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        
        init(_ color: UIColor) {
            var alpha : CGFloat = 0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        }
        
        var uiColor : UIColor {
            UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        }
        
        var color : Color { Color(uiColor: uiColor) }
        
        /// Light enough that white text on it would be hard to read
        var isLight : Bool {
            var red : CGFloat = 0, green : CGFloat = 0, blue : CGFloat = 0, alpha : CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            func linear(_ c: CGFloat) -> CGFloat {
                c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue) > 0.4
        }
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
    var photos : [UIImage] = []
    
    @State var tempComposition : [CompositionItem] = []
    @State var showComposition : Bool = false
    /// Renewed after returning from the material picker to clear the row's stuck highlight;
    /// a new ID on every render would rebuild the rows on each keystroke
    @State private var materialLinkID = UUID()
    
    init(composition: Binding<[CompositionItem]>, photos: [UIImage] = []) {
        self._composition = composition
        self.photos = photos
        
        if composition.isEmpty {
            _tempComposition = State(initialValue : [CompositionItem(percentage: 100, material: "")])
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
        100 - tempComposition.reduce(0) { $0 + $1.percentage }
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
                            .accessibilityLabel("Add Material")
                        }
                        
                        if tempComposition.count > 1 {
                            Button {
                                withAnimation {
                                    removeComposition(tempComposition[index])
                                }
                            } label: {
                                Label("", systemImage : "xmark.circle")
                                    .font(.title3)
                                    .foregroundStyle(Color.red)
                            }
                            .accessibilityLabel("Remove Material")
                        }
                        
                    }
                ) {
                    PercentagePicker(
                        composition: $tempComposition,
                        compositionItem: $tempComposition[index]
                    )
                    
                    NavigationLink {
                        MaterialPicker(material: $tempComposition[index].material)
                            .onDisappear { materialLinkID = UUID() }
                    } label: {
                        HStack {
                            Text("Material")
                            
                            Spacer()
                            
                            Text(tempComposition[index].material != "" ? tempComposition[index].material : "--")
                                .foregroundStyle(Color.secondary)
                       
                        }
                    }
                    .id(materialLinkID)
                    
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
        .overlay {
            if !photos.isEmpty {
                FloatingPhotoReference(images: photos, isVisible: true)
            }
        }
        .navigationTitle("Composition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    composition = tempComposition
                    
                    dismiss()
                }) {
                    Text("Done")
                }
                .disabled(saveDisabled)
            }
        }
    }
    
    private func addComposition() {
        tempComposition.insert(CompositionItem(percentage: remainingComposition, material: ""), at: 0)
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
                if compositionItem.percentage == 0 {
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


