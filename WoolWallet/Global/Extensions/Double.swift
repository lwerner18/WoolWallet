//
//  Double.swift
//  WoolWallet
//
//  Created by Mac on 11/16/24.
//

import Foundation
import SwiftUI

extension Double {
    var formatted: String {
        return GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
