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
    
    @ObservedObject var pattern : Pattern
    
    var body: some View {
        HStack {
            VStack {
                PatternItemDisplay(pattern: pattern, size: Size.medium)
                
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
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(UIColor.secondaryLabel))
                
                Spacer()
                
                if pattern.oneSize {
                    Text("One Size")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .font(.caption)
                } else if pattern.intendedSize != nil && pattern.intendedSize != "" {
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
