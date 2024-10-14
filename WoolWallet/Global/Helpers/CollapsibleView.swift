//
//  Collapsible.swift
//  WoolWallet
//
//  Created by Mac on 10/12/24.
//

import Foundation
import SwiftUI

struct CollapsibleView<Label, Content>: View where Label: View, Content: View {
    @State private var isSecondaryViewVisible = false
    
    @ViewBuilder let label: () -> Label
    var showArrows : Bool = false
    var openByDefault : Bool = false
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Group {
            Button {
                withAnimation {
                    isSecondaryViewVisible.toggle()
                }
                
            } label: {
                HStack {
                    label()
                        .foregroundStyle(.black)
                    
                    if showArrows {
                        Spacer()
                        
                        Image(systemName: isSecondaryViewVisible ? "chevron.down" : "chevron.up")
                    }
                }
            }
            
            if isSecondaryViewVisible {
                content()
                    .onTapGesture {
                        withAnimation {
                            isSecondaryViewVisible.toggle()
                        }
                    }
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            if openByDefault {
                isSecondaryViewVisible = true
            }
        }
    }
}
