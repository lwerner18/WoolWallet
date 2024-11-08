//
//  InfoCard.swift
//  WoolWallet
//
//  Created by Mac on 10/7/24.
//

import Foundation
import SwiftUI

struct InfoCard<Header: View, Footer: View, Content: View>: View {
    var noPadding : Bool
    var backgroundColor: Color
    let header: () -> Header // Closure for the header view
    let footer: () -> Footer // Closure for the footer view
    let content: () -> Content // Closure for the content view
    
    init(
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        backgroundColor : Color = Color(UIColor.secondarySystemGroupedBackground),
        noPadding : Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.backgroundColor = backgroundColor
        self.noPadding = noPadding
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            header()
                .infoCardHeader()
            
            // Render the main content
            content()
                .padding(noPadding ? 0 : 15) // Padding for the content
                .background(backgroundColor)
                .cornerRadius(8) // Rounded corners for the card
                .shadow(radius: 0.5)
            
            footer()
                .padding(.bottom, 15) // Add some padding below the header
                .font(.subheadline)
        }
    }
}
