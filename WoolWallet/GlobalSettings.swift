//
//  EnvironmentValues.swift
//  WoolWallet
//
//  Created by Mac on 3/22/24.
//

import Foundation
import SwiftUI

struct NumberFormatterKey: EnvironmentKey {
    static let defaultValue: NumberFormatter = {
        let formatter = NumberFormatter()
        
        formatter.minimumFractionDigits = 0 // Minimum number of digits after decimal
        formatter.maximumFractionDigits = 2 // Maximum number of digits after decimal
        formatter.numberStyle = .decimal // Set the number style
        
        return formatter
    }()
}

extension EnvironmentValues {
    var numberFormatter: NumberFormatter {
        get { self[NumberFormatterKey.self] }
        set { self[NumberFormatterKey.self] = newValue }
    }
}
