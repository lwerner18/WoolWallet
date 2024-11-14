//
//  ScrollDots.swift
//  WoolWallet
//
//  Created by Mac on 10/21/24.
//

import Foundation
import SwiftUI


struct ScrollDots:  View {
    var scrollOffset : CGPoint
    var numberOfDots : Int
    var size : Size = Size.medium
    var hasBottomPadding : Bool
    
    var dotSize : CGFloat {
        switch size {
        case .extraSmall: return 3;
        case .small: return 3;
        case .medium: return 6;
        case .large: return 10;
        }
    }
    
    var bottomPadding : CGFloat {
        switch size {
        case .extraSmall: return 8;
        case .small: return 8;
        case .medium: return 10;
        case .large: return 15;
        }
    }
    
    var body: some View {
        HStack {
            
            let screenWidth = UIScreen.main.bounds.size.width
            let pagesSwiped = (scrollOffset.x / screenWidth) * -1.0
            let currentItemIndex = Int(pagesSwiped.rounded(.up))
            
            // Create a ZStack to overlay the dots on a capsule
            ZStack {
                // Light gray capsule background
                Capsule()
                    .fill(Color.black.opacity(0.5)) // Adjust opacity for light gray
                    .frame(width: CGFloat(numberOfDots) * (dotSize + 9), height: dotSize + 9) // Adjust the frame based on the number of dots
                
                // Dots
                HStack(spacing: 6) { // Adjust spacing between dots
                    ForEach(0..<numberOfDots, id: \.self) { index in
                        Circle()
                            .fill(index == currentItemIndex ? Color.white : Color.gray)
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
            
        }
        .padding(.bottom, hasBottomPadding ? bottomPadding : 0)
    }
}

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
