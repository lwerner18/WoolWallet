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
    var backgroundColor: Color = Color(UIColor.secondarySystemGroupedBackground)
    let content: () -> Content
    
    var body: some View {
        content() // Content provided as a closure
            .padding(noPadding! ? 0 : 15) // Padding for the section
            .background(backgroundColor)
            .cornerRadius(8) // Rounded corners for the section
            .shadow(radius: 0.5)
    }
}
