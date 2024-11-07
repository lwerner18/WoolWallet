//
//  PatternItemDisplay.swift
//  WoolWallet
//
//  Created by Mac on 11/6/24.
//

import Foundation
import SwiftUI


struct PatternItemDisplay : View {
    @ObservedObject var pattern : Pattern
    var size : Size = Size.medium
    
    var body : some View {
        PatternItemDisplayWithItem(item: pattern.patternItems.isEmpty ? nil : pattern.patternItems.first?.item, size: size)
    }
}

struct PatternItemDisplayWithItem : View {
    var item : Item? = nil
    var size : Size = Size.medium
    
    var body : some View {
        VStack {
            let itemDisplay =
            PatternUtils.shared.getItemDisplay(for: item)
            
            if itemDisplay.custom {
                Image(itemDisplay.icon)
                    .iconCircle(background: itemDisplay.color, size: size)
            } else {
                Image(systemName: itemDisplay.icon)
                    .iconCircle(background: itemDisplay.color, size: size)
            }
        }
    }
}
