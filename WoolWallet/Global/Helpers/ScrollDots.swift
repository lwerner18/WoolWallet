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
    var smallMode : Bool = false
    var hasBottomPadding : Bool = true
    
    var body: some View {
        HStack {
            
            let screenWidth = UIScreen.main.bounds.size.width
            let pagesSwiped = (scrollOffset.x / screenWidth) * -1.0
            let currentItemIndex = Int(pagesSwiped.rounded(.up))
            let size : CGFloat = smallMode ? 4 : 7
            
            // Create a ZStack to overlay the dots on a capsule
            ZStack {
                // Light gray capsule background
                Capsule()
                    .fill(Color.black.opacity(0.5)) // Adjust opacity for light gray
                    .frame(width: CGFloat(numberOfDots) * (size + 11), height: size + 11) // Adjust the frame based on the number of dots
                
                // Dots
                HStack(spacing: 6) { // Adjust spacing between dots
                    ForEach(0..<numberOfDots, id: \.self) { index in
                        Circle()
                            .fill(index == currentItemIndex ? Color.white : Color.gray)
                            .frame(width: size, height: size)
                    }
                }
            }
            
        }
        .padding(.bottom, hasBottomPadding ? (smallMode ? 4 : 8) : 0)
    }
}
