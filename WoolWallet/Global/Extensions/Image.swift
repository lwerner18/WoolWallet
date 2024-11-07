//
//  Image.swift
//  WoolWallet
//
//  Created by Mac on 10/4/24.
//

import Foundation
import SwiftUI

enum Size {
    case extraSmall
    case small
    case medium
    case large
}

extension Image {
    func iconCircle(background : Color, size : Size = Size.medium) -> some View {
        var frameSize : CGFloat
        var padding : CGFloat
        
        switch size {
        case .extraSmall: frameSize = 11; padding = 5
        case .small: frameSize = 15; padding = 8
        case .medium: frameSize = 25; padding = 15
        case .large: frameSize = 40; padding = 28
        }
        
        return self
            .resizable()
            .scaledToFit()
            .frame(width: frameSize, height: frameSize) // Adjust size as needed
            .foregroundColor(.white) // Icon color
            .padding(padding) // Padding inside the circle
            .background(background) // Circle background color
            .clipShape(Circle()) // Clip to circle shape
    }
}

