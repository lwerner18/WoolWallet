//
//  FilterCapsule.swift
//  WoolWallet
//
//  Created by Mac on 11/6/24.
//

import Foundation
import SwiftUI

struct FilterCapsule<Content: View> : View {
    var text : String?
    let highlighted : Bool
    let showX : Bool
    let onClick : () -> Void
    let content: () -> Content // Closure for the content view

    
    init(
        text : String? = nil,
        highlighted : Bool = false,
        showX : Bool = false,
        onClick : @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.text = text
        self.highlighted = highlighted
        self.showX = showX
        self.onClick = onClick
        self.content = content
    }
    
    var body : some View {
        Button(action: onClick) {
            HStack() {
                Spacer()
                
                if text != nil {
                    Text(text!).foregroundColor(highlighted ? Color.accentColor : Color(UIColor.secondaryLabel)).fixedSize()
                } else {
                    content()
                }
                
                Spacer()
                
                if showX {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .font(.caption)
                }
       
            }
            .filterCapsule(
                background: highlighted
                ? Color.accentColor.opacity(0.2)
                : Color(UIColor.secondarySystemGroupedBackground),
                border: highlighted
                ? Color.accentColor.opacity(0.2)
                : Color(UIColor.secondaryLabel)
            )
            
        }
    }
}
