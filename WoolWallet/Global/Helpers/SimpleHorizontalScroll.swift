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
    let paging : Bool
    let content: () -> Content // Closure for the content view
    
    init(
        count : Int,
        paging : Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.count = count
        self.paging = paging
        self.content = content
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                content()
            }
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(count <= 1)
    }
}
