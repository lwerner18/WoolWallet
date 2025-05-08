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
    
    @State var sliderPosition: ClosedRange<Float> = 0...3000
    
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
                        
//                        Text("Length").bold().padding(.top, 10).padding(.bottom, 20)
//                        
//                        RangedSliderView(value: $sliderPosition, bounds: 0...3000)
//                            .padding(.vertical, 20)
//                            .padding(.horizontal, 22)
                        
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
                                        if !colorFilter.namedColor!.colors.isEmpty {
                                            // Diamond-shaped color view
                                            Circle()
                                                .fill(Color(uiColor : colorFilter.namedColor!.colors[0]))
                                                .frame(width: 18, height: 18)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.black, lineWidth: 0.25) // Black border with width
                                                )
                                        }
                                        
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

struct RangedSliderView: View {
    let currentValue: Binding<ClosedRange<Float>>
    let sliderBounds: ClosedRange<Int>
    
    public init(value: Binding<ClosedRange<Float>>, bounds: ClosedRange<Int>) {
        self.currentValue = value
        self.sliderBounds = bounds
    }
    
    var body: some View {
        GeometryReader { geomentry in
            sliderView(sliderSize: geomentry.size)
        }
    }
    
    
    @ViewBuilder private func sliderView(sliderSize: CGSize) -> some View {
        let sliderViewYCenter = sliderSize.height / 2
        
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.primary)
                .frame(height: 4)
            ZStack {
                let sliderBoundDifference = sliderBounds.count
                let stepWidthInPixel = CGFloat(sliderSize.width) / CGFloat(sliderBoundDifference)
                
                // Calculate Left Thumb initial position
                let leftThumbLocation: CGFloat = currentValue.wrappedValue.lowerBound == Float(sliderBounds.lowerBound)
                ? 0
                : CGFloat(currentValue.wrappedValue.lowerBound - Float(sliderBounds.lowerBound)) * stepWidthInPixel
                
                // Calculate right thumb initial position
                let rightThumbLocation = CGFloat(currentValue.wrappedValue.upperBound) * stepWidthInPixel
                
                // Path between both handles
                lineBetweenThumbs(from: .init(x: leftThumbLocation, y: sliderViewYCenter), to: .init(x: rightThumbLocation, y: sliderViewYCenter))
                
                // Left Thumb Handle
                let leftThumbPoint = CGPoint(x: leftThumbLocation, y: sliderViewYCenter)
                thumbView(position: leftThumbPoint, value: Float(currentValue.wrappedValue.lowerBound))
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(0, dragLocation.x), sliderSize.width)
                        
                        let newValue = Float(sliderBounds.lowerBound) + Float(xThumbOffset / stepWidthInPixel)
                        
                        // Stop the range thumbs from colliding each other
                        if newValue < currentValue.wrappedValue.upperBound {
                            currentValue.wrappedValue = newValue...currentValue.wrappedValue.upperBound
                        }
                    })
                
                // Right Thumb Handle
                thumbView(position: CGPoint(x: rightThumbLocation, y: sliderViewYCenter), value: currentValue.wrappedValue.upperBound)
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(CGFloat(leftThumbLocation), dragLocation.x), sliderSize.width)
                        
                        var newValue = Float(xThumbOffset / stepWidthInPixel) // convert back the value bound
                        newValue = min(newValue, Float(sliderBounds.upperBound))
                        
                        // Stop the range thumbs from colliding each other
                        if newValue > currentValue.wrappedValue.lowerBound {
                            currentValue.wrappedValue = currentValue.wrappedValue.lowerBound...newValue
                        }
                    })
            }
        }
    }
    
    @ViewBuilder func lineBetweenThumbs(from: CGPoint, to: CGPoint) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }.stroke(Color.accentColor, lineWidth: 4)
    }
    
    @ViewBuilder func thumbView(position: CGPoint, value: Float) -> some View {
        ZStack {
            Text("\(Double(value).formatted) yards")
                .font(.footnote)
                .offset(y: -20)
                .padding(.bottom, 20)
            Circle()
                .frame(width: 24, height: 24)
                .foregroundColor(.primary)
                .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 2)
                .contentShape(Rectangle())
        }
        .position(x: position.x, y: position.y)
    }
}
