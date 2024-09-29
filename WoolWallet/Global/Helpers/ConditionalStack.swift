//
//  ConditionalStack.swift
//  WoolWallet
//
//  Created by Mac on 3/20/24.
//

import Foundation
import SwiftUI

struct ConditionalStack<Content: View>: View {
    let useVerticalLayout: Bool
    let content: Content
    
    init(useVerticalLayout: Bool, @ViewBuilder content: () -> Content) {
        self.useVerticalLayout = useVerticalLayout
        self.content = content()
    }
    
    var body: some View {
        Group {
            if useVerticalLayout {
                VStack { content }
            } else {
                HStack { content }
            }
        }
    }
}
