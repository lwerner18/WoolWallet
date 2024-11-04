//
//  NewItemHeader.swift
//  WoolWallet
//
//  Created by Mac on 10/30/24.
//

import Foundation
import SwiftUI

struct NewItemHeader:  View {
    var onClose: () -> Void
    
    var body: some View {
        // Toolbar-like header
        HStack {
            Spacer()
            
            Button {
                onClose()
            } label: {
                Text("Close")
            }
        }
        .padding(.bottom, 10) // Padding around the button
        .padding(.top, 20) // Padding around the button
        .padding(.horizontal, 20) // Padding around the button
    }
}
