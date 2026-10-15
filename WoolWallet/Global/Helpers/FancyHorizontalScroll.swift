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
    var size : Size
    let hasBottomPadding : Bool
    /// Lets the owner move to a page; otherwise the scroll keeps its own place
    let position : Binding<Int?>?
    var isScrollDisabled : Bool
    let content: () -> Content // Closure for the content view
    
    @State private var ownIndex: Int? = 0
    
    private var currentIndex: Binding<Int?> {
        position ?? $ownIndex
    }
    
    init(
        count : Int,
        size : Size = Size.medium,
        hasBottomPadding : Bool = true,
        position : Binding<Int?>? = nil,
        isScrollDisabled : Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.count = count
        self.size = size
        self.hasBottomPadding = hasBottomPadding
        self.position = position
        self.isScrollDisabled = isScrollDisabled
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
            .scrollTargetLayout()
        }
        .scrollPosition(id: currentIndex)
        .overlay(
            count > 1
            ? AnyView(
                ScrollDots(
                    currentIndex: currentIndex.wrappedValue ?? 0,
                    numberOfDots: count,
                    size: size,
                    hasBottomPadding: hasBottomPadding
                )
            )
            : AnyView(EmptyView()),
            alignment: .bottom
        )
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollDisabled(count <= 1 || isScrollDisabled)
    }
}
