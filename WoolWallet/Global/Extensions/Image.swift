//
//  Image.swift
//  WoolWallet
//
//  Created by Mac on 10/4/24.
//

import Foundation
import SwiftUI

extension Image {
    func iconCircle(background : Color, smallMode : Bool = false) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: smallMode ? 15 : 22, height: smallMode ? 15 : 22) // Adjust size as needed
            .foregroundColor(.white) // Icon color
            .padding(smallMode ? 8 : 13) // Padding inside the circle
            .background(background) // Circle background color
            .clipShape(Circle()) // Clip to circle shape
    }
}

