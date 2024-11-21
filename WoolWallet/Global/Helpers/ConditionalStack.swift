//
//  ConditionalStack.swift
//  WoolWallet
//
//  Created by Mac on 3/20/24.
//

import Foundation
import SwiftUI

struct ConditionalStack<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if GlobalSettings.shared.isPortraitMode {
                VStack { content }
            } else {
                HStack { content }
            }
        }
    }
}
