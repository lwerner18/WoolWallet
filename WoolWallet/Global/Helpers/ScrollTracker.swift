//
//  ScrollTracker.swift
//  WoolWallet
//
//  Created by Mac on 10/21/24.
//

import Foundation
import SwiftUI

struct ScrollTracker: ViewModifier {
    @Binding var scrollOffset: CGPoint
    var name : String
    
    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geometry in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named(name)).origin)
            })
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
    }
}
