//
//  InfoCard.swift
//  WoolWallet
//
//  Created by Mac on 10/7/24.
//

import Foundation
import SwiftUI

struct InfoCard<Content: View>: View {
    var noPadding : Bool? = false
    let content: () -> Content
    
    var body: some View {
        content() // Content provided as a closure
            .padding(noPadding! ? 0 : 15) // Padding for the section
            .background(Color(UIColor.secondarySystemGroupedBackground)) // Background color for the section
            .cornerRadius(8) // Rounded corners for the section
            .shadow(radius: 0.5)
    }
}
