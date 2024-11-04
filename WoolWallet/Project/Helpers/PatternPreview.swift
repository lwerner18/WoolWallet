//
//  PatternPreview.swift
//  WoolWallet
//
//  Created by Mac on 11/1/24.
//

import Foundation
import SwiftUI

struct PatternPreview: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    var pattern : Pattern
    
    var body: some View {
        HStack {
            VStack {
                let itemDisplay =
                PatternUtils.shared.getItemDisplay(
                    for: pattern.patternItems.isEmpty ? nil : pattern.patternItems.first?.item
                )
                
                if itemDisplay.custom {
                    Image(itemDisplay.icon)
                        .iconCircle(background: itemDisplay.color, xl: true)
                } else {
                    Image(systemName: itemDisplay.icon)
                        .iconCircle(background: itemDisplay.color, xl: true)
                }
                
                Text(pattern.type!)
                    .font(.caption)
                    .foregroundStyle(Color.primary)
            }
            
            
            Spacer()
            
            
            VStack(alignment: .center) {
                Text(pattern.name!)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.primary)
                    .font(.title3)
                    .bold()
                
                Text(pattern.designer!)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.footnote)
                    .bold()
                
                Spacer()
                
                Text(
                    PatternUtils.shared.joinedItems(patternItems: pattern.patternItems)
                )
                .foregroundStyle(Color(UIColor.secondaryLabel))
                
                Spacer()
                
                if pattern.oneSize != 0 {
                    Text("One Size")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .font(.caption)
                } else if pattern.intendedSize != nil {
                    Text("Intended size: \(pattern.intendedSize!)")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
