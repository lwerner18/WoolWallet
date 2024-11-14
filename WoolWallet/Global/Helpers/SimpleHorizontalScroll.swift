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
    let halfWidthInLandscape : Bool
    let content: () -> Content // Closure for the content view
    
    init(
        count : Int,
        halfWidthInLandscape : Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.count = count
        self.halfWidthInLandscape = halfWidthInLandscape
        self.content = content
    }
    
//    var isPortraitMode: Bool {
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            return windowScene.interfaceOrientation.isPortrait
//        }
//        return false
//    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                content()
                    .simpleScrollItem(
                        count: count,
                        halfWidthInLandscape : halfWidthInLandscape,
                        isLandscape: !GlobalSettings.shared.isPortraitMode
                    )
            }
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(count <= 1)
    }
}
