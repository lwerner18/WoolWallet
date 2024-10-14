//
//  ClearButton.swift
//  WoolWallet
//
//  Created by Mac on 3/10/24.
//

import Foundation
import SwiftUI


struct ClearButton: ViewModifier {
    @Binding var text: String
    
    public func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            content
            
            if !text.isEmpty {
                Button(action:
                        {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(Color(UIColor.opaqueSeparator))
                }
                .padding(.trailing, 8)
            }
        }
    }
}
