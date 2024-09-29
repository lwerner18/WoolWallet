//
//  ButtonStyles.swift
//  WoolWallet
//
//  Created by Mac on 8/28/24.
//

import Foundation
import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.white) // Set the fill color to white
            .foregroundColor(.gray) // Set text color
            .overlay(
                RoundedRectangle(cornerRadius: 16) // Rounded border
                    .stroke(Color.gray, lineWidth: 0.5) // Border color and width
                    .shadow(radius: 0.5) // Optional: shadow for the entire list
            )
       
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Scale effect when pressed
            .animation(.spring(), value: configuration.isPressed) // Animation for the scale effect
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(isEnabled ? Color(hex: "#36727E") : Color(uiColor: UIColor.lightGray).opacity(0.5))
            .foregroundColor(isEnabled ? .white : Color(uiColor: UIColor.lightGray)) // Set text color
            .clipShape(RoundedRectangle(cornerRadius: 16)) // Apply rounded corners
            .overlay(
                RoundedRectangle(cornerRadius: 16) // Rounded border
                    .stroke(isEnabled ? Color(hex: "#36727E") : Color(uiColor: UIColor.lightGray).opacity(0.5), lineWidth: 0.5) // Border color and width
                    .shadow(radius: 0.5) // Optional: shadow for the entire list
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Scale effect when pressed
            .animation(.spring(), value: configuration.isPressed) // Animation for the scale effect
    }
}
