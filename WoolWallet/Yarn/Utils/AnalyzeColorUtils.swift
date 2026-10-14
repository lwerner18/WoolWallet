//
//  AnalyzeColorUtils.swift
//  WoolWallet
//
//  Created by Mac on 7/20/24.
//

import Foundation
import CoreML
import Vision
import SwiftUI
import Sweetercolor

enum AnalyzeColorError: Error {
    case unknownError
}

class AnalyzeColorUtils {
    static let shared = AnalyzeColorUtils()
    
    // Loaded once; `shared` is created lazily and thread-safely on first use
    private let segmentationModel: VNCoreMLModel? = {
        guard let modelURL = Bundle.main.url(forResource: "yarn_segmentation_model", withExtension: "mlmodelc"),
              let coreMLModel = try? MLModel(contentsOf: modelURL) else {
            return nil
        }
        return try? VNCoreMLModel(for: coreMLModel)
    }()
    
    private init() {}
    
    /// Always calls `completion` exactly once, with nil on any failure.
    func classifyImageWithModel(image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let segmentationModel else {
            print("Failed to load Core ML model")
            completion(nil)
            return
        }
        
        let request = VNCoreMLRequest(model: segmentationModel) { (request, error) in
            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let multiArray = results.first?.featureValue.multiArrayValue else {
                print("Failed to obtain multi-array results:", error?.localizedDescription ?? "unknown error")
                completion(nil)
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                completion(self.mlMultiArrayToUIImage(multiArray, originalImage: image))
            }
        }
        
        let resizedImage = image.resize(to: CGSize(width: 256, height: 256))
        
        guard let cgImage = resizedImage?.cgImage else {
            print("Failed to get CGImage from input image")
            completion(nil)
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform classification.\n\(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func mlMultiArrayToUIImage(_ mlMultiArray: MLMultiArray, originalImage : UIImage) -> UIImage? {
        // Ensure the MLMultiArray is of the expected shape and type.
        guard mlMultiArray.shape.count == 4,
              mlMultiArray.shape[0].intValue == 1,
              mlMultiArray.shape[3].intValue == 1,
              let height = mlMultiArray.shape[1] as? Int,
              let width = mlMultiArray.shape[2] as? Int else {
            return nil
        }
        
        let bufferSize = width * height
        let pixelData = mlMultiArray.dataPointer.bindMemory(to: Float32.self, capacity: bufferSize)
        
        // Find min and max values to normalize pixel values between 0 and 1.
        var minValue: Float = Float.greatestFiniteMagnitude
        var maxValue: Float = -Float.greatestFiniteMagnitude
        for i in 0..<bufferSize {
            minValue = min(minValue, pixelData[i])
            maxValue = max(maxValue, pixelData[i])
        }
        let range = maxValue - minValue
        
        
        // Create a grayscale context
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        
        let neighborhoodRadius = 1 // Define the radius of the neighborhood
        
        // Fill the context with pixel data
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * width + x
                let pixelValue = pixelData[pixelIndex]
                let normalizedPixelValue = range > 0 ? (pixelValue - minValue) / range : 0 // Normalize pixel value to [0, 1]
                
                let roundedPixelValue = normalizedPixelValue < 0.86 ? 0 : 1
                
                var isSurroundedByWhite = true
                
                // Check the surrounding pixels within the defined neighborhood radius
                for dy in -neighborhoodRadius...neighborhoodRadius {
                    for dx in -neighborhoodRadius...neighborhoodRadius {
                        let nx = x + dx
                        let ny = y + dy
                        
                        // Ensure the neighboring coordinates are within bounds
                        if nx >= 0 && nx < width && ny >= 0 && ny < height {
                            let neighborPixelIndex = ny * width + nx
                            let neighborPixelValue = pixelData[neighborPixelIndex]
                            
                            let normalizedNeighborPixelValue = range > 0 ? (neighborPixelValue - minValue) / range : 0 // Normalize pixel value to [0, 1]
                            
                            let roundedNeighborPixelValue = normalizedNeighborPixelValue < 0.86 ? 0 : 1
                            
                            // Check if the neighbor pixel is white
                            if roundedNeighborPixelValue == 0 { // Assuming 255 is the value for white
                                isSurroundedByWhite = false
                                break
                            }
                        }
                    }
                    if !isSurroundedByWhite {
                        break
                    }
                }
                
                if isSurroundedByWhite || roundedPixelValue == 1 {
                    context.setFillColor(gray: CGFloat(roundedPixelValue), alpha: 1.0)
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        
        // Create a UIImage from the context
        guard let cgImage = context.makeImage() else { return nil }
        
        let result = UIImage(cgImage: cgImage)
        
        let targetSize = originalImage.size
        let format = Self.bitmapFormat(scale: result.scale)
        
        let resizedImage = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            result.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        let flippedImage = UIGraphicsImageRenderer(size: resizedImage.size, format: format).image { rendererContext in
            let flipContext = rendererContext.cgContext
            
            // Move the origin to the middle of the image so we will rotate and scale around the center.
            flipContext.translateBy(x: resizedImage.size.width, y: 0)
            flipContext.scaleBy(x: -1.0, y: 1.0) // Flip horizontal
            
            // Draw the original image into the transformed context
            resizedImage.draw(at: CGPoint.zero)
        }
        
        // Setup the context with the swapped dimensions for 90-degree rotation
        let rotatedSize = CGSize(width: flippedImage.size.height, height: flippedImage.size.width)
        let rotatedImage = UIGraphicsImageRenderer(size: rotatedSize, format: format).image { rendererContext in
            let rotateContext = rendererContext.cgContext
            
            // Move the origin to the new bottom left (originally top left)
            rotateContext.translateBy(x: flippedImage.size.height, y: 0)
            rotateContext.rotate(by: CGFloat.pi / 2)  // 90 degrees clockwise rotation
            
            // Draw the image onto the transformed context
            flippedImage.draw(at: CGPoint(x: 0, y: 0))
        }
        
        return rotatedImage
    }
    
    /// `yarnColors` reads the mask as 4 bytes per pixel, so wide-color (16-bit) rendering must be avoided.
    private static func bitmapFormat(scale: CGFloat) -> UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        format.preferredRange = .standard
        return format
    }
    
    func yarnColors(from colorImage: UIImage, with maskImage: UIImage) throws -> [Color] {
        guard let colorCGImage = colorImage.cgImage,
              let maskCGImage = maskImage.cgImage,
              let colorDataProvider = colorCGImage.dataProvider,
              let maskDataProvider = maskCGImage.dataProvider else {
            return []
        }
        
        let colorBitmapData = colorDataProvider.data
        let maskBitmapData = maskDataProvider.data
        
        guard let colorPtr = CFDataGetBytePtr(colorBitmapData),
              let maskPtr = CFDataGetBytePtr(maskBitmapData) else {
            throw NSError(domain: "Pointer to bitmap data is nil.", code: 1, userInfo: nil)
        }
        
        let width = colorCGImage.width
        let height = colorCGImage.height
        let colorBytesPerRow = colorCGImage.bytesPerRow
        let maskBytesPerRow = maskCGImage.bytesPerRow
        let bytesPerPixel = 4
        
        let maskDataLength = CFDataGetLength(maskBitmapData)
        let colorDataLength = CFDataGetLength(colorBitmapData)
        
        var ringColors: [(color: UIColor, pixelCount: CGFloat)] = []
        
        let centerX = width / 2
        let centerY = height / 2
        let maxRadius = max(width, height) / 2
        let pixelGroupSize = 80
        
        for radius in stride(from: 0, to: maxRadius, by: pixelGroupSize) {
            var rTotal: CGFloat = 0
            var gTotal: CGFloat = 0
            var bTotal: CGFloat = 0
            var aTotal: CGFloat = 0
            var validPixelCount: CGFloat = 0
            
            for angle in stride(from: 0.0, to: 360.0, by: 1.0) {
                let radian = angle * .pi / 180.0
                let x = centerX + Int(Double(radius) * cos(radian))
                let y = centerY + Int(Double(radius) * sin(radian))
                
                if x >= 0 && x < width && y >= 0 && y < height {
                    let colorPixelOffset = y * colorBytesPerRow + x * bytesPerPixel
                    let maskPixelOffset = y * maskBytesPerRow + x * bytesPerPixel
                    
                    guard maskPixelOffset >= 0 && maskPixelOffset < maskDataLength else {
                        continue // Skip if mask offset is out of bounds
                    }
                    
                    guard colorPixelOffset >= 0 && colorPixelOffset < colorDataLength else {
                        continue // Skip if color offset is out of bounds
                    }
                    
                    let maskValue = maskPtr[maskPixelOffset]
                    
                    if maskValue == 255 {  // Only process if mask pixel is white
                        let r = CGFloat(colorPtr[colorPixelOffset]) / 255.0
                        let g = CGFloat(colorPtr[colorPixelOffset + 1]) / 255.0
                        let b = CGFloat(colorPtr[colorPixelOffset + 2]) / 255.0
                        let a = CGFloat(colorPtr[colorPixelOffset + 3]) / 255.0
                        
                        if a > 0 {
                            rTotal += r
                            gTotal += g
                            bTotal += b
                            aTotal += a
                            validPixelCount += 1
                        }
                    }
                }
            }
            
            if validPixelCount > 0 {
                let rAvg = rTotal / validPixelCount
                let gAvg = gTotal / validPixelCount
                let bAvg = bTotal / validPixelCount
                let aAvg = aTotal / validPixelCount
                
                let averageColor = UIColor(red: rAvg, green: gAvg, blue: bAvg, alpha: aAvg).brightened(by: 0.3).saturated(by: 0.3)
                
                ringColors.append((averageColor, validPixelCount))
            }
        }
        
        return Self.distinctColors(from: ringColors).map { Color(uiColor: $0) }
    }
    
    /// CIEDE2000 distance under which two samples count as the same yarn color.
    private static let sameColorDistance: CGFloat = 15
    /// Colors covering less than this share of the sampled yarn are treated as noise.
    private static let minimumColorShare: CGFloat = 0.1
    private static let maximumColorCount = 4
    
    /// Groups sampled colors that look alike, ordered from most to least of the yarn covered.
    private static func distinctColors(from samples: [(color: UIColor, pixelCount: CGFloat)]) -> [UIColor] {
        var groups: [(color: UIColor, pixelCount: CGFloat)] = []
        
        for sample in samples {
            let closest = groups.indices.min { a, b in
                groups[a].color.CIEDE2000(compare: sample.color) < groups[b].color.CIEDE2000(compare: sample.color)
            }
            
            if let closest, groups[closest].color.CIEDE2000(compare: sample.color) < sameColorDistance {
                groups[closest].pixelCount += sample.pixelCount
            } else {
                groups.append(sample)
            }
        }
        
        let totalPixels = groups.reduce(0) { $0 + $1.pixelCount }
        guard totalPixels > 0 else { return [] }
        
        return groups
            .filter { $0.pixelCount / totalPixels >= minimumColorShare }
            .sorted { $0.pixelCount > $1.pixelCount }
            .prefix(maximumColorCount)
            .map(\.color)
    }

    
//    func yarnColors(from colorImage: UIImage, with maskImage: UIImage) throws -> [Color] {
//        guard let colorCGImage = colorImage.cgImage,
//              let maskCGImage = maskImage.cgImage,
//              let colorDataProvider = colorCGImage.dataProvider,
//              let maskDataProvider = maskCGImage.dataProvider else {
//            return []
//        }
//        
//        let colorBitmapData = colorDataProvider.data
//        let maskBitmapData = maskDataProvider.data
//        
//        let colorPtr = CFDataGetBytePtr(colorBitmapData)
//        let maskPtr = CFDataGetBytePtr(maskBitmapData)
//        
//        let width = colorCGImage.width
//        let height = colorCGImage.height
//        let colorBytesPerRow = colorCGImage.bytesPerRow
//        let maskBytesPerRow = maskCGImage.bytesPerRow
//        let bytesPerPixel = 4
//        
//        var colorSet = Set<Color>()
//        var distinctColors = Set<Color>()
//        
//        
//        let centerX = width / 2
//        let centerY = height / 2
//        let maxRadius = max(width, height) / 2
//        let pixelGroupSize = 80
//        
//        for radius in stride(from: 0, to: maxRadius, by: pixelGroupSize) {
//            var rTotal: CGFloat = 0
//            var gTotal: CGFloat = 0
//            var bTotal: CGFloat = 0
//            var aTotal: CGFloat = 0
//            var validPixelCount: CGFloat = 0
//            
//            for angle in stride(from: 0.0, to: 360.0, by: 1.0) {
//                let radian = angle * .pi / 180.0
//                let x = centerX + Int(Double(radius) * cos(radian))
//                let y = centerY + Int(Double(radius) * sin(radian))
//                
//                if x >= 0 && x < width && y >= 0 && y < height {
//                    let colorPixelOffset = y * colorBytesPerRow + x * bytesPerPixel
//                    let maskPixelOffset = y * maskBytesPerRow + x * bytesPerPixel
//                    let maskValue = maskPtr![maskPixelOffset]
//                    
//                    if maskValue == 255 {  // Only process if mask pixel is white
//                        let r = CGFloat(colorPtr![colorPixelOffset]) / 255.0
//                        let g = CGFloat(colorPtr![colorPixelOffset + 1]) / 255.0
//                        let b = CGFloat(colorPtr![colorPixelOffset + 2]) / 255.0
//                        let a = CGFloat(colorPtr![colorPixelOffset + 3]) / 255.0
//                        
//                        if a > 0 {
//                            rTotal += r
//                            gTotal += g
//                            bTotal += b
//                            aTotal += a
//                            validPixelCount += 1
//                        }
//                    }
//                }
//            }
//            
//            if validPixelCount > 0 {
//                let rAvg = rTotal / validPixelCount
//                let gAvg = gTotal / validPixelCount
//                let bAvg = bTotal / validPixelCount
//                let aAvg = aTotal / validPixelCount
//                
//                let averageColor = Color(uiColor: UIColor(red: rAvg, green: gAvg, blue: bAvg, alpha: aAvg).brightened(by: 0.3).saturated(by: 0.3))
//                
//                colorSet.insert(averageColor)
//            }
//        }
//        print("Number of colors", colorSet.count)
//        
//        for color in colorSet {
//            var isSimilar = false
//            for existingColor in distinctColors {
//                if color.isSimilar(to: existingColor, threshold: 0.05) {
//                    isSimilar = true
//                    break
//                }
//            }
//            
//            if !isSimilar {
//                distinctColors.insert(color)
//            }
//        }
//        
//        return Array(distinctColors)
//    }
    
  

    
}
