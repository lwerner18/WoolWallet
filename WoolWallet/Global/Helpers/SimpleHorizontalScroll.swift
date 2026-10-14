//
//  SimpleHorizontalScroll.swift
//  WoolWallet
//
//  Created by Mac on 11/3/24.
//

import Foundation
import SwiftUI

struct SimpleHorizontalScroll<Content: View>: View {
    let count: Int
    let content: () -> Content // Closure for the content view
    
    init(
        count : Int,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.count = count
        self.content = content
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                content()
                    .simpleScrollItem(count: count)
            }
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(count <= 1)
    }
}
