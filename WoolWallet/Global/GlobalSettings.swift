//
//  EnvironmentValues.swift
//  WoolWallet
//
//  Created by Mac on 3/22/24.
//

import Foundation
import SwiftUI

class GlobalSettings {
    static let shared = GlobalSettings()
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        
        formatter.minimumFractionDigits = 0 // Minimum number of digits after decimal
        formatter.maximumFractionDigits = 2 // Maximum number of digits after decimal
        formatter.numberStyle = .decimal // Set the number style
        
        return formatter
    }()
    
    var isPortraitMode: Bool {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.interfaceOrientation.isPortrait
        }
        return false
    }
    
    private init() {}
}
