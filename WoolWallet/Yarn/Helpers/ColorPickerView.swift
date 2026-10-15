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

let namedColors : [NamedColor] = ColorNaming.references.map { reference in
    NamedColor(name: reference.name, colors: reference.hexes.map { UIColor(Color(hex: $0)) })
} + [
    NamedColor(name: "Multicolored", colors: []),
    NamedColor(name: "Other", colors: [])
]

/// Replaces the system color picker, whose eyedropper can't be hidden and can only sample what's on screen
struct YarnColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var photos : [UIImage]
    var onDone : (Color) -> Void
    
    @State private var hue : Double
    @State private var saturation : Double
    @State private var brightness : Double
    @State private var showPhotoSampler = false
    
    init(color: Color, photos: [UIImage], onDone: @escaping (Color) -> Void) {
        self.photos = photos
        self.onDone = onDone
        
        var hue : CGFloat = 0, saturation : CGFloat = 0, brightness : CGFloat = 0, alpha : CGFloat = 0
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        _hue = State(initialValue: min(max(hue, 0), 1))
        _saturation = State(initialValue: min(max(saturation, 0), 1))
        _brightness = State(initialValue: min(max(brightness, 0), 1))
    }
    
    private var color : Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color)
                        .frame(height: 90)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1)))
                        .accessibilityHidden(true)
                    
                    if !photos.isEmpty {
                        Button {
                            showPhotoSampler = true
                        } label: {
                            Label("Pick from Photo", systemImage: "eyedropper")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    palette
                    
                    VStack(spacing: 16) {
                        GradientSlider(
                            title: "Hue",
                            value: $hue,
                            colors: stride(from: 0.0, through: 1.0, by: 1.0 / 12).map { Color(hue: $0, saturation: 1, brightness: 1) },
                            thumbColor: Color(hue: hue, saturation: 1, brightness: 1)
                        )
                        
                        GradientSlider(
                            title: "Saturation",
                            value: $saturation,
                            colors: [
                                Color(hue: hue, saturation: 0, brightness: brightness),
                                Color(hue: hue, saturation: 1, brightness: brightness)
                            ],
                            thumbColor: color
                        )
                        
                        GradientSlider(
                            title: "Brightness",
                            value: $brightness,
                            colors: [Color.black, Color(hue: hue, saturation: saturation, brightness: 1)],
                            thumbColor: color
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(color)
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showPhotoSampler) {
                PhotoColorSampler(images: photos) { picked in
                    var pickedHue : CGFloat = 0, pickedSaturation : CGFloat = 0, pickedBrightness : CGFloat = 0, alpha : CGFloat = 0
                    UIColor(picked).getHue(&pickedHue, saturation: &pickedSaturation, brightness: &pickedBrightness, alpha: &alpha)
                    
                    hue = min(max(pickedHue, 0), 1)
                    saturation = min(max(pickedSaturation, 0), 1)
                    brightness = min(max(pickedBrightness, 0), 1)
                }
            }
        }
    }
    
    private var palette: some View {
        VStack(spacing: 0) {
            ForEach(PaletteSwatch.rows.indices, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(PaletteSwatch.rows[row]) { swatch in
                        let isSelected = swatch.matches(hue: hue, saturation: saturation, brightness: brightness)
                        
                        Button {
                            hue = swatch.hue
                            saturation = swatch.saturation
                            brightness = swatch.brightness
                        } label: {
                            Rectangle()
                                .fill(swatch.color)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    if isSelected {
                                        Rectangle().stroke(Color.white, lineWidth: 3)
                                        Rectangle().stroke(Color.black, lineWidth: 1)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(swatch.name)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1)))
    }
}

private struct PaletteSwatch: Identifiable {
    let id = UUID()
    let hue : Double
    let saturation : Double
    let brightness : Double
    let name : String
    
    var color : Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    func matches(hue: Double, saturation: Double, brightness: Double) -> Bool {
        let tolerance = 0.005
        // Hue means nothing for grays
        let hueMatches = self.saturation == 0 || abs(self.hue - hue) < tolerance
        return hueMatches && abs(self.saturation - saturation) < tolerance && abs(self.brightness - brightness) < tolerance
    }
    
    private static let hueNames = ["Red", "Orange", "Yellow", "Lime", "Green", "Mint", "Cyan", "Azure", "Blue", "Violet", "Magenta", "Rose"]
    
    /// Twelve hues from pale to dark, with a row of grays on top, like the system color grid
    static let rows : [[PaletteSwatch]] = {
        let grays = (0..<12).map { step in
            let brightness = 1 - Double(step) / 11
            return PaletteSwatch(hue: 0, saturation: 0, brightness: brightness, name: "Gray, \(Int((brightness * 100).rounded()))% brightness")
        }
        
        let levels : [(name: String, saturation: Double, brightness: Double)] = [
            ("Palest", 0.2, 1),
            ("Pale", 0.4, 1),
            ("Light", 0.65, 1),
            ("Bright", 0.9, 0.95),
            ("Rich", 1, 0.8),
            ("Deep", 1, 0.6),
            ("Dark", 0.9, 0.4),
            ("Darkest", 0.6, 0.25)
        ]
        
        let colors = levels.map { level in
            hueNames.indices.map { index in
                PaletteSwatch(
                    hue: Double(index) / Double(hueNames.count),
                    saturation: level.saturation,
                    brightness: level.brightness,
                    name: "\(level.name) \(hueNames[index])"
                )
            }
        }
        
        return [grays] + colors
    }()
}

private struct GradientSlider: View {
    let title : String
    @Binding var value : Double
    let colors : [Color]
    let thumbColor : Color
    
    private let thumbSize : CGFloat = 28
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.secondary)
            
            GeometryReader { proxy in
                let travel = max(proxy.size.width - thumbSize, 1)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                        .overlay(Capsule().stroke(Color.primary.opacity(0.1)))
                    
                    Circle()
                        .fill(thumbColor)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(radius: 2)
                        .offset(x: value * travel)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            value = min(max((drag.location.x - thumbSize / 2) / travel, 0), 1)
                        }
                )
            }
            .frame(height: thumbSize)
        }
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 0.05, 1)
            case .decrement: value = max(value - 0.05, 0)
            @unknown default: break
            }
        }
    }
}

struct ColorPickerItem: Identifiable, Equatable {
    var id           : UUID = UUID()
    var color        : Color
    var name         : String
    var description  : String = ""
    var existingItem : StoredColor? = nil
}

/// A yarn color on a single line: tap the swatch to open the picker, or the name to choose a different one
struct ColorRow: View {
    @Binding var item : ColorPickerItem
    var photos : [UIImage] = []
    var onRemove : () -> Void
    
    @State private var showPicker = false
    @State private var showPhotoSampler = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                showPicker = true
            } label: {
                Circle()
                    .fill(item.color)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Change Color")
            .accessibilityValue(item.description.isEmpty ? item.name : item.description)
            
            VStack(alignment: .leading, spacing: 4) {
                nameMenu
                
                if item.name == "Other" {
                    TextField("Describe the color", text: $item.description)
                        .font(.subheadline)
                } else if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer(minLength: 0)
            
            if !photos.isEmpty {
                Button {
                    showPhotoSampler = true
                } label: {
                    Image(systemName: "eyedropper")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Pick Color from Photo")
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove Color")
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showPicker) {
            YarnColorPickerSheet(color: item.color, photos: photos) { newColor in
                item.color = newColor
            }
        }
        .fullScreenCover(isPresented: $showPhotoSampler) {
            PhotoColorSampler(images: photos) { color in
                item.color = color
            }
        }
        .onChange(of: item.color) {
            updateClosestColorName()
        }
        .onChange(of: item.name) {
            item.description = ""
        }
        .onAppear {
            if item.name.isEmpty {
                updateClosestColorName()
            }
        }
    }
    
    private var nameMenu: some View {
        Menu {
            Picker("Color Name", selection: $item.name) {
                ForEach(namedColors, id: \.name) { color in
                    Text(color.name).tag(color.name)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(item.name.isEmpty ? "Choose Name" : item.name)
                    .foregroundStyle(Color.primary)
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
        }
        .accessibilityLabel("Color Name")
        .accessibilityValue(item.name)
    }
    
    private func updateClosestColorName() {
        if let closestName = ColorNaming.closestName(to: UIColor(item.color)) {
            item.name = closestName
        }
    }
}

/// Full-screen eyedropper for the yarn's photos
struct PhotoColorSampler: View {
    @Environment(\.dismiss) private var dismiss
    
    let images : [UIImage]
    var onPick : (Color) -> Void
    
    @State private var imageIndex = 0
    @State private var pixels : PhotoPixels? = nil
    /// Position within the photo, from 0 to 1 on each axis
    @State private var point = CGPoint(x: 0.5, y: 0.5)
    @State private var color : Color? = nil
    @State private var isDragging = false
    
    private let loupeSize : CGFloat = 120
    private let loupeZoom : CGFloat = 4
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
            }
            .padding()
            
            GeometryReader { proxy in
                sampler(image: images[imageIndex], in: proxy.size)
            }
            
            bottomBar
        }
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
        .task(id: imageIndex) {
            let image = images[imageIndex]
            pixels = nil
            color = nil
            point = CGPoint(x: 0.5, y: 0.5)
            pixels = await Task.detached(priority: .userInitiated) { PhotoPixels(image: image) }.value
            color = pixels?.color(at: point)
        }
    }
    
    private func sampler(image: UIImage, in container: CGSize) -> some View {
        let fitted = fittedSize(image.size, in: container)
        let origin = CGPoint(x: (container.width - fitted.width) / 2, y: (container.height - fitted.height) / 2)
        let target = CGPoint(x: origin.x + point.x * fitted.width, y: origin.y + point.y * fitted.height)
        // Keep the loupe above the finger unless that would push it off the top
        let loupeAbove = target.y - loupeSize - 40 > 0
        
        return ZStack {
            Image(uiImage: image)
                .resizable()
                .frame(width: fitted.width, height: fitted.height)
                .position(x: container.width / 2, y: container.height / 2)
            
            Circle()
                .fill(color ?? Color.clear)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(radius: 2)
                .position(target)
            
            if isDragging {
                loupe(image: image, fitted: fitted)
                    .position(x: target.x, y: loupeAbove ? target.y - loupeSize / 2 - 40 : target.y + loupeSize / 2 + 40)
            }
        }
        .frame(width: container.width, height: container.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard fitted.width > 0, fitted.height > 0 else { return }
                    
                    isDragging = true
                    point = CGPoint(
                        x: min(max((value.location.x - origin.x) / fitted.width, 0), 1),
                        y: min(max((value.location.y - origin.y) / fitted.height, 0), 1)
                    )
                    color = pixels?.color(at: point) ?? color
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Photo")
        .accessibilityHint("Drag on the photo to pick a color")
    }
    
    private func loupe(image: UIImage, fitted: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: fitted.width * loupeZoom, height: fitted.height * loupeZoom)
            .offset(
                x: loupeSize / 2 - point.x * fitted.width * loupeZoom,
                y: loupeSize / 2 - point.y * fitted.height * loupeZoom
            )
            .frame(width: loupeSize, height: loupeSize, alignment: .topLeading)
            .background(Color.black)
            .clipShape(Circle())
            .overlay(Circle().stroke(color ?? Color.white, lineWidth: 6))
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: 10, height: 10)
            )
            .shadow(radius: 6)
            .allowsHitTesting(false)
    }
    
    private var bottomBar: some View {
        VStack(spacing: 16) {
            if images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(images.indices, id: \.self) { index in
                            Button {
                                imageIndex = index
                            } label: {
                                Image(uiImage: images[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(index == imageIndex ? Color.white : Color.clear, lineWidth: 2)
                                    )
                            }
                            .accessibilityLabel("Photo \(index + 1) of \(images.count)")
                            .accessibilityAddTraits(index == imageIndex ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            HStack(spacing: 12) {
                Circle()
                    .fill(color ?? Color.clear)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                    .accessibilityHidden(true)
                
                Text("Drag on the photo to pick a color")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                
                Spacer()
                
                Button("Use Color") {
                    if let color {
                        onPick(color)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(color == nil)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private func fittedSize(_ size: CGSize, in container: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }
        
        let scale = min(container.width / size.width, container.height / size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}

/// A downsized RGBA copy of a photo so colors can be read while dragging
private struct PhotoPixels {
    let width : Int
    let height : Int
    let data : [UInt8]
    
    init?(image: UIImage, maxDimension: CGFloat = 1200) {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height, 1))
        let width = max(1, Int((image.size.width * scale).rounded()))
        let height = max(1, Int((image.size.height * scale).rounded()))
        var data = [UInt8](repeating: 0, count: width * height * 4)
        
        let drawn = data.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            
            // UIImage drawing applies the photo's orientation but expects a top-left origin
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            UIGraphicsPushContext(context)
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            UIGraphicsPopContext()
            return true
        }
        
        guard drawn else { return nil }
        
        self.width = width
        self.height = height
        self.data = data
    }
    
    /// Averages a small patch so a single stray fiber or bit of noise doesn't decide the color
    func color(at point: CGPoint, radius: Int = 2) -> Color {
        let centerX = min(max(Int(point.x * CGFloat(width)), 0), width - 1)
        let centerY = min(max(Int(point.y * CGFloat(height)), 0), height - 1)
        var red = 0, green = 0, blue = 0, count = 0
        
        for y in max(centerY - radius, 0)...min(centerY + radius, height - 1) {
            for x in max(centerX - radius, 0)...min(centerX + radius, width - 1) {
                let offset = (y * width + x) * 4
                red += Int(data[offset])
                green += Int(data[offset + 1])
                blue += Int(data[offset + 2])
                count += 1
            }
        }
        
        return Color(
            .sRGB,
            red: Double(red) / Double(count * 255),
            green: Double(green) / Double(count * 255),
            blue: Double(blue) / Double(count * 255)
        )
    }
}

class ColorPickerItemWrapper: ObservableObject, Identifiable {
    @Published var color: Color
    
    init(item: ColorPickerItem) {
        self.color = item.color
    }
}
