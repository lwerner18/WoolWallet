//
//  InfoCard.swift
//  WoolWallet
//
//  Created by Mac on 10/7/24.
//

import Foundation
import SwiftUI

struct InfoCard<Header: View, Content: View>: View {
    var noPadding : Bool
    var backgroundColor: Color
    let header: () -> Header // Closure for the header view
    let content: () -> Content // Closure for the content view
    
    init(
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        backgroundColor : Color = Color(UIColor.secondarySystemGroupedBackground),
        noPadding : Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.backgroundColor = backgroundColor
        self.noPadding = noPadding
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            header()
                .padding(.top, 5) // Add some padding below the header
                .font(.subheadline.smallCaps())
                .foregroundColor(.secondary)
            
            // Render the main content
            content()
                .padding(noPadding ? 0 : 15) // Padding for the content
                .background(backgroundColor)
                .cornerRadius(8) // Rounded corners for the card
                .shadow(radius: 0.5)
        }
    }
}
