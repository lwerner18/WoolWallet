//
//  UIImage.swift
//  WoolWallet
//
//  Created by Mac on 7/20/24.
//

import Foundation
import SwiftUI

extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage? {
        let rect = CGRect(origin: .zero, size: targetSize)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        self.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
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
