//
//  UIImage.swift
//  WoolWallet
//
//  Created by Mac on 7/20/24.
//

import Foundation
import SwiftUI
import ImageIO

extension UIImage {
    /// Decodes image data directly at a reduced size, avoiding a full-resolution bitmap in memory.
    static func downsampled(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        
        var targetPixelSize = maxPixelSize
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
           let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue {
            targetPixelSize = min(maxPixelSize, CGFloat(max(width, height)))
        }
        
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: targetPixelSize
        ] as CFDictionary
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    /// Returns a copy whose longest edge is at most `maxPixelSize` pixels, or self if already smaller.
    func scaledDown(toMaxPixelSize maxPixelSize: CGFloat) -> UIImage {
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale
        let longestEdge = max(pixelWidth, pixelHeight)
        guard longestEdge > maxPixelSize else { return self }
        
        let ratio = maxPixelSize / longestEdge
        let targetSize = CGSize(width: (pixelWidth * ratio).rounded(), height: (pixelHeight * ratio).rounded())
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Turned to the right, drawn upright so it saves without relying on orientation metadata
    func rotatedClockwise(quarterTurns: Int) -> UIImage {
        let turns = ((quarterTurns % 4) + 4) % 4
        guard turns != 0 else { return self }
        
        let originalSize = CGSize(width: size.width * scale, height: size.height * scale)
        let rotatedSize = turns.isMultiple(of: 2) ? originalSize : CGSize(width: originalSize.height, height: originalSize.width)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        
        return UIGraphicsImageRenderer(size: rotatedSize, format: format).image { context in
            context.cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.cgContext.rotate(by: CGFloat(turns) * .pi / 2)
            draw(in: CGRect(x: -originalSize.width / 2, y: -originalSize.height / 2, width: originalSize.width, height: originalSize.height))
        }
    }
    
    func resize(to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
//    func distinctColorsTest(threshold: CGFloat = 0.35, blockSize: Int = 200) -> [Color] {
//        guard let cgImage = self.cgImage else {
//            return []
//        }
//        
//        let width = cgImage.width
//        let height = cgImage.height
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * width
//        let bitsPerComponent = 8
//        
//        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
//        let context = CGContext(data: &pixelData,
//                                width: width,
//                                height: height,
//                                bitsPerComponent: bitsPerComponent,
//                                bytesPerRow: bytesPerRow,
//                                space: colorSpace,
//                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
//        
//        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
//        
//        let colorSet = NSCountedSet()
//        let queue = DispatchQueue.global(qos: .userInitiated)
//        let group = DispatchGroup()
//        
//        for y in stride(from: 0, to: height, by: blockSize) {
//            for x in stride(from: 0, to: width, by: blockSize) {
//                group.enter()
//                queue.async {
//                    var rTotal: CGFloat = 0
//                    var gTotal: CGFloat = 0
//                    var bTotal: CGFloat = 0
//                    var aTotal: CGFloat = 0
//                    var count: CGFloat = 0
//                    
//                    for yOffset in 0..<blockSize {
//                        for xOffset in 0..<blockSize {
//                            let pixelIndex = ((y + yOffset) * width + (x + xOffset)) * bytesPerPixel
//                            if pixelIndex < pixelData.count {
//                                let a = CGFloat(pixelData[pixelIndex + 3]) / 255.0
//                                if a > 0.5 { // Only include opaque pixels
//                                    rTotal += CGFloat(pixelData[pixelIndex]) / 255.0
//                                    gTotal += CGFloat(pixelData[pixelIndex + 1]) / 255.0
//                                    bTotal += CGFloat(pixelData[pixelIndex + 2]) / 255.0
//                                    aTotal += a
//                                    count += 1
//                                }
//                            }
//                        }
//                    }
//                    
//                    if count > 0 {
//                        let r = rTotal / count
//                        let g = gTotal / count
//                        let b = bTotal / count
//                        let a = aTotal / count
//                        
//                        let color = UIColor(red: r, green: g, blue: b, alpha: a)
//                        
//                        // Exclude colors that are close to white or black
//                        if color != .white && color != .black {
//                            colorSet.add(color)
//                        }
//                    }
//                    
//                    group.leave()
//                }
//            }
//        }
//        
//        group.wait()
//        
//        var distinctColors = [Color]()
//        for color in colorSet {
//            if let uiColor = color as? UIColor {
//                var isSimilar = false
//                for existingColor in distinctColors {
//                    if uiColor.isSimilar(to: existingColor.uiColor(), threshold: threshold) {
//                        isSimilar = true
//                        break
//                    }
//                }
//                
//                if !isSimilar {
//                    distinctColors.append(Color(uiColor))
//                }
//            }
//        }
//        
//        return distinctColors
//    }
}
