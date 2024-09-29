//
//  UIColor.swift
//  WoolWallet
//
//  Created by Mac on 7/20/24.
//

import Foundation
import UIKit

extension UIColor {
    func brightened(by factor: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the hue, saturation, brightness, and alpha components of the color
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            // Increase the brightness by the specified factor, clamping it to 1.0
            brightness = min(brightness + factor, 1.0)
            
            // Return a new UIColor with the updated brightness
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        // If the color can't be converted to HSB, return the original color
        return self
    }
    
    func saturated(by factor: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the hue, saturation, brightness, and alpha components of the color
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            // Increase the brightness by the specified factor, clamping it to 1.0
            saturation = min(saturation + factor, 1.0)
            
            // Return a new UIColor with the updated brightness
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        // If the color can't be converted to HSB, return the original color
        return self
    }
}

extension Array where Element: UIColor {
    func toData() -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
    
    static func from(data: Data) -> [UIColor]? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, UIColor.self], from: data) as? [UIColor]
    }
}
