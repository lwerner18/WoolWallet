//
//  Tabs.swift
//  WoolWallet
//
//  Created by Mac on 10/29/24.
//

import Foundation
import SwiftUI

struct Tabs<T: CaseIterable & Identifiable & Equatable & CustomStringConvertible>: View {
    @Binding var selectedTab: T
    var tabCounts : [TabCount<T>]
    
    var body: some View {
        HStack {
            ForEach(Array(T.allCases)){ tab in
                Button(action: {
                    withAnimation {
                        selectedTab = tab
                    }
                }) {
                    Spacer()
                    
                    Text("\(tab.description) (\(tabCounts.first(where: {$0.tab == tab})!.count))")
                        .foregroundColor(selectedTab == tab ? Color.accentColor : .gray)
                        .frame(height: 35)
                        .font(T.allCases.count > 2 ? .caption : .footnote)
                    
                    Spacer()
                }
            }
        }
        .overlay(
            // Sliding underline
            GeometryReader { geometry in
                let buttonWidth = geometry.size.width / CGFloat(T.allCases.count)
                let index : Int = T.allCases.firstIndex {$0 == selectedTab}! as! Int
                
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: buttonWidth, height: 2)
                    .offset(x: CGFloat(index) * buttonWidth, y: 33)
                    .animation(.easeInOut, value: selectedTab)
            }
        )
        .padding(.bottom, 5)
    }
}
