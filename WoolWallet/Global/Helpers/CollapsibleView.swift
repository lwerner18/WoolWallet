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
    var useInfoCard : Bool = false
    @ViewBuilder let content: () -> Content
    
    var body: some View {
//        DisclosureGroup(isExpanded: $isSecondaryViewVisible) {
//            content()
//        } label : {
//            if useInfoCard {
//                InfoCard(backgroundColor: Color.accentColor.opacity(0.1)) {
//                    CollapsibleViewHeader(label: label, isSecondaryViewVisible: isSecondaryViewVisible, showArrows: showArrows)
//                }
//            } else {
//                CollapsibleViewHeader(label: label, isSecondaryViewVisible: isSecondaryViewVisible, showArrows: showArrows)
//            }
//        }
//        .onAppear {
//            if openByDefault {
//                isSecondaryViewVisible = true
//            }
//        }
        
        Group {
            Button {
                isSecondaryViewVisible.toggle()
            } label: {
                if useInfoCard {
                    InfoCard(backgroundColor: Color.accentColor.opacity(0.1)) {
                        CollapsibleViewHeader(label: label, isSecondaryViewVisible: isSecondaryViewVisible, showArrows: showArrows)
                    }
                } else {
                    CollapsibleViewHeader(label: label, isSecondaryViewVisible: isSecondaryViewVisible, showArrows: showArrows)
                }
            }
            
            if isSecondaryViewVisible {
                content()
                    .onTapGesture {
                        isSecondaryViewVisible.toggle()
                    }
            }
        }
        .onAppear {
            if openByDefault {
                isSecondaryViewVisible = true
            }
        }
    }
}

struct CollapsibleViewHeader<Label>: View where Label: View {
    
    
    @ViewBuilder let label: () -> Label
    var isSecondaryViewVisible : Bool
    var showArrows : Bool
    
    var body: some View {
        HStack {
            label()
                .foregroundStyle(.black)
            
            if showArrows {
                Spacer()
                
                Image(systemName: isSecondaryViewVisible ? "chevron.up" : "chevron.down")
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
    }
}
