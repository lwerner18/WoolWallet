//
//  Color.swift
//  WoolWallet
//
//  Created by Mac on 7/20/24.
//

import Foundation
import SwiftUI

extension Color {        
    func isSimilar(to color: Color, threshold: CGFloat) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        return abs(r1 - r2) < threshold && abs(g1 - g2) < threshold && abs(b1 - b2) < threshold && abs(a1 - a2) < threshold
    }
    
    func uiColor() -> UIColor {
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        return UIColor(red: components[0], green: components[1], blue: components[2], alpha: components[3])
    }
    
    func distance(to other: Color) -> CGFloat {
        let c1 = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let c2 = UIColor(other).cgColor.components ?? [0, 0, 0, 0]
        
        let rDiff = c1[0] - c2[0]
        let gDiff = c1[1] - c2[1]
        let bDiff = c1[2] - c2[2]
        let aDiff = c1[3] - c2[3]
        
        return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff + aDiff * aDiff)
    }
    
    init(hex: String) {
        var cleanHexCode = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHexCode = cleanHexCode.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        
        Scanner(string: cleanHexCode).scanHexInt64(&rgb)
        
        let redValue = Double((rgb >> 16) & 0xFF) / 255.0
        let greenValue = Double((rgb >> 8) & 0xFF) / 255.0
        let blueValue = Double(rgb & 0xFF) / 255.0
        self.init(red: redValue, green: greenValue, blue: blueValue)
    }
    
    static func random() -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            opacity: 1
        )
    }
    
//    func closestNamedColor(namedColors: [NamedColor]) -> String {
//        var closestColor: NamedColor? = nil
//        var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude
//        
//        for namedColor in namedColors {
//            let distance = self.distance(to: namedColor.color)
//            print("Color", namedColor.name, "Distance", distance)
//            if distance < minDistance {
//                minDistance = distance
//                closestColor = namedColor
//            }
//        }
//        
//        return closestColor?.name ?? "Unknown"
//    }
}
