//
//  ColorPickerView.swift
//  WoolWallet
//
//  Created by Mac on 7/20/24.
//

import Foundation
import SwiftUI
import Sweetercolor

// Define a struct to hold color names and their corresponding Color values
struct NamedColor : Identifiable, Hashable {
    let id = UUID()
    let name: String
    let colors: [UIColor]
}

let namedColors = [
    NamedColor(
        name: "Red",
        colors: [
            UIColor(hue: 0/360, saturation: 0.688, brightness: 0.649, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.706, brightness: 0.816, alpha: 1.0)


        ]
    ),
    NamedColor(
        name: "Maroon",
        colors: [
            UIColor(hue: 0/360, saturation: 0.750, brightness: 0.216, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.737, brightness: 0.309, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.644, brightness: 0.431, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.570, brightness: 0.553, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.485, brightness: 0.667, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.750, brightness: 0.314, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.707, brightness: 0.471, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Orange",
        colors: [
            UIColor(hue: 0/360, saturation: 0.711, brightness: 0.922, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.652, brightness: 0.933, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.693, brightness: 0.627, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.694, brightness: 0.792, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.694, brightness: 0.922, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.577, brightness: 0.937, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.473, brightness: 0.949, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Beige",
        colors: [
            UIColor(hue: 30/360, saturation: 0.577, brightness: 0.973, alpha: 1.0),
            UIColor(hue: 30/360, saturation: 0.469, brightness: 0.973, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.862, brightness: 0.996, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Yellow",
        colors: [
            UIColor(hue: 45/360, saturation: 0.711, brightness: 0.961, alpha: 1.0),
            UIColor(hue: 45/360, saturation: 0.654, brightness: 0.973, alpha: 1.0),
            UIColor(hue: 45/360, saturation: 0.585, brightness: 0.973, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.765, brightness: 0.949, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.841, brightness: 0.993, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.862, brightness: 0.996, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.855, brightness: 0.996, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Gold",
        colors: [
            UIColor(hue: 30/360, saturation: 0.550, brightness: 0.627, alpha: 1.0),
            UIColor(hue: 30/360, saturation: 0.650, brightness: 0.784, alpha: 1.0),
            UIColor(hue: 30/360, saturation: 0.702, brightness: 0.953, alpha: 1.0),
            UIColor(hue: 30/360, saturation: 0.630, brightness: 0.953, alpha: 1.0),
            UIColor(hue: 45/360, saturation: 0.571, brightness: 0.624, alpha: 1.0),
            UIColor(hue: 45/360, saturation: 0.577, brightness: 0.788, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Green",
        colors: [
            UIColor(hue: 60/360, saturation: 0.457, brightness: 0.439, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.445, brightness: 0.635, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.537, brightness: 0.835, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.521, brightness: 0.925, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.575, brightness: 0.937, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.525, brightness: 0.922, alpha: 1.0),
            UIColor(hue: 90/360, saturation: 0.391, brightness: 0.239, alpha: 1.0),
            UIColor(hue: 90/360, saturation: 0.460, brightness: 0.341, alpha: 1.0),
            UIColor(hue: 90/360, saturation: 0.392, brightness: 0.353, alpha: 1.0),
            UIColor(hue: 90/360, saturation: 0.447, brightness: 0.608, alpha: 1.0),
            UIColor(hue: 90/360, saturation: 0.462, brightness: 0.718, alpha: 1.0),
            UIColor(hue: 90/360, saturation: 0.477, brightness: 0.823, alpha: 1.0),
            UIColor(hue: 90/360, saturation: 0.466, brightness: 0.874, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Olive",
        colors: [
            UIColor(hue: 60/360, saturation: 0.267, brightness: 0.384, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.407, brightness: 0.549, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.440, brightness: 0.761, alpha: 1.0),
            UIColor(hue: 60/360, saturation: 0.333, brightness: 0.313, alpha: 1.0)

        ]
    ),
    NamedColor(
        name: "Teal",
        colors: [
            UIColor(hue: 197/360, saturation: 0.734, brightness: 0.282, alpha: 1.0),
            UIColor(hue: 197/360, saturation: 0.711, brightness: 0.388, alpha: 1.0),
            UIColor(hue: 197/360, saturation: 0.605, brightness: 0.549, alpha: 1.0),
            UIColor(hue: 197/360, saturation: 0.524, brightness: 0.694, alpha: 1.0),
            UIColor(hue: 197/360, saturation: 0.531, brightness: 0.827, alpha: 1.0),
            
        ]
    ),
    NamedColor(
        name: "Blue",
        colors: [
            UIColor(hue: 197/360, saturation: 0.651, brightness: 0.969, alpha: 1.0),
            UIColor(hue: 197/360, saturation: 0.603, brightness: 0.973, alpha: 1.0),
            UIColor(hue: 197/360, saturation: 0.682, brightness: 0.980, alpha: 1.0),
            UIColor(hue: 197/360, saturation: 0.738, brightness: 0.988, alpha: 1.0),
            UIColor(hue: 210/360, saturation: 0.746, brightness: 0.812, alpha: 1.0),
            UIColor(hue: 210/360, saturation: 0.764, brightness: 0.961, alpha: 1.0),
            UIColor(hue: 210/360, saturation: 0.733, brightness: 0.964, alpha: 1.0),
            UIColor(hue: 210/360, saturation: 0.676, brightness: 0.973, alpha: 1.0),
            UIColor(hue: 210/360, saturation: 0.645, brightness: 0.980, alpha: 1.0)


        ]
    ),
    NamedColor(
        name: "Navy",
        colors: [
            UIColor(hue: 210/360, saturation: 0.843, brightness: 0.329, alpha: 1.0),
            UIColor(hue: 210/360, saturation: 0.800, brightness: 0.463, alpha: 1.0),
            UIColor(hue: 210/360, saturation: 0.755, brightness: 0.635, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Purple",
        colors: [
            UIColor(hue: 240/360, saturation: 0.875, brightness: 0.216, alpha: 1.0),
            UIColor(hue: 240/360, saturation: 0.750, brightness: 0.309, alpha: 1.0),
            UIColor(hue: 240/360, saturation: 0.833, brightness: 0.447, alpha: 1.0),
            UIColor(hue: 240/360, saturation: 0.765, brightness: 0.556, alpha: 1.0),
            UIColor(hue: 240/360, saturation: 0.728, brightness: 0.670, alpha: 1.0),
            UIColor(hue: 240/360, saturation: 0.707, brightness: 0.886, alpha: 1.0),
            UIColor(hue: 240/360, saturation: 0.661, brightness: 0.961, alpha: 1.0),
            UIColor(hue: 240/360, saturation: 0.575, brightness: 0.973, alpha: 1.0),
            UIColor(hue: 240/360, saturation: 0.591, brightness: 0.980, alpha: 1.0),
            UIColor(hue: 300/360, saturation: 0.750, brightness: 0.145, alpha: 1.0),
            UIColor(hue: 300/360, saturation: 0.759, brightness: 0.247, alpha: 1.0),
            UIColor(hue: 300/360, saturation: 0.699, brightness: 0.478, alpha: 1.0),
            UIColor(hue: 300/360, saturation: 0.670, brightness: 0.596, alpha: 1.0),
            UIColor(hue: 300/360, saturation: 0.645, brightness: 0.733, alpha: 1.0)

        ]
    ),
    NamedColor(
        name: "Pink",
        colors: [
            UIColor(hue: 300/360, saturation: 0.734, brightness: 0.925, alpha: 1.0),
            UIColor(hue: 300/360, saturation: 0.651, brightness: 0.964, alpha: 1.0),
            UIColor(hue: 300/360, saturation: 0.607, brightness: 0.973, alpha: 1.0),
            UIColor(hue: 300/360, saturation: 0.533, brightness: 0.980, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.687, brightness: 0.831, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.562, brightness: 0.878, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.537, brightness: 0.914, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.553, brightness: 0.949, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.417, brightness: 0.961, alpha: 1.0)

        ]
    ),
    NamedColor(
        name: "Brown",
        colors: [
            UIColor(hue: 0/360, saturation: 0.750, brightness: 0.188, alpha: 1.0),
            UIColor(hue: 0/360, saturation: 0.727, brightness: 0.447, alpha: 1.0),
            UIColor(hue: 30/360, saturation: 0.750, brightness: 0.188, alpha: 1.0),
            UIColor(hue: 30/360, saturation: 0.659, brightness: 0.451, alpha: 1.0),
            UIColor(hue: 45/360, saturation: 0.586, brightness: 0.188, alpha: 1.0),
            UIColor(hue: 45/360, saturation: 0.593, brightness: 0.451, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Black",
        colors: [
            UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "White",
        colors: [
            UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 1.0)
        ]
    ),
    NamedColor(
        name: "Gray",
        colors: [
            UIColor(hue: 0, saturation: 0, brightness: 0.75, alpha: 1.0),
            UIColor(hue: 0, saturation: 0, brightness: 0.5, alpha: 1.0),
            UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1.0)
        ]
    )
]

struct SquareColorPickerView: View {
    
    @Binding var colorValue: Color
    
    var body: some View {
        
        colorValue
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .clipShape(
                .rect(
                    topLeadingRadius: 10,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 10
                )
            )
            .overlay(
                ColorPicker("", selection: $colorValue)
                    .labelsHidden()
                    .opacity(0.015)
                    .scaleEffect(CGSize(width: 300, height: 35))
            )
        
    }
}

struct ColorPickerItem: Identifiable, Equatable {
    var id           : UUID = UUID()
    var color        : Color
    var name         : String
    var existingItem : StoredColor? = nil
}

struct ColorPickerView: View {
    @Binding var colorPickerItem: ColorPickerItem
    var removeAction: () -> Void
    var addAction: () -> Void
    var displayAddButton: Bool
    var canRemove: Bool
    
    
    var body: some View {
        Section(
            header : HStack {
                Text("Color")
                
                Spacer()
                
                if displayAddButton {
                    Button(action : addAction) {
                        Label("", systemImage : "plus.circle").font(.title3)
                    }
                }
                
                if canRemove {
                    Button(action : removeAction) {
                        Label("", systemImage : "xmark.circle")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
                
            }
        ) {
            SquareColorPickerView(colorValue: $colorPickerItem.color)
                .listRowInsets(EdgeInsets())
                .background(Color(UIColor.systemGroupedBackground))
                .onChange(of: colorPickerItem.color) {
                    // Update the closest color name when the color changes
                    updateClosestColorName(with: UIColor(colorPickerItem.color))
                }
                .onAppear {
                    if colorPickerItem.name == "" {
                        updateClosestColorName(with: UIColor(colorPickerItem.color))
                    }
                }
            
            if colorPickerItem.name != "" {
                Picker("Color", selection: $colorPickerItem.name) {
                    ForEach(namedColors, id: \.name) { color in
                        Text(color.name).tag(color.name)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
    }
    
    private func updateClosestColorName(with color: UIColor) {
        DispatchQueue.global(qos: .background).async {
            
            var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude
            var closestColor: String? = nil
            
            for namedColor in namedColors {
                var totalDistance = 0.0
                
                for colorBenchmark in namedColor.colors {
                    totalDistance += colorBenchmark.CIEDE2000(compare: color)
                }
                
                let averageDistance = totalDistance / Double(namedColor.colors.count)
                
                print("Color", namedColor.name, "Average Distance", averageDistance)
                
                if averageDistance < minDistance {
                    minDistance = averageDistance
                    closestColor = namedColor.name
                }
            }
            
            DispatchQueue.main.async { // Ensure UI updates are performed on the main thread
                self.colorPickerItem.name = closestColor!
            }
        }
        
    }
}

class ColorPickerItemWrapper: ObservableObject, Identifiable {
    @Published var color: Color
    
    init(item: ColorPickerItem) {
        self.color = item.color
    }
}
