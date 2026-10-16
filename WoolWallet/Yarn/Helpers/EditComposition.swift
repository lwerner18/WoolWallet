//
//  EditComposition.swift
//  WoolWallet
//
//  Created by Mac on 9/22/24.
//

import Foundation
import SwiftUI

struct CompositionItem : Identifiable, Hashable {
    var id = UUID()
    var percentage: Int
    var material: String
    var materialDescription : String = ""
    var existingItem : Composition? = nil
}

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
    
    private var lines: [String] {
        composition
            .sorted { $0.percentage > $1.percentage }
            .compactMap { item in
                let material = YarnUtils.shared.getMaterial(item: item)
                guard item.percentage != 0, !material.isEmpty else { return nil }
                return "\(item.percentage)% \(material)"
            }
    }
    
    var body: some View {
        Text(lines.joined(separator: " · "))
            .font(.subheadline)
            .foregroundStyle(Color.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Stacked horizontal bar of fiber percentages
struct CompositionChart : View {
    var composition : [CompositionItem]
    /// Segments take on the yarn's own colors when it has any
    var yarnColors : [Color] = []
    var smallMode : Bool = false
    
    private var remainingComposition: Int {
        var remaining = 100
        
        for compositionItem in composition {
            if compositionItem.percentage != 0 && compositionItem.material != "" {
                remaining -= Int(compositionItem.percentage)
            }
        }
        
        return remaining
    }
    
    private var filledItems: [CompositionItem] {
        composition
            .filter { $0.percentage != 0 && YarnUtils.shared.getMaterial(item: $0) != "" }
            .sorted { $0.percentage > $1.percentage }
    }
    
    private var segments: [(id: UUID, percentage: Int, color: Color)] {
        let colors = CompositionChart.segmentColors(from: yarnColors, count: max(filledItems.count, 1))
        var result = filledItems.enumerated().map { index, item in
            (id: item.id, percentage: item.percentage, color: colors[index])
        }
        
        if remainingComposition > 0 {
            result.append((
                id: CompositionChart.remainingID,
                percentage: remainingComposition,
                color: Color.gray.opacity(0.35)
            ))
        }
        
        return result
    }
    
    private static let remainingID = UUID()
    
    var body: some View {
        let segments = segments
        let spacing : CGFloat = smallMode ? 1.5 : 2
        let barHeight : CGFloat = smallMode ? 12 : 16
        
        Group {
            if segments.isEmpty {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: barHeight)
            } else {
                GeometryReader { proxy in
                    let totalSpacing = spacing * CGFloat(max(segments.count - 1, 0))
                    let usable = max(proxy.size.width - totalSpacing, 0)
                    
                    HStack(spacing: spacing) {
                        ForEach(segments, id: \.id) { segment in
                            Capsule()
                                .fill(segment.color)
                                .frame(width: usable * CGFloat(segment.percentage) / 100)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(height: barHeight)
            }
        }
        .padding(.vertical, smallMode ? 2 : 4)
        .accessibilityElement()
        .accessibilityLabel(accessibilitySummary)
    }
    
    private var accessibilitySummary: String {
        let parts = filledItems.map {
            "\($0.percentage)% \(YarnUtils.shared.getMaterial(item: $0))"
        }
        if remainingComposition > 0 {
            return (parts + ["\(remainingComposition)% unassigned"]).joined(separator: ", ")
        }
        return parts.isEmpty ? "Composition" : parts.joined(separator: ", ")
    }
    
    /// One color per segment. With fewer yarn colors than segments, the colors repeat a shade lighter or darker
    /// so neighbors stay apart.
    static func segmentColors(from yarnColors: [Color], count: Int) -> [Color] {
        guard !yarnColors.isEmpty else {
            return (0..<count).map { chartColors[$0 % chartColors.count] }
        }
        
        // Stored colors come back in no particular order, so sort them to keep each segment's color stable
        let bases = yarnColors.map { HSB(UIColor($0)) }.sorted { ($0.hue, $0.brightness) < ($1.hue, $1.brightness) }
        
        return (0..<count).map { index in
            var shade = bases[index % bases.count]
            let step = CGFloat(index / bases.count)
            
            // Pulled in from the extremes so white and black segments still show against the card
            shade.brightness = min(max(shade.brightness, 0.25), 0.9)
            shade.brightness += (shade.brightness > 0.55 ? -0.2 : 0.2) * step
            shade.brightness = min(max(shade.brightness, 0.15), 0.95)
            
            return shade.color
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
        
        var color : Color {
            Color(uiColor: UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1))
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
    /// When set, the preview chart uses the yarn's colors instead of the default palette
    var yarnColors : [Color] = []
    
    @State var tempComposition : [CompositionItem] = []
    /// Renewed after returning from the material picker to clear the row's stuck highlight;
    /// a new ID on every render would rebuild the rows on each keystroke
    @State private var materialLinkID = UUID()
    
    init(
        composition: Binding<[CompositionItem]>,
        photos: [UIImage] = [],
        yarnColors: [Color] = []
    ) {
        self._composition = composition
        self.photos = photos
        self.yarnColors = yarnColors
        
        if composition.isEmpty {
            _tempComposition = State(initialValue: [CompositionItem(percentage: 100, material: "")])
        } else {
            _tempComposition = State(initialValue: composition.wrappedValue)
        }
    }
    
    var uniqueMaterials: [String] {
        var compositionsSet = Set<String>()
        
        for composition in compositions {
            if let material = composition.material {
                compositionsSet.insert(material)
            }
        }
        
        return Array(compositionsSet)
    }
    
    var remainingComposition: Int {
        100 - tempComposition.reduce(0) { $0 + $1.percentage }
    }
    
    private var hasCompleteFiber: Bool {
        tempComposition.contains {
            $0.percentage > 0 && YarnUtils.shared.getMaterial(item: $0) != ""
        }
    }
    
    var saveDisabled: Bool {
        tempComposition.contains {
            $0.percentage == 0 || YarnUtils.shared.getMaterial(item: $0) == ""
        }
    }
    
    private var saveHintText: String {
        if saveDisabled {
            return "Give each fiber a percentage and a material."
        }
        if remainingComposition > 0 {
            return "\(remainingComposition)% left unassigned — you can still save, or add another fiber."
        }
        return ""
    }
    
    var body: some View {
        Form {
            if hasCompleteFiber {
                previewSection
            }
            
            ForEach(tempComposition.indices, id: \.self) { index in
                fiberSection(at: index)
                    .transition(.slide)
            }
            
            if remainingComposition > 0 {
                addFiberSection
            }
            
            if !saveHintText.isEmpty {
                Section {
                    Label(saveHintText, systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
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
                Button("Done", action: save)
                    .disabled(saveDisabled)
            }
        }
    }
    
    private var previewSection: some View {
        Section {
            VStack(spacing: 10) {
                CompositionChart(
                    composition: tempComposition,
                    yarnColors: yarnColors
                )
                
                CompositionText(composition: tempComposition)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .customFormSection()
        } header: {
            Text("Preview")
        } footer: {
            if remainingComposition > 0 {
                Text("Gray is the \(remainingComposition)% still unassigned.")
            }
        }
    }
    
    private func fiberSection(at index: Int) -> some View {
        Section {
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
                    
                    Text(tempComposition[index].material.isEmpty ? "Choose…" : tempComposition[index].material)
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
        } header: {
            HStack {
                Text(tempComposition.count > 1 ? "Fiber \(index + 1)" : "Fiber")
                
                Spacer()
                
                if tempComposition.count > 1 {
                    Button(role: .destructive) {
                        withAnimation {
                            removeComposition(tempComposition[index])
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(UIColor.tertiaryLabel))
                    }
                    .accessibilityLabel("Remove Fiber \(index + 1)")
                }
            }
        }
    }
    
    private var addFiberSection: some View {
        Section {
            Button {
                withAnimation {
                    addComposition()
                }
            } label: {
                Label("Add Fiber", systemImage: "plus.circle")
            }
        } footer: {
            Text("\(remainingComposition)% left to assign.")
        }
    }
    
    private func save() {
        composition = tempComposition
        dismiss()
    }
    
    private func addComposition() {
        tempComposition.append(CompositionItem(percentage: remainingComposition, material: ""))
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


