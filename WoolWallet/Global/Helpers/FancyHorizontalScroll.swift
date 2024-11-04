//
//  HorizontalScroll.swift
//  WoolWallet
//
//  Created by Mac on 11/2/24.
//

import Foundation
import SwiftUI

struct FancyHorizontalScroll<Content: View>: View {
    let count: Int
    let smallMode : Bool
    let hasBottomPadding : Bool
    let trailing : Bool
    let content: () -> Content // Closure for the content view
    
    @State private var scrollOffset = CGPoint.zero
    
    init(
        count : Int,
        smallMode : Bool = true,
        hasBottomPadding : Bool = true,
        trailing : Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.count = count
        self.smallMode = smallMode
        self.hasBottomPadding = hasBottomPadding
        self.trailing = trailing
        self.content = content
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                content()
                    .containerRelativeFrame(.horizontal)
                    .scrollTransition(.animated, axis: .horizontal) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1.0 : 0.8)
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
                    }
                    .padding(.vertical, 4)
            }
            .scrollTracker(
                scrollOffset : $scrollOffset,
                name: "scroll"
            )
        }
        .overlay(
            count > 1
            ? AnyView(
                ScrollDots(
                    scrollOffset: scrollOffset,
                    numberOfDots: count,
                    smallMode: smallMode,
                    hasBottomPadding: hasBottomPadding
                )
            )
            : AnyView(EmptyView()),
            alignment: trailing ? .bottomTrailing : .bottom
        )
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollDisabled(count <= 1)
    }
}
