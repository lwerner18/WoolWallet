//
//  FormRow.swift
//  WoolWallet
//
//  Created by Mac on 7/20/24.
//

import Foundation
import SwiftUI

struct FormRow<Content: View>: View {
    let inline: Bool?
    let hasDivider: Bool?
    let content: Content
    let isSkinny : Bool?
    
    init(inline: Bool? = false, hasDivider: Bool? = true, isSkinny: Bool? = false, @ViewBuilder content: () -> Content) {
        self.inline = inline
        self.hasDivider = hasDivider
        self.isSkinny = isSkinny
        self.content = content()
    }
    
    var body: some View {
        Group {
            if inline! {
                HStack(spacing : 8) {
                    content
                }
                .padding(.vertical, isSkinny! ? 10 : 20)
                .padding(.horizontal, 20)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    content
                }
                .padding(.vertical, isSkinny! ? 10 : 20)
                .padding(.horizontal, 20)
            }
            
            if hasDivider! {
                Divider()
            }
          
        }
    }
}
